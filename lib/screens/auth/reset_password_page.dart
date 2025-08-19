import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/theme_provider.dart';

class ResetPasswordPage extends StatefulWidget {
  final FirebaseAuth auth;
  ResetPasswordPage({Key? key, FirebaseAuth? auth})
      : auth = auth ?? FirebaseAuth.instance,
        super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmailLive);
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateEmailLive);
    _emailController.dispose();
    super.dispose();
  }

  void _validateEmailLive() {
    final email = _emailController.text.trim();
    final hasFarsi = RegExp(r'[\u0600-\u06FF]').hasMatch(email);

    setState(() {
      // تنظیم پیام خطا برای فارسی
      if (hasFarsi) {
        _emailError = 'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)';
      } else if (email.isNotEmpty &&
          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _emailError = 'ایمیل نامعتبر است';
      } else {
        _emailError = null;
      }
    });
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      // تنظیمات اکشن کد برای لینک بازیابی
      var actionCodeSettings = ActionCodeSettings(
        url:
            'https://exammaster.page.link/reset-password', // آدرس صفحه بازیابی شما
        handleCodeInApp: true,
        iOSBundleId: 'com.example.exam_master',
        androidPackageName: 'com.example.exam_master',
        androidInstallApp: true,
        dynamicLinkDomain: 'exammaster.page.link',
      );

      await widget.auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
        actionCodeSettings: actionCodeSettings,
      );

      setState(() {
        _statusMessage = 'لینک بازیابی رمز عبور به ایمیل شما ارسال شد.';
      });
    } on FirebaseAuthException catch (e) {
      String message = 'خطا در ارسال ایمیل بازیابی';
      if (e.code == 'user-not-found') {
        message = 'کاربری با این ایمیل یافت نشد';
      } else if (e.code == 'invalid-email') {
        message = 'ایمیل وارد شده نامعتبر است';
      }

      setState(() {
        _statusMessage = message;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'خطای غیرمنتظره: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('بازیابی رمز عبور'),
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
          // حل مشکل صفحه سفید
          extendBodyBehindAppBar: true,
          body: Container(
            width: double.infinity,
            height: double.infinity,
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: IntrinsicHeight(
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
                                    Icons.lock_reset,
                                    size: 64,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'بازیابی رمز عبور',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'ایمیل خود را وارد کنید تا لینک بازیابی برای شما ارسال شود',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              key: const ValueKey('emailField'),
                              controller: _emailController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'ایمیل',
                                hintText: 'example@example.com',
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  _emailError = 'ایمیل را وارد کنید';
                                  return 'ایمیل را وارد کنید';
                                }
                                // بررسی حروف فارسی
                                if (RegExp(r'[\u0600-\u06FF]')
                                    .hasMatch(value)) {
                                  _emailError =
                                      'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)';
                                  return 'ایمیل صحیح را وارد کنید (فقط حروف انگلیسی)';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                    .hasMatch(value.trim())) {
                                  _emailError = 'ایمیل نامعتبر است';
                                  return 'ایمیل نامعتبر است';
                                }
                                _emailError = null;
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            if (_isLoading)
                              const CircularProgressIndicator()
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  key: const ValueKey('resetButton'),
                                  onPressed: _resetPassword,
                                  icon: const Icon(Icons.lock_reset),
                                  label: const Text('ارسال ایمیل بازیابی'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            if (_statusMessage != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _statusMessage!.contains('خطا')
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _statusMessage!.contains('خطا')
                                        ? Colors.red.withOpacity(0.3)
                                        : Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _statusMessage!.contains('خطا')
                                          ? Icons.error_outline
                                          : Icons.check_circle_outline,
                                      color: _statusMessage!.contains('خطا')
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _statusMessage!,
                                        key: const ValueKey('statusMessage'),
                                        style: TextStyle(
                                          color: _statusMessage!.contains('خطا')
                                              ? Colors.red
                                              : Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.arrow_back,
                                color: isDarkMode
                                    ? Colors.amber[300]
                                    : Colors.amber[700],
                              ),
                              label: Text(
                                'بازگشت به صفحه ورود',
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
                      ),
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
