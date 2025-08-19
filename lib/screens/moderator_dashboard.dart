import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../widgets/role_based_access.dart';

class ModeratorDashboard extends StatelessWidget {
  const ModeratorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.moderator, // ← اصلاح: contentModerator → moderator
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پنل ناظر'),
          backgroundColor: Colors.orange,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.content_paste, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'دسترسی ناظر به بخش‌های محتوا',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                      context, '/moderator_question_approval'); // ← اصلاح مسیر
                },
                icon: const Icon(Icons.approval),
                label: const Text('تأیید سوالات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
