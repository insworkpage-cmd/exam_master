import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
        const SnackBar(content: Text('پاسخ کپچا اشتباه است')),
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
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.pushReplacementNamed(context, '/profile');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ورود: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    decoration: const InputDecoration(labelText: 'ایمیل'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value!.isEmpty ? 'ایمیل را وارد کنید' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('passwordField'),
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'رمز عبور',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (value) =>
                        value!.length < 6 ? 'حداقل ۶ کاراکتر وارد کنید' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('🔐 کپچا: $_firstNumber + $_secondNumber = ?'),
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
                    decoration: const InputDecoration(labelText: 'پاسخ کپچا'),
                    validator: (value) =>
                        value!.isEmpty ? 'پاسخ کپچا را وارد کنید' : null,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        ElevatedButton(
                          key: const ValueKey('loginButton'),
                          onPressed: _login,
                          child: const Text('ورود'),
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
