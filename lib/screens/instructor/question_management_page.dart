import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/question_model.dart';
import '../../services/question_service.dart';
import '../../widgets/question_status_badge.dart'; // اصلاح مسیر import
import '../../models/user_role.dart';
import '../../widgets/role_based_access.dart';

class QuestionManagementPage extends StatefulWidget {
  const QuestionManagementPage({super.key});

  @override
  State<QuestionManagementPage> createState() => _QuestionManagementPageState();
}

class _QuestionManagementPageState extends State<QuestionManagementPage> {
  List<Question> _questions = [];
  bool _isLoading = false;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        _questions = await QuestionService.getQuestionsByInstructor(user.uid);
      }
    } catch (e) {
      _showError('خطا در بارگذاری سوالات: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    return Consumer<AuthProvider>(
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
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshQuestions,
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
              ],
            ),
            body: Column(
              children: [
                _buildStatsCards(),
                _buildStatusFilter(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _questions.isEmpty
                          ? const Center(child: Text('سوالی یافت نشد'))
                          : _buildQuestionsList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCards() {
    final pendingCount = _questions.where((q) => q.status == 'pending').length;
    final approvedCount =
        _questions.where((q) => q.status == 'approved').length;
    final rejectedCount =
        _questions.where((q) => q.status == 'rejected').length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'در انتظار تأیید',
              pendingCount,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'تأیید شده',
              approvedCount,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'رد شده',
              rejectedCount,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('فیلتر: '),
          const SizedBox(width: 8),
          QuestionStatusBadge(status: _selectedStatus),
        ],
      ),
    );
  }

  Widget _buildQuestionsList() {
    final filteredQuestions = _selectedStatus == 'all'
        ? _questions
        : _questions.where((q) => q.status == _selectedStatus).toList();

    return RefreshIndicator(
      onRefresh: _refreshQuestions,
      child: ListView.builder(
        itemCount: filteredQuestions.length,
        itemBuilder: (context, index) {
          final question = filteredQuestions[index];
          return QuestionCard(
            question: question,
            onEdit: () => _editQuestion(question),
            onDelete: () => _deleteQuestion(question.id),
          );
        },
      ),
    );
  }

  Future<void> _addQuestion() async {
    await showDialog(
      context: context,
      builder: (context) => QuestionFormDialog(
        onSubmit: (question) async {
          try {
            await QuestionService.addQuestion(question);
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
            await QuestionService.updateQuestion(updatedQuestion);
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
        await QuestionService.deleteQuestion(questionId);
        _showSuccess('سوال با موفقیت حذف شد');
        _loadQuestions();
      } catch (e) {
        _showError('خطا در حذف سوال: $e');
      }
    }
  }
}

class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onEdit,
    required this.onDelete,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر کارت
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStatusColor(question.status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    question.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                QuestionStatusBadge(status: question.status),
              ],
            ),
          ),

          // محتوای کارت
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // گزینه‌ها
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isCorrect = index == question.correctAnswerIndex;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCorrect ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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

                const SizedBox(height: 8),

                // اطلاعات اضافی
                if (question.source != null) ...[
                  Row(
                    children: [
                      Icon(Icons.source, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'منبع: ${question.source}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (question.instructorId != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'مدرس: ${question.instructorId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // فوتر کارت با دکمه‌ها
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('ویرایش'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
                  labelText: 'متن سوال',
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
                            labelText: 'گزینه ${index + 1}',
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
      id: widget.question?.id ?? '',
      text: _textController.text.trim(),
      options: _optionControllers.map((c) => c.text.trim()).toList(),
      correctAnswerIndex: _correctAnswerIndex,
      source: _sourceController.text.trim().isEmpty
          ? null
          : _sourceController.text.trim(),
      explanation: _explanationController.text.trim().isEmpty
          ? null
          : _explanationController.text.trim(),
      instructorId:
          Provider.of<AuthProvider>(context, listen: false).currentUser?.uid,
      status: widget.question?.status ?? 'pending',
    );

    widget.onSubmit(question);
    Navigator.pop(context);
  }
}
