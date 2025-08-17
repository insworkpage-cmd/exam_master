import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JoinPage extends StatefulWidget {
  final String classId;

  const JoinPage({super.key, required this.classId});

  @override
  State<JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<JoinPage> {
  @override
  void initState() {
    super.initState();
    _handleJoin();
  }

  Future<void> _handleJoin() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // ذخیره classId برای استفاده بعد از ورود
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pendingClassId', widget.classId);

      // هدایت به صفحه ورود
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // هدایت به صفحه student_class_page
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/student-class',
          arguments: widget.classId,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
