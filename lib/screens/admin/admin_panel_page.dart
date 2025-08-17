// lib/screens/admin/admin_panel_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardTab(),
    const UsersManagementTab(),
    const QuestionsManagementTab(),
    const ReportsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مدیریت'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'داشبورد',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'کاربران',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_answer),
            label: 'سوالات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'گزارش‌ها',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'داشبورد مدیریت',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildStatCard('تعداد کاربران', '150', Icons.people, Colors.blue),
          _buildStatCard(
              'تعداد سوالات', '450', Icons.question_answer, Colors.green),
          _buildStatCard('تعداد کلاس‌ها', '25', Icons.class_, Colors.orange),
          _buildStatCard('تعداد آزمون‌ها', '120', Icons.quiz, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}

class UsersManagementTab extends StatelessWidget {
  const UsersManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('مدیریت کاربران - در حال توسعه'),
    );
  }
}

class QuestionsManagementTab extends StatelessWidget {
  const QuestionsManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('مدیریت سوالات - در حال توسعه'),
    );
  }
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('گزارش‌ها - در حال توسعه'),
    );
  }
}
