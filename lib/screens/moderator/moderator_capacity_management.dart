import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/capacity_service.dart';
import '../../utils/logger.dart';

class ModeratorCapacityManagementPage extends StatefulWidget {
  const ModeratorCapacityManagementPage({super.key});

  @override
  State<ModeratorCapacityManagementPage> createState() =>
      _ModeratorCapacityManagementPageState();
}

class _ModeratorCapacityManagementPageState
    extends State<ModeratorCapacityManagementPage> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت درخواست‌های افزایش ظرفیت'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('capacity_requests')
            .where('status', isEqualTo: 'pending')
            .orderBy('requestedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'درخواستی وجود ندارد',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final request = requests[index];
              final data = request.data() as Map<String, dynamic>;

              return RequestCard(
                request: request,
                data: data,
                onApprove: () => _showApprovalDialog(request.id, data),
                onReject: () => _showRejectionDialog(request.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showApprovalDialog(
      String requestId, Map<String, dynamic> data) async {
    _amountController.text = '5'; // مقدار پیش‌فرض

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید افزایش ظرفیت'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('کاربر: ${data['userEmail']}'),
            const SizedBox(height: 8),
            Text('دلیل: ${data['reason']}'),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'مقدار افزایش',
                border: OutlineInputBorder(),
                hintText: 'مقدار افزایش ظرفیت را وارد کنید',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأیید'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final amount = int.tryParse(_amountController.text) ?? 5;

      try {
        // به‌روزرسانی درخواست
        await FirebaseFirestore.instance
            .collection('capacity_requests')
            .doc(requestId)
            .update({
          'status': 'approved',
          'approvedAt': DateTime.now().toIso8601String(),
          'approvedBy': 'moderator', // باید از کاربر فعلی استفاده شود
          'approvedAmount': amount,
        });

        // افزایش ظرفیت کاربر
        await CapacityService.increaseProposalCapacity(data['userId'], amount);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('درخواست با موفقیت تأیید شد'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        Logger.error('Error approving capacity request: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در تأیید درخواست: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRejectionDialog(String requestId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رد درخواست'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('آیا از رد این درخواست اطمینان دارید؟'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'دلیل رد (اختیاری)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('رد'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('capacity_requests')
            .doc(requestId)
            .update({
          'status': 'rejected',
          'rejectedAt': DateTime.now().toIso8601String(),
          'rejectedBy': 'moderator', // باید از کاربر فعلی استفاده شود
          'rejectionReason': reasonController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('درخواست با موفقیت رد شد'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        Logger.error('Error rejecting capacity request: $e');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در رد درخواست: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class RequestCard extends StatelessWidget {
  final DocumentSnapshot request;
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const RequestCard({
    super.key,
    required this.request,
    required this.data,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final requestedAt = (data['requestedAt'] as Timestamp).toDate();

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
                    'درخواست از: ${data['userEmail']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'در انتظار',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'تاریخ درخواست: ${requestedAt.year}/${requestedAt.month}/${requestedAt.day}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'دلیل:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data['reason'],
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('رد'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: const Text('تأیید'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
