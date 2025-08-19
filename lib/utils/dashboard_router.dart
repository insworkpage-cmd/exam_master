import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../screens/admin_dashboard.dart';
import '../screens/moderator_dashboard.dart';
import '../screens/instructor/class_list_page.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/normal_user_dashboard.dart'; // ← اضافه شد

class DashboardRouter extends StatelessWidget {
  final UserModel user;
  const DashboardRouter({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.moderator: // ← اصلاح: contentModerator → moderator
        return const ModeratorDashboard();
      case UserRole.instructor:
        return const InstructorClassListPage();
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.normaluser: // ← اضافه شد
        return const NormalUserDashboard();
      case UserRole.guest: // ← اضافه شد برای کاربران مهمان
        return const Scaffold(
          body: Center(child: Text('شما به عنوان مهمان وارد شده‌اید')),
        );
      default:
        return const Scaffold(
          body: Center(child: Text('داشبورد کاربر')),
        );
    }
  }
}
