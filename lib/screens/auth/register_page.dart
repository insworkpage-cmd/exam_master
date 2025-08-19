import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/theme_provider.dart';
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
  bool _isPasswordFieldEnabled = true;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _emailController.addListener(_validateEmailLive);
    _passwordController.addListener(_validatePasswordMatch);
    _confirmController.addListener(_validatePasswordMatch);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.removeListener(_validateEmailLive);
    _emailController.dispose();
    _passwordController.removeListener(_validatePasswordMatch);
    _passwordController.dispose();
    _confirmController.removeListener(_validatePasswordMatch);
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
    final hasFarsi = RegExp(r'[\u0600-\u06FF]').hasMatch(email);

    setState(() {
      _emailValid = _emailRegex.hasMatch(email) && !hasFarsi;
      _isPasswordFieldEnabled = !hasFarsi;

      // تنظیم پیام خطا برای فارسی
      if (hasFarsi) {
        _emailError = 'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)';
      } else if (email.isNotEmpty && !_emailValid) {
        _emailError = 'ایمیل نامعتبر است';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePasswordMatch() {
    if (_passwordController.text.isNotEmpty &&
        _confirmController.text.isNotEmpty &&
        _passwordController.text != _confirmController.text) {
      setState(() {
        _confirmPasswordError = 'رمزها با هم مطابقت ندارند';
      });
    } else {
      setState(() {
        _confirmPasswordError = null;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final captchaAnswer = int.tryParse(_captchaController.text.trim());
    if (captchaAnswer != (_firstNumber + _secondNumber)) {
      setState(() {
        _captchaController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('پاسخ کپچا اشتباه است'),
          backgroundColor: Colors.red,
        ),
      );
      _generateCaptcha();
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
        message = 'این ایمیل قبلاً ثبت شده است';
      } else if (e.code == 'invalid-email') {
        message = 'فرمت ایمیل اشتباه است';
      } else if (e.code == 'weak-password') {
        message = 'رمز عبور باید حداقل ۶ کاراکتر باشد';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطای غیرمنتظره: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ثبت‌نام'),
            centerTitle: true,
            backgroundColor: Colors.amber[700],
            automaticallyImplyLeading: false,
            actions: [
              // دکمه حالت دارک مود در سمت چپ
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                tooltip: isDarkMode ? 'حالت روشن' : 'حالت تاریک',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
              // دکمه بازگشت در سمت راست
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'بازگشت',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        const Color(0xFF1a1a2e),
                        const Color(0xFF16213e),
                        const Color(0xFF0f3460),
                      ]
                    : [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                        const Color(0xFFf093fb),
                      ],
              ),
            ),
            child: SafeArea(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16), // کاهش padding
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_add,
                                size: 48, // کاهش سایز آیکون
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(height: 12), // کاهش فاصله
                              Text(
                                'ایجاد حساب کاربری',
                                style: TextStyle(
                                  fontSize: 22, // کاهش سایز فونت
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24), // کاهش فاصله
                        TextFormField(
                          key: const ValueKey('nameField'),
                          controller: _nameController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'نام و نام خانوادگی',
                            hintText: 'نام کامل خود را وارد کنید',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.7),
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
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'ایمیل',
                            hintText: 'مثال: user@example.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.email),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.7),
                            errorStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            errorText: _emailError,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              _emailError = 'ایمیل را وارد کنید';
                              return 'ایمیل را وارد کنید';
                            }
                            // بررسی حروف فارسی
                            if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
                              _emailError =
                                  'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)';
                              return 'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)';
                            }
                            if (!_emailRegex.hasMatch(value.trim())) {
                              _emailError = 'ایمیل نامعتبر است';
                              return 'ایمیل نامعتبر است';
                            }
                            _emailError = null;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('passwordField'),
                          enabled: _isPasswordFieldEnabled,
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'رمز عبور',
                            hintText:
                                'رمز قوی برای امنیت حساب خودتان انتخاب کنید',
                            helperText: 'حداقل ۶ کاراکتر وارد کنید',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: _showPassword
                                  ? const Icon(Icons.visibility_off)
                                  : const Icon(Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.7),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            errorStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            errorText: _passwordError, // اضافه کردن این خط
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _passwordError = 'رمز عبور را وارد کنید';
                              });
                              return 'رمز عبور را وارد کنید';
                            }
                            if (value.length < 6) {
                              setState(() {
                                _passwordError =
                                    'رمز عبور باید حداقل ۶ کاراکتر باشد';
                              });
                              return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                            }
                            setState(() {
                              _passwordError = null;
                            });
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('confirmField'),
                          enabled: _isPasswordFieldEnabled,
                          controller: _confirmController,
                          obscureText: !_showConfirmPassword,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'تکرار رمز عبور',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: _showConfirmPassword
                                  ? const Icon(Icons.visibility_off)
                                  : const Icon(Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _showConfirmPassword = !_showConfirmPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.7),
                            errorStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            errorText: _confirmPasswordError,
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              _confirmPasswordError =
                                  'تکرار رمز عبور را وارد کنید';
                              return 'تکرار رمز عبور را وارد کنید';
                            }
                            if (value != _passwordController.text) {
                              _confirmPasswordError =
                                  'رمزها با هم مطابقت ندارند';
                              return 'رمزها با هم مطابقت ندارند';
                            }
                            _confirmPasswordError = null;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.1),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_firstNumber + $_secondNumber = ?',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.refresh),
                                    onPressed: () {
                                      _generateCaptcha();
                                      setState(() {});
                                    },
                                    tooltip: 'تغییر کپچا',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const ValueKey('captchaField'),
                                controller: _captchaController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  labelText: 'پاسخ کپچا',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.7),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'پاسخ کپچا را وارد کنید';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24), // کاهش فاصله
                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              key: const ValueKey('registerButton'),
                              onPressed: _emailValid ? _register : null,
                              icon: const Icon(Icons.person_add),
                              label: const Text('ثبت‌نام'),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor:
                                    Colors.indigo, // تغییر رنگ به آبی
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
