import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_based_access.dart'; // ✅ مسیر اصلاح شد
import '../../providers/auth_provider.dart';
import '../../models/user_role.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.admin,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تنظیمات سیستم'),
          backgroundColor: Colors.redAccent,
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingsSection(
                  'عمومی',
                  [
                    _buildSettingItem(
                      'اطلاعات سیستم',
                      Icons.info,
                      () => _showSystemInfo(context),
                    ),
                    _buildSettingItem(
                      'پشتیبان‌گیری',
                      Icons.backup,
                      () => _showBackupDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  'امنیت',
                  [
                    _buildSettingItem(
                      'مدیریت دسترسی‌ها',
                      Icons.security,
                      () => _showAccessManagement(context),
                    ),
                    _buildSettingItem(
                      'لاگ‌های سیستم',
                      Icons.receipt_long,
                      () => _showSystemLogs(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  'پیشرفته',
                  [
                    _buildSettingItem(
                      'پاکسازی کش',
                      Icons.cleaning_services,
                      () => _showClearCacheDialog(context),
                    ),
                    _buildSettingItem(
                      'تنظیمات API',
                      Icons.api,
                      () => _showApiSettings(context),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showSystemInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اطلاعات سیستم'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نسخه برنامه: 1.0.0'),
            Text('نسخه Flutter: 3.16.0'),
            Text('نسخه Dart: 3.2.0'),
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

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پشتیبان‌گیری'),
        content: const Text('آیا از پشتیبان‌گیری مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('پشتیبان‌گیری با موفقیت انجام شد')),
              );
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }

  void _showAccessManagement(BuildContext context) {
    Navigator.pushNamed(context, '/user-management');
  }

  void _showSystemLogs(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('این قابلیت در حال توسعه است')),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاکسازی کش'),
        content: const Text('آیا از پاکسازی کش مطمئن هستید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('کش با موفقیت پاکسازی شد')),
              );
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }

  void _showApiSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('این قابلیت در حال توسعه است')),
    );
  }
}
