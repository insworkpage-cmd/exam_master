import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth; // ← اصلاح import
import '../../core/question_model.dart';
import '../../services/question_service.dart';
import '../../widgets/question_status_badge.dart';
import '../../models/user_role.dart';
import '../../widgets/role_based_access.dart';
import 'package:uuid/uuid.dart';

class QuestionManagementPage extends StatefulWidget {
  const QuestionManagementPage({super.key});

  @override
  State<QuestionManagementPage> createState() => _QuestionManagementPageState();
}

class _QuestionManagementPageState extends State<QuestionManagementPage> {
  List<Question> _questions = [];
  bool _isLoading = false;
  String _selectedStatus = 'all';
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();
  String _sortOption = 'date'; // date, status, text
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<Question> _getFilteredAndSortedQuestions() {
    var filtered = _questions.where((question) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return question.text.toLowerCase().contains(query) ||
          question.options
              .any((option) => option.toLowerCase().contains(query)) ||
          (question.source?.toLowerCase().contains(query) ?? false);
    }).toList();

    // اعمال فیلتر وضعیت
    if (_selectedStatus != 'all') {
      filtered = filtered.where((q) => q.status == _selectedStatus).toList();
    }

    // مرتب‌سازی
    filtered.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case 'date':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        case 'text':
          comparison = a.text.compareTo(b.text);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }
      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _loadQuestions() async {
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

      // شبیه‌سازی دریافت سوالات از Firestore
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _questions = [
          Question(
            id: '1',
            text: 'مجموع زوایای مثلث قائمه‌ای چقدر است؟',
            options: ['90', '180', '270', '360'],
            correctAnswerIndex: 1,
            source: 'کتاب ریاضی',
            explanation: 'مجموع زوایای مثلث قائمه‌ای برابر با 360 درجه است',
            instructorId: authProvider.currentUser!.uid,
            status: 'approved',
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
          Question(
            id: '2',
            text: 'سرعت نور در خلاء چقدر است؟',
            options: [
              '299,792 km/s',
              '300,000 km/s',
              '299,000 km/s',
              '298,792 km/s'
            ],
            correctAnswerIndex: 0,
            source: 'کتاب فیزیک',
            explanation:
                'سرعت نور در خلاء برابر با 299,792 کیلومتر بر ثانیه است',
            instructorId: authProvider.currentUser!.uid,
            status: 'pending',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          Question(
            id: '3',
            text: 'پایتخت ایران کجاست؟',
            options: ['تهران', 'اصفهان', 'شیراز', 'مشهد'],
            correctAnswerIndex: 0,
            source: 'کتاب جغرافیا',
            explanation: 'تهران پایتخت ایران است',
            instructorId: authProvider.currentUser!.uid,
            status: 'rejected',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshQuestions() async {
    await _loadQuestions();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuestions = _getFilteredAndSortedQuestions();

    return Consumer<app_auth.AuthProvider>(
      // ← اصلاح Consumer
      builder: (context, authProvider, child) {
        if (authProvider.currentUser == null) {
          return const Center(child: Text('لطفاً وارد شوید'));
        }
        return RoleBasedAccess(
          requiredRole: UserRole.instructor,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('مدیریت سوالات'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addQuestion,
                  tooltip: 'افزودن سوال جدید',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshQuestions,
                  tooltip: 'تازه‌سازی',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'all',
                      child: Text('همه سوالات'),
                    ),
                    const PopupMenuItem(
                      value: 'pending',
                      child: Text('در انتظار تأیید'),
                    ),
                    const PopupMenuItem(
                      value: 'approved',
                      child: Text('تأیید شده'),
                    ),
                    const PopupMenuItem(
                      value: 'rejected',
                      child: Text('رد شده'),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.sort),
                  onPressed: _showSortOptions,
                  tooltip: 'مرتب‌سازی',
                ),
              ],
            ),
            body: Column(
              children: [
                // بخش جستجو
                _buildSearchBar(),
                // بخش آمار
                _buildStatsCards(),
                // بخش فیلتر وضعیت
                _buildStatusFilter(),
                // بخش لیست سوالات
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage.isNotEmpty
                          ? _buildErrorState()
                          : filteredQuestions.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _refreshQuestions,
                                  child: ListView.builder(
                                    itemCount: filteredQuestions.length,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    itemBuilder: (context, index) {
                                      final question = filteredQuestions[index];
                                      return QuestionCard(
                                        question: question,
                                        onEdit: () => _editQuestion(question),
                                        onDelete: () =>
                                            _deleteQuestion(question.id),
                                        onViewDetails: () =>
                                            _showQuestionDetails(question),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'جستجوی سوال...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalCount = _questions.length;
    final pendingCount = _questions.where((q) => q.status == 'pending').length;
    final approvedCount =
        _questions.where((q) => q.status == 'approved').length;
    final rejectedCount =
        _questions.where((q) => q.status == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('کل', totalCount, Colors.blue)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildStatCard('در انتظار', pendingCount, Colors.orange)),
          const SizedBox(width: 8),
          Expanded(
              child: _buildStatCard('تأیید شده', approvedCount, Colors.green)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatCard('رد شده', rejectedCount, Colors.red)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('فیلتر: '),
          const SizedBox(width: 8),
          QuestionStatusBadge(status: _selectedStatus),
          const Spacer(),
          Text('${_getFilteredAndSortedQuestions().length} سوال'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'خطا در بارگیری سوالات',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadQuestions,
            child: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'سوالی با این مشخصات یافت نشد'
                : 'سوالی یافت نشد',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'از کلیدواژه دیگری استفاده کنید'
                : 'برای افزودن سوال جدید روی + ضربه بزنید',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'مرتب‌سازی بر اساس',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...['date', 'status', 'text'].map((option) {
              final titles = {
                'date': 'تاریخ ایجاد',
                'status': 'وضعیت',
                'text': 'متن سوال',
              };
              return ListTile(
                title: Text(titles[option]!),
                trailing: _sortOption == option
                    ? Icon(_isAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortOption == option) {
                      _isAscending = !_isAscending;
                    } else {
                      _sortOption = option;
                      _isAscending = true;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _addQuestion() async {
    await showDialog(
      context: context,
      builder: (context) => QuestionFormDialog(
        onSubmit: (question) async {
          try {
            final questionService = QuestionService(); // ← ایجاد instance
            await questionService.addQuestion(question);
            _showSuccess('سوال با موفقیت اضافه شد');
            _loadQuestions();
          } catch (e) {
            _showError('خطا در افزودن سوال: $e');
          }
        },
      ),
    );
  }

  Future<void> _editQuestion(Question question) async {
    await showDialog(
      context: context,
      builder: (context) => QuestionFormDialog(
        question: question,
        onSubmit: (updatedQuestion) async {
          try {
            final questionService = QuestionService(); // ← ایجاد instance
            await questionService.updateQuestion(updatedQuestion);
            _showSuccess('سوال با موفقیت ویرایش شد');
            _loadQuestions();
          } catch (e) {
            _showError('خطا در ویرایش سوال: $e');
          }
        },
      ),
    );
  }

  Future<void> _deleteQuestion(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: const Text('آیا از حذف این سوال اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final questionService = QuestionService(); // ← ایجاد instance
        await questionService.deleteQuestion(questionId);
        _showSuccess('سوال با موفقیت حذف شد');
        _loadQuestions();
      } catch (e) {
        _showError('خطا در حذف سوال: $e');
      }
    }
  }

  void _showQuestionDetails(Question question) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'جزئیات سوال',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  QuestionStatusBadge(status: question.status),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'متن سوال:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(question.text),
              const SizedBox(height: 12),
              const Text(
                'گزینه‌ها:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...question.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isCorrect = index == question.correctAnswerIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isCorrect ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            color: isCorrect
                                ? Colors.green.shade800
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              if (question.source != null) ...[
                const SizedBox(height: 12),
                Text(
                  'منبع: ${question.source}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
              if (question.explanation != null) ...[
                const SizedBox(height: 12),
                const Text(
                  'توضیحات:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(question.explanation!),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('بستن'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onEdit;
  final VoidCallback onDelete; // ← اضافه شد
  final VoidCallback onViewDetails;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onEdit,
    required this.onDelete, // ← اضافه شد
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(question.status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onViewDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      question.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  QuestionStatusBadge(status: question.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${question.createdAt.day}/${question.createdAt.month}/${question.createdAt.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (question.source != null) ...[
                    Icon(Icons.source, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      question.source!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('جزئیات'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('ویرایش'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete, // ← اصلاح شد
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('حذف'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getStatusColor(String status) {
  switch (status) {
    case 'pending':
      return Colors.orange;
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

class QuestionFormDialog extends StatefulWidget {
  final Question? question;
  final Function(Question) onSubmit;

  const QuestionFormDialog({
    super.key,
    this.question,
    required this.onSubmit,
  });

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _sourceController = TextEditingController();
  final _explanationController = TextEditingController();
  final List<TextEditingController> _optionControllers = [];
  int _correctAnswerIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.question != null) {
      _textController.text = widget.question!.text;
      _sourceController.text = widget.question!.source ?? '';
      _explanationController.text = widget.question!.explanation ?? '';
      _correctAnswerIndex = widget.question!.correctAnswerIndex;
      _optionControllers.addAll(
        widget.question!.options
            .map((option) => TextEditingController(text: option)),
      );
    } else {
      for (int i = 0; i < 4; i++) {
        _optionControllers.add(TextEditingController());
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _sourceController.dispose();
    _explanationController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.question == null ? 'افزودن سوال جدید' : 'ویرایش سوال'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'متن سوال *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'لطفاً متن سوال را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ..._optionControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
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
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: 'گزینه ${index + 1} *',
                            border: const OutlineInputBorder(),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: 'منبع (اختیاری)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _explanationController,
                decoration: const InputDecoration(
                  labelText: 'توضیح پاسخ (اختیاری)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        ElevatedButton(
          onPressed: _submitForm,
          child: const Text('ذخیره'),
        ),
      ],
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final question = Question(
      id: widget.question?.id ?? const Uuid().v4(),
      text: _textController.text.trim(),
      options: _optionControllers.map((c) => c.text.trim()).toList(),
      correctAnswerIndex: _correctAnswerIndex,
      source: _sourceController.text.trim().isEmpty
          ? null
          : _sourceController.text.trim(),
      explanation: _explanationController.text.trim().isEmpty
          ? null
          : _explanationController.text.trim(),
      instructorId: Provider.of<app_auth.AuthProvider>(context, listen: false)
          .currentUser
          ?.uid,
      status: widget.question?.status ?? 'pending',
      createdAt: widget.question?.createdAt ?? DateTime.now(),
    );

    widget.onSubmit(question);
    Navigator.pop(context);
  }
}
