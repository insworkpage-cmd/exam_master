import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/user_role.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _captchaController = TextEditingController();
  final RegExp _emailRegex =
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  int _firstNumber = 0;
  int _secondNumber = 0;
  bool _emailValid = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _emailController.addListener(_validateEmailLive);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    final rand = Random();
    _firstNumber = rand.nextInt(10);
    _secondNumber = rand.nextInt(10);
    _captchaController.clear();
  }

  void _validateEmailLive() {
    final email = _emailController.text.trim();
    setState(() {
      _emailValid = _emailRegex.hasMatch(email);
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final captchaAnswer = int.tryParse(_captchaController.text.trim());
    if (captchaAnswer != (_firstNumber + _secondNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پاسخ کپچا اشتباه است')),
      );
      _generateCaptcha();
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);

      await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        role: UserRole.normaluser,
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/normaluser_dashboard');
    } on FirebaseAuthException catch (e) {
      String message = 'خطا در ثبت‌نام';
      if (e.code == 'email-already-in-use') {
        message = 'این ایمیل قبلاً ثبت شده است.';
      } else if (e.code == 'invalid-email') {
        message = 'فرمت ایمیل اشتباه است.';
      } else if (e.code == 'weak-password') {
        message = 'رمز باید حداقل ۶ کاراکتر باشد.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطای غیرمنتظره: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ثبت‌نام با ایمیل')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  key: const ValueKey('nameField'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'نام و نام خانوادگی',
                    hintText: 'نام کامل خود را وارد کنید',
                  ),
                  textDirection: TextDirection.rtl,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'نام را وارد کنید';
                    }
                    if (value.trim().length < 3) {
                      return 'نام باید حداقل ۳ کاراکتر باشد';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('emailField'),
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'ایمیل',
                    hintText: 'مثال: user@example.com',
                    errorText: _emailController.text.isNotEmpty && !_emailValid
                        ? 'ایمیل صحیح وارد کنید (فقط حروف انگلیسی)'
                        : null,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'ایمیل را وارد کنید';
                    }
                    if (!_emailRegex.hasMatch(value.trim())) {
                      return 'ایمیل صحیح وارد کنید';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('passwordField'),
                  enabled: _emailValid,
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'رمز عبور',
                    suffixIcon: IconButton(
                      icon: Icon(_showPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) => value!.length < 6
                      ? 'رمز باید حداقل ۶ کاراکتر باشد'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('confirmField'),
                  enabled: _emailValid,
                  controller: _confirmController,
                  obscureText: !_showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'تکرار رمز عبور',
                    suffixIcon: IconButton(
                      icon: Icon(_showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _showConfirmPassword = !_showConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'رمزها با هم مطابقت ندارند';
                    }
                    return null;
                  },
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
                  decoration: const InputDecoration(labelText: 'پاسخ کپچا'),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? 'پاسخ کپچا را وارد کنید' : null,
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        key: const ValueKey('registerButton'),
                        onPressed: _emailValid ? _register : null,
                        icon: const Icon(Icons.person_add),
                        label: const Text('ثبت‌نام'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
