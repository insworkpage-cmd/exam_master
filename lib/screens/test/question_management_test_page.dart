import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth; // ← اصلاح import
import '../../models/user_role.dart';
import '../../widgets/question_status_badge.dart';

class QuestionManagementTestPage extends StatelessWidget {
  const QuestionManagementTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تست مدیریت سوالات'),
      ),
      body: Consumer<app_auth.AuthProvider>(
        // ← اصلاح: AuthProvider با prefix
        builder: (context, authProvider, child) {
          if (authProvider.currentUser == null) {
            return const Center(child: Text('لطفاً وارد شوید'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTestCard(
                context,
                'تست افزودن سوال',
                'بررسی افزودن سوال توسط مدرس',
                Icons.add,
                Colors.blue,
                () => Navigator.pushNamed(
                    context, '/instructor_question_management'), // ← اصلاح مسیر
              ),
              _buildTestCard(
                context,
                'تست تأیید سوال',
                'بررسی تأیید سوال توسط ناظر محتوا',
                Icons.approval,
                Colors.green,
                () => Navigator.pushNamed(
                    context, '/moderator_question_approval'), // ← اصلاح مسیر
              ),
              _buildTestCard(
                context,
                'تست دسترسی‌ها',
                'بررسی دسترسی‌های مختلف بر اساس نقش',
                Icons.security,
                Colors.orange,
                () => _testAccesses(context, authProvider.currentUser!.role),
              ),
              _buildTestCard(
                context,
                'تست وضعیت‌ها',
                'بررسی نمایش وضعیت‌های مختلف سوال',
                Icons.visibility,
                Colors.purple,
                () => _testStatuses(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _testAccesses(BuildContext context, UserRole userRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تست دسترسی‌ها'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نقش فعلی: ${userRole.persianName}'),
            const SizedBox(height: 16),
            Text('سطح دسترسی: ${userRole.level}'),
            const SizedBox(height: 16),
            _buildAccessTestItem(
              'افزودن سوال',
              userRole.level >= UserRole.instructor.level,
            ),
            _buildAccessTestItem(
              'ویرایش سوال',
              userRole.level >= UserRole.instructor.level,
            ),
            _buildAccessTestItem(
              'حذف سوال',
              userRole.level >= UserRole.admin.level,
            ),
            _buildAccessTestItem(
              'تأیید سوال',
              userRole.level >=
                  UserRole
                      .moderator.level, // ← اصلاح: contentModerator → moderator
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTestItem(String action, bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            hasAccess ? Icons.check_circle : Icons.cancel,
            color: hasAccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(action),
        ],
      ),
    );
  }

  void _testStatuses(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تست وضعیت‌ها'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusTestItem('در انتظار تأیید', 'pending'),
            _buildStatusTestItem('تأیید شده', 'approved'),
            _buildStatusTestItem('رد شده', 'rejected'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTestItem(String label, String status) {
    return Card(
      child: ListTile(
        leading: QuestionStatusBadge(status: status),
        title: Text(label),
        subtitle: Text('کد وضعیت: $status'),
      ),
    );
  }
}
