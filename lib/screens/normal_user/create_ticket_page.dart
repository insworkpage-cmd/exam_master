import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../services/ticket_service.dart';
import '../../utils/logger.dart';

class CreateTicketPage extends StatefulWidget {
  const CreateTicketPage({super.key});

  @override
  State<CreateTicketPage> createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'technical';
  String _selectedPriority = 'normal';
  bool _isLoading = false;

  final List<String> _categories = [
    'technical',
    'account',
    'content',
    'capacity',
    'spam',
    'other',
  ];

  final List<String> _priorities = [
    'low',
    'normal',
    'high',
    'urgent',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ایجاد تیکت جدید'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'لطفاً اطلاعات تیکت را وارد کنید',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // موضوع تیکت
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'موضوع تیکت *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'لطفاً موضوع تیکت را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // توضیحات تیکت
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'توضیحات *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'لطفاً توضیحات تیکت را وارد کنید';
                  }
                  if (value.trim().length < 10) {
                    return 'لطفاً توضیحات بیشتری وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // دسته‌بندی
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'دسته‌بندی *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryText(category)),
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

              // اولویت
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'اولویت *',
                  border: OutlineInputBorder(),
                ),
                items: _priorities.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(_getPriorityText(priority)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'لطفاً اولویت را انتخاب کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // دکمه ارسال - اصلاح شده
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitTicket,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('ارسال تیکت'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      // اصلاح شده: حذف متغیر ticketId و استفاده مستقیم از نتیجه
      await TicketService.createTicket(
        userId: authProvider.currentUser!.uid,
        userEmail: authProvider.currentUser!.email, // اصلاح شده: حذف ?? ''
        userName: authProvider.currentUser!.name, // اصلاح شده: حذف ?? ''
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تیکت با موفقیت ایجاد شد'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // بازگشت به صفحه قبلی
      }
    } catch (e) {
      Logger.error('Error creating ticket: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ایجاد تیکت: $e'),
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

  String _getCategoryText(String category) {
    switch (category) {
      case 'technical':
        return 'فنی';
      case 'account':
        return 'حساب کاربری';
      case 'content':
        return 'محتوا';
      case 'capacity':
        return 'ظرفیت';
      case 'spam':
        return 'اسپم';
      case 'other':
        return 'سایر';
      default:
        return category;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'low':
        return 'پایین';
      case 'normal':
        return 'عادی';
      case 'high':
        return 'بالا';
      case 'urgent':
        return 'فوری';
      default:
        return priority;
    }
  }
}
