import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
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
  bool _isPasswordFieldEnabled = true;
  String? _emailError; // اضافه کردن متغیر برای خطای ایمیل

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _emailController.addListener(_checkEmailInput);
  }

  @override
  void dispose() {
    _emailController.removeListener(_checkEmailInput);
    _emailController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    final rand = Random();
    _firstNumber = rand.nextInt(10);
    _secondNumber = rand.nextInt(10);
    _captchaController.clear();
  }

  void _checkEmailInput() {
    final text = _emailController.text;
    // بررسی آیا کاربر فارسی تایپ کرده است
    final hasFarsi = RegExp(r'[\u0600-\u06FF]').hasMatch(text);

    setState(() {
      _isPasswordFieldEnabled = !hasFarsi;

      // تنظیم پیام خطا برای فارسی
      if (hasFarsi) {
        _emailError = 'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)';
      } else {
        // فقط اگر خطای فارسی بود آن را پاک کن، خطاهای دیگر باقی بمانند
        if (_emailError == 'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)') {
          _emailError = null;
        }
      }
    });
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
      final userRole = authProvider.userRole;
      debugPrint('User role after login: $userRole');
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
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
        route = '/admin_dashboard';
        break;
      case UserRole.moderator:
        route = '/moderator_dashboard';
        break;
      case UserRole.instructor:
        route = '/instructor_dashboard';
        break;
      case UserRole.student:
        route = '/student_dashboard';
        break;
      case UserRole.normaluser:
        route = '/normaluser_dashboard';
        break;
      default:
        route = '/guest_home';
    }
    debugPrint('Navigating to route: $route');
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('ورود با ایمیل'),
            centerTitle: true,
            backgroundColor: Colors.amber[700],
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                tooltip: isDarkMode ? 'حالت روشن' : 'حالت تاریک',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
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
                          padding: const EdgeInsets.all(20),
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
                                Icons.login,
                                size: 64,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ورود به حساب کاربری',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          key: const ValueKey('emailField'),
                          controller: _emailController,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'ایمیل',
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
                            errorText: _emailError, // نمایش خطا در زیر کادر
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              _emailError = 'ایمیل را وارد کنید';
                              return 'ایمیل را وارد کنید';
                            }
                            // بررسی حروف فارسی
                            if (RegExp(r'[\u0600-\u06FF]').hasMatch(value)) {
                              _emailError =
                                  'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)';
                              return 'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              _emailError = 'ایمیل نامعتبر است';
                              return 'ایمیل نامعتبر است';
                            }
                            _emailError =
                                null; // پاک کردن خطا در صورت صحیح بودن
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('passwordField'),
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          enabled: _isPasswordFieldEnabled,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            labelText: 'رمز عبور',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: _showPassword
                                  ? const Icon(Icons.visibility_off)
                                  : const Icon(Icons.visibility),
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
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
                                icon: Icon(
                                  Icons.person_add_alt_1,
                                  color: isDarkMode
                                      ? Colors.amber[300]
                                      : Colors.amber[700],
                                ),
                                label: Text(
                                  'ثبت‌نام',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.amber[300]
                                        : Colors.amber[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                key: const ValueKey('goToResetPasswordButton'),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/reset-password');
                                },
                                icon: Icon(
                                  Icons.lock_reset,
                                  color: isDarkMode
                                      ? Colors.amber[300]
                                      : Colors.amber[700],
                                ),
                                label: Text(
                                  'فراموشی رمز عبور',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.amber[300]
                                        : Colors.amber[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
