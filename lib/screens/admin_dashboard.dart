import 'package:flutter/material.dart';
import '../../widgets/role_based_access.dart';
import '../../models/user_role.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: RoleBasedAccess(
        requiredRole: UserRole.admin,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: const Text('پنل مدیریت ادمین'),
            backgroundColor: Colors.redAccent,
            actions: [
              IconButton(
                icon: const Icon(Icons.exit_to_app),
                tooltip: 'خروج از سیستم',
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // هدر خوشامگویی
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'خوش آمدید، ادمین محترم',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Theme.of(context).primaryColor,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'به پنل مدیریت کل سیستم',
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // آمار سریع
                Text(
                  'آمار کلی سیستم',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard(
                        context, 'کاربران', '1,234', Icons.people, Colors.blue),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        context, 'سوالات', '567', Icons.quiz, Colors.green),
                    const SizedBox(width: 12),
                    _buildStatCard(
                        context, 'کلاس‌ها', '89', Icons.class_, Colors.orange),
                  ],
                ),
                const SizedBox(height: 24),
                // منوی مدیریت
                Text(
                  'منوی مدیریت',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  children: [
                    _buildManagementCard(
                      context,
                      'مدیریت کاربران',
                      Icons.manage_accounts,
                      Colors.blue,
                      () => Navigator.pushNamed(context, '/user-management'),
                    ),
                    _buildManagementCard(
                      context,
                      'مدیریت سوالات',
                      Icons.quiz,
                      Colors.green,
                      () =>
                          Navigator.pushNamed(context, '/question-management'),
                    ),
                    _buildManagementCard(
                      context,
                      'مدیریت کلاس‌ها',
                      Icons.class_,
                      Colors.orange,
                      () => Navigator.pushNamed(context, '/class-management'),
                    ),
                    _buildManagementCard(
                      context,
                      'گزارش‌گیری',
                      Icons.assessment,
                      Colors.purple,
                      () => Navigator.pushNamed(context, '/reports'),
                    ),
                    _buildManagementCard(
                      context,
                      'نظارت سیستم',
                      Icons.monitor_heart,
                      Colors.red,
                      () => Navigator.pushNamed(context, '/system-monitor'),
                    ),
                    _buildManagementCard(
                      context,
                      'تنظیمات',
                      Icons.settings,
                      Colors.grey,
                      () => Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // فعالیت‌های اخیر
                Text(
                  'فعالیت‌های اخیر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_add, color: Colors.green),
                    title: Text(
                      'کاربر جدید ثبت‌نام کرد',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '۲ دقیقه پیش',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // هدایت به صفحه کاربر
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.quiz, color: Colors.blue),
                    title: Text(
                      'سوال جدید تأیید شد',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '۵ دقیقه پیش',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, '/question-approval');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text(
                      'گزارش خطا ثبت شد',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '۱۰ دقیقه پیش',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // هدایت به صفحه گزارش‌ها
                    },
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/admin-panel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'ورود به پنل مدیریت کامل',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _handleLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'خروج از سیستم',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید خروج'),
        content: const Text('آیا مطمئن هستید که می‌خواهید از سیستم خارج شوید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
