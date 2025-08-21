import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../widgets/role_based_access.dart';
import '../providers/auth_provider.dart' as app_auth;

class ModeratorDashboard extends StatelessWidget {
  const ModeratorDashboard({super.key});

  Future<void> _performLogout(BuildContext context) async {
    try {
      debugPrint('=== LOGOUT PROCESS STARTED ===');
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);

      // نمایش پیام در حال خروج
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('در حال خروج از حساب کاربری...'),
          duration: Duration(seconds: 2),
        ),
      );

      await authProvider.signOut();
      debugPrint('=== SIGN OUT COMPLETED ===');

      if (context.mounted) {
        debugPrint('=== NAVIGATING TO HOME SCREEN ===');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('با موفقیت از حساب کاربری خارج شدید'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('=== LOGOUT ERROR: $e ===');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در خروج: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    debugPrint('=== LOGOUT DIALOG SHOWED ===');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروج از حساب'),
        content: const Text('آیا از خروج از حساب کاربری اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              debugPrint('=== LOGOUT CANCELED ===');
            },
            child: const Text('لغو'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              debugPrint('=== LOGOUT CONFIRMED ===');
              await _performLogout(context);
            },
            style: TextButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.moderator,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل ناظر'),
          centerTitle: true,
          backgroundColor: Colors.orange,
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'پروفایل کاربری',
              onPressed: () {
                debugPrint('=== PROFILE BUTTON PRESSED ===');
                Navigator.pushNamed(context, '/profile');
              },
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'خروج از حساب کاربری',
              onPressed: () {
                debugPrint('=== LOGOUT BUTTON PRESSED ===');
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.orange,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.content_paste,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'پنل ناظر',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Consumer<app_auth.AuthProvider>(
                      builder: (context, authProvider, child) {
                        return Text(
                          'کاربر: ${authProvider.currentUser?.name ?? "ناشناس"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('داشبورد'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.approval),
                title: const Text('تأیید سوالات'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/moderator_question_approval');
                },
              ),
              ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('گزارش‌ها'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/reports');
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('پروفایل کاربری'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('خروج از حساب'),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'داشبورد ناظر آموزشی',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // کارت آمار
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'آمار کلی',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard('سوالات در انتظار تأیید', '24',
                              Icons.hourglass_top),
                          _buildStatCard(
                              'سوالات تأیید شده', '156', Icons.check_circle),
                          _buildStatCard('سوالات رد شده', '12', Icons.cancel),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // بخش اقدامات
              const Text(
                'اقدامات سریع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    'تأیید سوالات',
                    Icons.approval,
                    Colors.orange,
                    () => Navigator.pushNamed(
                        context, '/moderator_question_approval'),
                  ),
                  _buildActionCard(
                    'گزارش‌ها',
                    Icons.assessment,
                    Colors.blue,
                    () => Navigator.pushNamed(context, '/reports'),
                  ),
                  _buildActionCard(
                    'پروفایل کاربری',
                    Icons.person,
                    Colors.green,
                    () => Navigator.pushNamed(context, '/profile'),
                  ),
                  _buildActionCard(
                    'تنظیمات',
                    Icons.settings,
                    Colors.purple,
                    () => Navigator.pushNamed(context, '/settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.orange),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(title),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
