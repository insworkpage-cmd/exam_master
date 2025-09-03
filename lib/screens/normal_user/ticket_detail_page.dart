import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../services/ticket_service.dart';

class TicketDetailPage extends StatefulWidget {
  final String ticketId;
  const TicketDetailPage({
    super.key,
    required this.ticketId,
  });

  @override
  State<TicketDetailPage> createState() => _TicketDetailPageState();
}

class _TicketDetailPageState extends State<TicketDetailPage> {
  Map<String, dynamic>? _ticket;
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _responseController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadTicket() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final ticket = await TicketService.getTicketById(widget.ticketId);

      if (ticket == null) {
        throw Exception('تیکت یافت نشد');
      }

      if (!mounted) return;

      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addResponse() async {
    // دریافت Provider قبل از هر عملیات ناهمگام
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    if (_responseController.text.trim().isEmpty) {
      if (mounted) {
        _showErrorMessage('لطفاً متن پاسخ را وارد کنید');
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (authProvider.currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      final success = await TicketService.addResponse(
        ticketId: widget.ticketId,
        responderId: authProvider.currentUser?.uid ?? '',
        responderName: authProvider.currentUser?.name ?? '',
        responderRole: 'user',
        response: _responseController.text.trim(),
        responseRole: 'user',
      );

      if (success) {
        _responseController.clear();
        await _loadTicket();

        if (mounted) {
          _showSuccessMessage('پاسخ شما با موفقیت ارسال شد');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('خطا در ارسال پاسخ: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _closeTicket() async {
    // دریافت Provider قبل از هر عملیات ناهمگام
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بستن تیکت'),
        content: const Text('آیا از بستن این تیکت اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('بستن'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (authProvider.currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      final success = await TicketService.closeTicketByUser(
        ticketId: widget.ticketId,
        userId: authProvider.currentUser!.uid,
        reason: 'بسته شده توسط کاربر',
      );

      if (success) {
        await _loadTicket();

        if (mounted) {
          _showSuccessMessage('تیکت با موفقیت بسته شد');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('خطا در بستن تیکت: $e');
      }
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed_by_user':
        return Colors.grey;
      case 'reopened':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'in_progress':
        return 'در حال بررسی';
      case 'resolved':
        return 'حل شده';
      case 'closed_by_user':
        return 'بسته شده توسط کاربر';
      case 'reopened':
        return 'بازگشتی';
      default:
        return 'ناشناخته';
    }
  }

  String _formatDateTime(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final formatter = DateFormat('yyyy/MM/dd HH:mm');
      return formatter.format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('جزئیات تیکت'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTicket,
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }
    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('جزئیات تیکت'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Text('تیکت یافت نشد'),
        ),
      );
    }
    // ignore: dead_null_aware_expression
    final status = _ticket!['status'] ?? 'unknown';
    final canClose =
        status == 'open' || status == 'in_progress' || status == 'reopened';
    final canRespond = status != 'closed_by_user' && status != 'resolved';
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات تیکت'),
        backgroundColor: Colors.blue,
        actions: [
          if (canClose)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeTicket,
              tooltip: 'بستن تیکت',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بخش اطلاعات اصلی تیکت
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _ticket!['subject'] ?? 'بدون موضوع',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _ticket!['description'] ?? 'بدون توضیحات',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.category, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'دسته‌بندی: ${_ticket!['category'] ?? 'ناشناخته'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'ایجاد: ${_formatDateTime(_ticket!['createdAt'])}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // بخش پاسخ‌ها
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'پاسخ‌ها',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_ticket!['responses'] == null ||
                        (_ticket!['responses'] as List).isEmpty)
                      const Text(
                        'پاسخی ثبت نشده است',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      )
                    else
                      ...(_ticket!['responses'] as List).map((response) {
                        final isModerator =
                            response['responderRole'] == 'moderator';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isModerator
                                ? Colors.blue[50]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      response['responderName'] ?? 'ناشناخته',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isModerator
                                            ? Colors.blue[800]
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDateTime(response['timestamp']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                response['response'] ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // بخش ارسال پاسخ جدید
            if (canRespond)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ارسال پاسخ جدید',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _responseController,
                        decoration: const InputDecoration(
                          labelText: 'متن پاسخ',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _addResponse,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('ارسال پاسخ'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
