import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../screens/admin_dashboard.dart'; // ✅ مسیر صحیح
import '../screens/moderator_dashboard.dart'; // ✅ مسیر صحیح
import '../screens/instructor/class_list_page.dart';
import '../screens/student/student_dashboard.dart';

class DashboardRouter extends StatelessWidget {
  final UserModel user;

  const DashboardRouter({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.contentModerator:
        return const ModeratorDashboard();
      case UserRole.instructor:
        return const InstructorClassListPage();
      case UserRole.student:
        return const StudentDashboard();
      default:
        return const Scaffold(
          body: Center(child: Text('داشبورد کاربر')),
        );
    }
  }
}
