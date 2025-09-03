import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../widgets/capacity_indicator.dart';

class NormalUserDashboard extends StatelessWidget {
  const NormalUserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل کاربری'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            tooltip: 'اعلان‌ها',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بخش خوش‌آمدگویی و اطلاعات کاربر
            _buildWelcomeSection(context, user),
            const SizedBox(height: 24),

            // بخش ظرفیت پیشنهاد سوال
            CapacityIndicator(
              onRequestMore: () {
                Navigator.pushNamed(context, '/request_capacity');
              },
            ),
            const SizedBox(height: 24),

            // بخش دسترسی‌های سریع
            _buildQuickAccessSection(context),
            const SizedBox(height: 24),

            // بخش آمار و فعالیت‌ها
            _buildStatsSection(),
            const SizedBox(height: 24),

            // بخش اقدامات اصلی
            _buildActionsSection(context),
          ],
        ),
      ),
    );
  }

  // اصلاح شده: اضافه کردن پارامتر context و حذف const
  Widget _buildWelcomeSection(BuildContext context, user) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    Icons.person,
                    color: Colors.blue[800],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'خوش آمدید، ${user?.name ?? 'کاربر'}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'شما به عنوان کاربر عادی وارد شده‌اید',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // اصلاح شده: اضافه کردن پارامتر context
  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'دسترسی‌های سریع',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildQuickAccessCard(
              context: context,
              title: 'پیشنهاد سوال',
              icon: Icons.lightbulb_outline,
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/propose_question');
              },
            ),
            _buildQuickAccessCard(
              context: context,
              title: 'تیکت‌های من',
              icon: Icons.support_agent_outlined,
              color: Colors.green,
              onTap: () {
                Navigator.pushNamed(context, '/ticket_list');
              },
            ),
            _buildQuickAccessCard(
              context: context,
              title: 'پیشنهادات من',
              icon: Icons.history_outlined,
              color: Colors.orange,
              onTap: () {
                Navigator.pushNamed(context, '/my_proposals');
              },
            ),
            _buildQuickAccessCard(
              context: context,
              title: 'جستجوی کلاس‌ها',
              icon: Icons.search_outlined,
              color: Colors.purple,
              onTap: () {
                Navigator.pushNamed(context, '/join_class');
              },
            ),
          ],
        ),
      ],
    );
  }

  // اصلاح شده: اضافه کردن پارامتر context
  Widget _buildQuickAccessCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
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

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آمار فعالیت‌های شما',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'سوالات پیشنهادی',
              value: '5',
              icon: Icons.quiz_outlined,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'تیکت‌های فعال',
              value: '2',
              icon: Icons.support_agent_outlined,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'کلاس‌های عضو',
              value: '3',
              icon: Icons.class_outlined,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // اصلاح شده: اضافه کردن پارامتر context
  Widget _buildActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'اقدامات اصلی',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/join_class');
                },
                icon: const Icon(Icons.search),
                label: const Text('جستجوی کلاس‌ها'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile');
                },
                icon: const Icon(Icons.person_outline),
                label: const Text('پروفایل کاربری'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
