import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/user_role.dart';
import '../auth/email_login_page.dart';
import '../student/student_class_page.dart';

// حذف شد: import '../../models/user_model.dart';

class StudentInviteHandler extends StatefulWidget {
  final String classIdFromLink;
  const StudentInviteHandler({super.key, required this.classIdFromLink});

  @override
  State<StudentInviteHandler> createState() => _StudentInviteHandlerState();
}

class _StudentInviteHandlerState extends State<StudentInviteHandler> {
  bool _loading = true;
  bool _isLoggedIn = false;
  bool _processingInvite = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isLoggedIn;

    setState(() {
      _isLoggedIn = isLoggedIn;
      _loading = false;
    });

    // اگر کاربر لاگین کرده بود، دعوت رو پردازش کن
    if (isLoggedIn) {
      _processInvite();
    }
  }

  Future<void> _processInvite() async {
    if (!mounted) return;

    setState(() {
      _processingInvite = true;
      _errorMessage = null;
    });

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final firestore = FirebaseFirestore.instance;

      // 1. بررسی اینکه کاربر قبلاً دانشجو بوده یا نه
      if (authProvider.userRole != UserRole.student) {
        // تغییر نقش کاربر به دانشجو
        await authProvider.updateUserRole(UserRole.student);
      }

      // 2. اضافه کردن کاربر به کلاس
      if (authProvider.currentUser != null) {
        final classRef =
            firestore.collection('classes').doc(widget.classIdFromLink);

        await classRef.update({
          'students': FieldValue.arrayUnion([authProvider.currentUser!.uid])
        });
      }

      // 3. هدایت به صفحه کلاس
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentClassPage(
              classIdFromInvite: widget.classIdFromLink,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطا در پردازش دعوت: ${e.toString()}';
          _processingInvite = false;
        });
      }
    }
  }

  void _onLoginSuccess() {
    if (mounted) {
      setState(() {
        _isLoggedIn = true;
      });
      // بعد از لاگین موفق، دعوت رو پردازش کن
      _processInvite();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _checkLoginStatus();
                },
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    if (_processingInvite) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('در حال پردازش دعوت...'),
            ],
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return EmailLoginPage(
        onLoginSuccess: _onLoginSuccess,
      );
    }

    // این حالت نباید رخ بده چون بعد از لاگین مستقیماً پردازش دعوت انجام میشه
    return const Scaffold(
      body: Center(child: Text('در حال هدایت به کلاس...')),
    );
  }
}
