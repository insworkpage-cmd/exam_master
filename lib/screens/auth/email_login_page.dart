import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_role.dart';
import 'dart:math';

class EmailLoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const EmailLoginPage({super.key, this.onLoginSuccess});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  int _firstNumber = 0;
  int _secondNumber = 0;
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    final rand = Random();
    _firstNumber = rand.nextInt(10);
    _secondNumber = rand.nextInt(10);
    _captchaController.clear();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final enteredCaptcha = int.tryParse(_captchaController.text.trim());
    final expectedCaptcha = _firstNumber + _secondNumber;

    if (enteredCaptcha != expectedCaptcha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پاسخ کپچا اشتباه است'),
          backgroundColor: Colors.red,
        ),
      );
      _generateCaptcha();
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      // دریافت نقش کاربر (اصلاح شد)
      final userRole = authProvider.userRole;
      debugPrint('User role after login: $userRole');

      // فراخوانی onLoginSuccess اگر وجود داشته باشد
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        // هدایت بر اساس نقش
        _navigateToDashboard(userRole);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard(UserRole? role) {
    String route;
    debugPrint('Navigating based on role: $role');

    switch (role) {
      case UserRole.admin:
        route = '/admin_dashboard'; // ← اصلاح مسیر
        break;
      case UserRole.moderator:
        route = '/moderator_dashboard'; // ← اصلاح: contentModerator → moderator
        break;
      case UserRole.instructor:
        route = '/instructor_dashboard'; // ← اصلاح مسیر
        break;
      case UserRole.student:
        route = '/student_dashboard'; // ← اصلاح مسیر
        break;
      case UserRole.normaluser:
        route = '/normaluser_dashboard'; // ← اضافه شد
        break;
      default:
        route = '/guest_home'; // ← اصلاح: profile → guest_home
    }

    debugPrint('Navigating to route: $route');
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ورود با ایمیل')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const ValueKey('emailField'),
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'ایمیل',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ایمیل را وارد کنید';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'ایمیل نامعتبر است';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('passwordField'),
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'رمز عبور',
                      border: const OutlineInputBorder(), // ← اضافه کردن const
                      prefixIcon: const Icon(Icons.lock), // ← اضافه کردن const
                      suffixIcon: IconButton(
                        icon: _showPassword
                            ? const Icon(
                                Icons.visibility_off) // ← اضافه کردن const
                            : const Icon(
                                Icons.visibility), // ← اضافه کردن const
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'رمز عبور را وارد کنید';
                      }
                      if (value.length < 6) {
                        return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '🔐 کپچا: $_firstNumber + $_secondNumber = ?',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          _generateCaptcha();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  TextFormField(
                    key: const ValueKey('captchaField'),
                    controller: _captchaController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'پاسخ کپچا',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'پاسخ کپچا را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: const ValueKey('loginButton'),
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'ورود',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          key: const ValueKey('goToRegisterButton'),
                          onPressed: () {
                            Navigator.pushNamed(context, '/register');
                          },
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('ثبت‌نام'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          key: const ValueKey('goToResetPasswordButton'),
                          onPressed: () {
                            Navigator.pushNamed(context, '/reset-password');
                          },
                          icon: const Icon(Icons.lock_reset),
                          label: const Text('فراموشی رمز عبور'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
