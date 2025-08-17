import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_based_access.dart'; // ✅ مسیر اصلاح شد
import '../../providers/auth_provider.dart';
import '../../models/user_role.dart';

class ClassManagementPage extends StatelessWidget {
  const ClassManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.admin,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت کلاس‌ها'),
          backgroundColor: Colors.redAccent,
        ),
        body: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildClassesList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'کل کلاس‌ها',
            '24',
            Icons.class_,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'دانشجویان',
            '342',
            Icons.people,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'لیست کلاس‌ها',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.class_, color: Colors.blue),
                title: Text('کلاس ${index + 1}'),
                subtitle: Text('مدرس: استاد ${index + 1}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Navigate to class details
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
