import 'package:flutter/material.dart';
import '../../widgets/role_based_access.dart';
import '../../models/user_role.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.admin,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل مدیریت ادمین'),
          backgroundColor: Colors.redAccent,
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خوش آمدید، ادمین محترم',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'به پنل مدیریت کل سیستم',
                            style: TextStyle(
                              color: Colors.grey[600],
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
              const Text(
                'آمار کلی سیستم',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatCard('کاربران', '1,234', Icons.people, Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard('سوالات', '567', Icons.quiz, Colors.green),
                  const SizedBox(width: 12),
                  _buildStatCard('کلاس‌ها', '89', Icons.class_, Colors.orange),
                ],
              ),

              const SizedBox(height: 24),

              // منوی مدیریت
              const Text(
                'منوی مدیریت',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                    'مدیریت کاربران',
                    Icons.manage_accounts,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/user-management'),
                  ),
                  _buildManagementCard(
                    'مدیریت سوالات',
                    Icons.quiz,
                    Colors.green,
                    () => Navigator.pushNamed(context, '/question-management'),
                  ),
                  _buildManagementCard(
                    'مدیریت کلاس‌ها',
                    Icons.class_,
                    Colors.orange,
                    () => Navigator.pushNamed(context, '/class-management'),
                  ),
                  _buildManagementCard(
                    'گزارش‌گیری',
                    Icons.assessment,
                    Colors.purple,
                    () => Navigator.pushNamed(context, '/reports'),
                  ),
                  _buildManagementCard(
                    'نظارت سیستم',
                    Icons.monitor_heart,
                    Colors.red,
                    () => Navigator.pushNamed(context, '/system-monitor'),
                  ),
                  _buildManagementCard(
                    'تنظیمات',
                    Icons.settings,
                    Colors.grey,
                    () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // فعالیت‌های اخیر
              const Text(
                'فعالیت‌های اخیر',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.green),
                  title: const Text('کاربر جدید ثبت‌نام کرد'),
                  subtitle: const Text('۲ دقیقه پیش'),
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
                  title: const Text('سوال جدید تأیید شد'),
                  subtitle: const Text('۵ دقیقه پیش'),
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
                  title: const Text('گزارش خطا ثبت شد'),
                  subtitle: const Text('۱۰ دقیقه پیش'),
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
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/admin-panel');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'ورود به پنل مدیریت کامل',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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
      ),
    );
  }

  Widget _buildManagementCard(
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
                style: const TextStyle(
                  // ✅ const اضافه شد
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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
