import 'package:flutter/material.dart';
import 'package:exam_master/screens/auth/email_login_page.dart';
import 'package:exam_master/screens/student/student_class_page.dart';

// فرض بر اینه که سیستم احراز هویت داری؛ این فقط شبیه‌سازیه
bool isUserLoggedIn = false;
String? invitedClassId;

class StudentInviteHandler extends StatefulWidget {
  final String classIdFromLink;

  const StudentInviteHandler({Key? key, required this.classIdFromLink})
      : super(key: key);

  @override
  State<StudentInviteHandler> createState() => _StudentInviteHandlerState();
}

class _StudentInviteHandlerState extends State<StudentInviteHandler> {
  bool _loading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    // شبیه‌سازی بررسی لاگین (در حالت واقعی با Firebase/AuthService جایگزین کن)
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoggedIn = isUserLoggedIn;
      invitedClassId = widget.classIdFromLink;
      _loading = false;
    });
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLoggedIn) {
      return EmailLoginPage(
        onLoginSuccess: _onLoginSuccess,
      );
    }

    // وقتی لاگین انجام شد، کاربر به کلاس منتقل می‌شود
    return StudentClassPage(classIdFromInvite: invitedClassId ?? '');
  }
}
