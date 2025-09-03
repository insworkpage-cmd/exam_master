import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // اصلاح شده: اضافه کردن import
import '../../providers/auth_provider.dart' as app_auth;
import '../../services/capacity_service.dart';
import '../../utils/logger.dart';

class RequestCapacityPage extends StatefulWidget {
  const RequestCapacityPage({super.key});

  @override
  State<RequestCapacityPage> createState() => _RequestCapacityPageState();
}

class _RequestCapacityPageState extends State<RequestCapacityPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  int _currentCapacity = 0;
  bool _isLoadingCapacity = true;

  @override
  void initState() {
    super.initState();
    _loadUserCapacity();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCapacity() async {
    setState(() {
      _isLoadingCapacity = true;
    });
    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }
      final capacityStatus = await CapacityService.getUserCapacityStatus(
        authProvider.currentUser!.uid,
      );
      setState(() {
        _currentCapacity = capacityStatus['capacity'] ?? 0;
        _isLoadingCapacity = false;
      });
    } catch (e) {
      Logger.error('Error loading user capacity: $e');
      setState(() {
        _isLoadingCapacity = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('درخواست افزایش ظرفیت پیشنهاد سوال'),
      ),
      body: _isLoadingCapacity
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // نمایش وضعیت فعلی ظرفیت
                    _buildCapacityInfo(),
                    const SizedBox(height: 24),
                    // راهنما
                    _buildGuideCard(),
                    const SizedBox(height: 24),
                    // فرم درخواست
                    _buildRequestForm(),
                    const SizedBox(height: 32),
                    // دکمه ارسال
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCapacityInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'وضعیت فعلی ظرفیت شما',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: _currentCapacity / 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _currentCapacity > 3 ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$_currentCapacity از 10',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _currentCapacity > 3
                  ? 'شما ظرفیت کافی برای پیشنهاد سوال دارید.'
                  : 'ظرفیت شما در حال اتمام است. برای ادامه پیشنهاد سوال، درخواست افزایش ظرفیت دهید.',
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

  Widget _buildGuideCard() {
    return Card(
      color: Colors.blue[50],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'راهنمای درخواست افزایش ظرفیت',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'لطفاً دلایل خود را برای درخواست افزایش ظرفیت به دقت توضیح دهید. '
              'ناظر مربوطه درخواست شما را بررسی کرده و در صورت صلاحدید، '
              'ظرفیت شما را افزایش خواهد داد. توجه داشته باشید که:\n'
              '• درخواست‌های نامربوط رد خواهند شد\n'
              '• افزایش ظرفیت منجر به کاهش امتیاز شما نمی‌شود\n'
              '• می‌توانید هر زمان ظرفیت خود را بررسی کنید',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'دلایل درخواست *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _reasonController,
          decoration: const InputDecoration(
            labelText: 'دلایل درخواست افزایش ظرفیت',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            hintText: 'لطفاً دلایل خود را با جزئیات توضیح دهید...',
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'لطفاً دلایل درخواست را وارد کنید';
            }
            if (value.trim().length < 20) {
              return 'لطفاً دلایل خود را با جزئیات بیشتری توضیح دهید (حداقل 20 کاراکتر)';
            }
            return null;
          },
        ),
      ],
    );
  }

  // اصلاح شده: انتقال child به انتهای لیست پارامترها
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRequest,
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
            : const Text('ارسال درخواست'),
      ),
    );
  }

  Future<void> _submitRequest() async {
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
      // ایجاد درخواست در سرویس پیشنهادات
      await FirebaseFirestore.instance.collection('capacity_requests').add({
        'userId': authProvider.currentUser!.uid,
        'userEmail': authProvider.currentUser!.email, // اصلاح شده: حذف ?? ''
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'requestedAt': DateTime.now().toIso8601String(),
        'currentCapacity': _currentCapacity,
        'requestedAmount': 0, // بعداً توسط ناظر پر می‌شود
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('درخواست شما با موفقیت ثبت شد'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Logger.error('Error submitting capacity request: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ثبت درخواست: $e'),
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
}
