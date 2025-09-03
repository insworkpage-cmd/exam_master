import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../services/capacity_service.dart';
import '../utils/logger.dart';

class CapacityIndicator extends StatefulWidget {
  final VoidCallback? onRequestMore;
  const CapacityIndicator({
    super.key,
    this.onRequestMore,
  });

  @override
  State<CapacityIndicator> createState() => _CapacityIndicatorState();
}

class _CapacityIndicatorState extends State<CapacityIndicator> {
  int _remainingCapacity = 10;
  bool _isBlocked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserCapacity();
  }

  Future<void> _checkUserCapacity() async {
    setState(() {
      _isLoading = true;
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
        });
      }
    } catch (e) {
      Logger.error('Error checking user capacity: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_isBlocked) {
      return Card(
        color: Colors.red.shade50, // اصلاح شده: استفاده از shade50
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.block, color: Colors.red, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سرویس پیشنهاد سوال مسدود شده',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors
                            .red.shade800, // اصلاح شده: استفاده از shade800
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'لطفاً با پشتیبانی تماس بگیرید',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade600, // اصلاح شده: استفاده از shade600
                ),
              ),
            ],
          ),
        ),
      );
    }

    Color capacityColor = Colors.green;
    String capacityText = 'ظرفیت کافی';

    if (_remainingCapacity <= 3) {
      capacityColor = Colors.orange;
      capacityText = 'ظرفیت در حال اتمام';
    } else if (_remainingCapacity <= 0) {
      capacityColor = Colors.red;
      capacityText = 'ظرفیت تمام شده';
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
                  _remainingCapacity > 3
                      ? Icons.check_circle
                      : _remainingCapacity > 0
                          ? Icons.warning
                          : Icons.error,
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
                if (_remainingCapacity <= 3 && widget.onRequestMore != null)
                  TextButton(
                    onPressed: widget.onRequestMore,
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
}
