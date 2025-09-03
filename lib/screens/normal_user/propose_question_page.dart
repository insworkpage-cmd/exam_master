import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../core/question_model.dart';
import '../../services/question_service.dart';
import '../../services/capacity_service.dart';
// import '../../widgets/capacity_indicator.dart'; // حذف شد - استفاده نشده
import '../../utils/logger.dart';
import '../../widgets/question_status_badge.dart';

class ProposeQuestionPage extends StatefulWidget {
  // پارامتر اختیاری برای پیشنهاد سوال در مورد یک سوال موجود
  final Question? relatedQuestion;
  // پارامتر اختیاری برای پیشنهاد سوال برای یک کلاس خاص
  final String? classId;

  const ProposeQuestionPage({
    super.key,
    this.relatedQuestion,
    this.classId,
  });

  @override
  State<ProposeQuestionPage> createState() => _ProposeQuestionPageState();
}

class _ProposeQuestionPageState extends State<ProposeQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _sourceController = TextEditingController();
  final _explanationController = TextEditingController();
  final _commentController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  int _correctAnswerIndex = 0;
  String _selectedCategory = 'عمومی';
  String _selectedDifficulty = 'متوسط';
  bool _isLoading = false;

  // متغیرهای جدید برای مدیریت ظرفیت
  int _remainingCapacity = 10;
  bool _isBlocked = false;
  bool _isLoadingCapacity = true;

  final List<String> _categories = [
    'عمومی',
    'ریاضی',
    'علوم',
    'ادبیات',
    'تاریخ',
    'جغرافیا',
    'فلسفه',
    'هنر',
    'ورزش',
    'فناوری',
  ];

  final List<String> _difficulties = [
    'آسان',
    'متوسط',
    'سخت',
  ];

  @override
  void initState() {
    super.initState();
    _checkUserCapacity();

    // اگر سوال مرتبط وجود دارد، اطلاعات آن را پر می‌کنیم
    if (widget.relatedQuestion != null) {
      _textController.text =
          'پیشنهاد برای بهبود: ${widget.relatedQuestion!.text}';
      _sourceController.text = widget.relatedQuestion!.source ?? '';
      _selectedCategory = widget.relatedQuestion!.category ?? 'عمومی';

      // گزینه‌های سوال مرتبط را اضافه می‌کنیم
      for (int i = 0; i < widget.relatedQuestion!.options.length; i++) {
        _optionControllers.add(
            TextEditingController(text: widget.relatedQuestion!.options[i]));
      }
      _correctAnswerIndex = widget.relatedQuestion!.correctAnswerIndex;
    } else {
      // ایجاد 4 گزینه پیش‌فرض
      for (int i = 0; i < 4; i++) {
        _optionControllers.add(TextEditingController());
      }
    }
  }

  // متد جدید برای بررسی ظرفیت کاربر
  Future<void> _checkUserCapacity() async {
    setState(() {
      _isLoadingCapacity = true;
    });
    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final capacityStatus = await CapacityService.getUserCapacityStatus(
          authProvider.currentUser!.uid,
        );

        setState(() {
          _remainingCapacity = capacityStatus['capacity'];
          _isBlocked = capacityStatus['isBlocked'];
          _isLoadingCapacity = false;
        });
      }
    } catch (e) {
      Logger.error('Error checking user capacity: $e');
      setState(() {
        _isLoadingCapacity = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _sourceController.dispose();
    _explanationController.dispose();
    _commentController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.relatedQuestion != null
            ? 'پیشنهاد بهبود سوال'
            : 'پیشنهاد سوال جدید'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _viewMyProposals(),
            tooltip: 'مشاهده پیشنهادات من',
          ),
        ],
      ),
      body: Consumer<app_auth.AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(child: Text('لطفاً وارد شوید'));
          }

          // بررسی وضعیت ظرفیت
          if (_isLoadingCapacity) {
            return const Center(child: CircularProgressIndicator());
          }

          // اگر سرویس مسدود شده باشد
          if (_isBlocked) {
            return _buildBlockedMessage();
          }

          // اگر ظرفیت تمام شده باشد
          if (_remainingCapacity <= 0) {
            return _buildNoCapacityMessage();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بخش ظرفیت
                  _buildCapacityInfo(),
                  const SizedBox(height: 20),

                  // بخش اطلاعات راهنما
                  _buildInfoCard(),
                  const SizedBox(height: 20),

                  // بخش متن سوال
                  _buildQuestionTextField(),
                  const SizedBox(height: 20),

                  // بخش گزینه‌ها
                  _buildOptionsSection(),
                  const SizedBox(height: 20),

                  // بخش تنظیمات سوال
                  _buildSettingsSection(),
                  const SizedBox(height: 20),

                  // بخش توضیحات و نظر
                  _buildExplanationSection(),
                  const SizedBox(height: 30),

                  // بخش دکمه‌ها
                  _buildActionButtons(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ویجت جدید برای نمایش پیام مسدودی
  Widget _buildBlockedMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'سرویس پیشنهاد سوال مسدود شده',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800, // اصلاح شده: استفاده از shade800
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'لطفاً با پشتیبانی تماس بگیرید',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ویجت جدید برای نمایش پیام عدم ظرفیت
  Widget _buildNoCapacityMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'ظرفیت پیشنهاد سوال شما تمام شده',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800, // اصلاح شده: استفاده از shade800
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'شما نمی‌توانید سوال جدیدی پیشنهاد دهید',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/request_capacity');
            },
            child: const Text('درخواست افزایش ظرفیت'),
          ),
        ],
      ),
    );
  }

  // ویجت جدید برای نمایش اطلاعات ظرفیت
  Widget _buildCapacityInfo() {
    Color capacityColor = Colors.green;
    String capacityText = 'ظرفیت کافی';

    if (_remainingCapacity <= 3) {
      capacityColor = Colors.orange;
      capacityText = 'ظرفیت در حال اتمام';
    }

    return Card(
      color:
          capacityColor.withOpacity(0.05), // اصلاح شده: استفاده از withOpacity
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _remainingCapacity > 3 ? Icons.check_circle : Icons.warning,
                  color: capacityColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    capacityText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: capacityColor.withOpacity(
                          0.8), // اصلاح شده: استفاده از withOpacity
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _remainingCapacity / 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(capacityColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ظرفیت باقی‌مانده: $_remainingCapacity از 10',
                  style: TextStyle(
                    fontSize: 14,
                    color: capacityColor
                        .withOpacity(0.7), // اصلاح شده: استفاده از withOpacity
                  ),
                ),
                if (_remainingCapacity <= 3)
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/request_capacity');
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8), // اصلاح شده: اضافه کردن const
                    ),
                    child: const Text(
                        'درخواست افزایش'), // اصلاح شده: اضافه کردن const
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50, // اصلاح شده: استفاده از shade50
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info,
                    color:
                        Colors.blue.shade700), // اصلاح شده: استفاده از shade700
                const SizedBox(width: 8),
                const Text(
                  'راهنمای پیشنهاد سوال',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.relatedQuestion != null
                  ? 'شما در حال پیشنهاد بهبود برای یک سوال موجود هستید. لطفاً پیشنهادات خود را با دقت وارد کنید.'
                  : 'شما می‌توانید سوال جدیدی را پیشنهاد دهید. پیشنهادات شما توسط ناظر بررسی شده و در صورت تأیید به بانک سوالات اضافه خواهد شد.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade800, // اصلاح شده: استفاده از shade800
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'متن سوال *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _textController,
          decoration: const InputDecoration(
            // اصلاح شده: اضافه کردن const
            labelText: 'متن سوال را وارد کنید',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(
                  12)), // اصلاح شده: استفاده از BorderRadius.all
            ),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'لطفاً متن سوال را وارد کنید';
            }
            if (value.trim().length < 10) {
              return 'متن سوال باید حداقل 10 کاراکتر باشد';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'گزینه‌ها *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._optionControllers.asMap().entries.map((entry) {
          final index = entry.key;
          final controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Radio<int>(
                  value: index,
                  groupValue: _correctAnswerIndex,
                  onChanged: (value) {
                    setState(() {
                      _correctAnswerIndex = value!;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'گزینه ${index + 1} *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'لطفاً این گزینه را وارد کنید';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),

        // دکمه افزودن گزینه جدید
        if (_optionControllers.length < 6)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('افزودن گزینه'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تنظیمات سوال',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // انتخاب دسته‌بندی
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                // اصلاح شده: اضافه کردن const
                labelText: 'دسته‌بندی *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(
                      12)), // اصلاح شده: استفاده از BorderRadius.all
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'لطفاً دسته‌بندی را انتخاب کنید';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // انتخاب سطح دشواری
            DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                // اصلاح شده: اضافه کردن const
                labelText: 'سطح دشواری *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(
                      12)), // اصلاح شده: استفاده از BorderRadius.all
                ),
              ),
              items: _difficulties.map((difficulty) {
                return DropdownMenuItem(
                  value: difficulty,
                  child: Text(difficulty),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'لطفاً سطح دشواری را انتخاب کنید';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // منبع سوال
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(
                // اصلاح شده: اضافه کردن const
                labelText: 'منبع (اختیاری)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(
                      12)), // اصلاح شده: استفاده از BorderRadius.all
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // توضیح پاسخ
        TextFormField(
          controller: _explanationController,
          decoration: const InputDecoration(
            // اصلاح شده: اضافه کردن const
            labelText: 'توضیح پاسخ (اختیاری)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(
                  12)), // اصلاح شده: استفاده از BorderRadius.all
            ),
          ),
          maxLines: 3,
        ),

        const SizedBox(height: 16),

        // نظر کاربر
        TextFormField(
          controller: _commentController,
          decoration: const InputDecoration(
            // اصلاح شده: اضافه کردن const
            labelText: 'توضیحات پیشنهاد (اختیاری)',
            hintText: 'دلایل پیشنهاد خود را بنویسید...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(
                  12)), // اصلاح شده: استفاده از BorderRadius.all
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // دکمه اصلی پیشنهاد سوال
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _submitProposal,
            style: ElevatedButton.styleFrom(
              // اصلاح شده: انتقال style به قبل از child
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: _isLoading
                ? const Text('در حال ارسال...')
                : const Text('ارسال پیشنهاد'),
          ),
        ),

        const SizedBox(height: 12),

        // دکمه مشاهده پیشنهادات قبلی
        OutlinedButton.icon(
          onPressed: _viewMyProposals,
          icon: const Icon(Icons.history),
          label: const Text('مشاهده پیشنهادات قبلی'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کاربر وارد نشده است')),
      );
      return;
    }

    // بررسی مجدد ظرفیت قبل از ارسال
    if (_remainingCapacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ظرفیت پیشنهاد سوال شما تمام شده است'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // تبدیل سطح دشواری به عدد
      final difficultyMap = {'آسان': 1, 'متوسط': 2, 'سخت': 3};
      final difficulty = difficultyMap[_selectedDifficulty] ?? 2;

      final question = Question(
        id: const Uuid().v4(),
        text: _textController.text.trim(),
        options: _optionControllers.map((c) => c.text.trim()).toList(),
        correctAnswerIndex: _correctAnswerIndex,
        source: _sourceController.text.trim().isEmpty
            ? null
            : _sourceController.text.trim(),
        explanation: _explanationController.text.trim().isEmpty
            ? null
            : _explanationController.text.trim(),
        instructorId: null,
        status: 'pending',
        createdAt: DateTime.now(),
        category: _selectedCategory,
        difficulty: difficulty,
        timeLimit: null,
        tags: null,
        classId: widget.classId,
        proposedBy: authProvider.currentUser!.uid,
        reviewedBy: null,
        reviewDate: null,
        reviewComment: null,
        updatedAt: null,
      );

      final questionService = QuestionService();
      await questionService.addQuestion(
        question: question,
        proposedBy: authProvider.currentUser!.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('پیشنهاد سوال با موفقیت ارسال شد'),
            backgroundColor: Colors.green,
          ),
        );

        // بازگشت به صفحه قبلی
        Navigator.pop(context);
      }
    } catch (e) {
      Logger.error('Error submitting question proposal: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال پیشنهاد: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _viewMyProposals() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MyProposalsPage(),
      ),
    );
  }
}

// صفحه نمایش پیشنهادات کاربر
class MyProposalsPage extends StatefulWidget {
  const MyProposalsPage({super.key});

  @override
  State<MyProposalsPage> createState() => _MyProposalsPageState();
}

class _MyProposalsPageState extends State<MyProposalsPage> {
  List<Question> _proposals = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMyProposals();
  }

  Future<void> _loadMyProposals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      final questionService = QuestionService();
      _proposals = await questionService.getQuestionsProposedByUser(
        authProvider.currentUser!.uid,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پیشنهادات من'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMyProposals,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                )
              : _proposals.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'شما هنوز هیچ سوالاتی پیشنهاد نداده‌اید',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMyProposals,
                      child: ListView.builder(
                        itemCount: _proposals.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final proposal = _proposals[index];
                          return ProposalCard(proposal: proposal);
                        },
                      ),
                    ),
    );
  }
}

class ProposalCard extends StatelessWidget {
  final Question proposal;

  const ProposalCard({super.key, required this.proposal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    proposal.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                QuestionStatusBadge(status: proposal.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  proposal.category ?? 'عمومی',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.speed, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  proposal.difficulty == 1
                      ? 'آسان'
                      : proposal.difficulty == 2
                          ? 'متوسط'
                          : 'سخت',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${proposal.createdAt.day}/${proposal.createdAt.month}/${proposal.createdAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (proposal.reviewDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.done_all, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'بررسی شد',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
