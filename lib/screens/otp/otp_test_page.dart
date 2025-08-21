import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/theme_provider.dart';
import '../../models/user_role.dart';

class OtpTestPage extends StatefulWidget {
  const OtpTestPage({super.key});

  @override
  State<OtpTestPage> createState() => _OtpTestPageState();
}

class _OtpTestPageState extends State<OtpTestPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String phoneNumber = '';
  String verificationId = '';
  bool codeSent = false;
  bool isLoading = false;
  bool isVerifying = false;
  int secondsRemaining = 0;
  Timer? _timer;
  String? _phoneError;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.removeListener(_validatePhone);
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final phone = _phoneController.text;
    setState(() {
      if (phone.isEmpty) {
        _phoneError = 'شماره موبایل را وارد کنید';
      } else if (!phone.startsWith('9')) {
        _phoneError = 'شماره موبایل باید با 9 شروع شود';
      } else if (!RegExp(r'^[0-9]{10}$')
          .hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''))) {
        _phoneError = 'شماره موبایل باید 10 رقم باشد';
      } else {
        _phoneError = null;
      }
    });
  }

  Future<void> sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
      _phoneError = null;
    });
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // این بخش زمانی اجرا می‌شود که OTP به صورت خودکار تایید شود
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() {
              isLoading = false;
              if (e.code == 'invalid-phone-number') {
                _phoneError = 'شماره موبایل نامعتبر است';
              } else {
                _phoneError = 'خطا در ارسال کد: ${e.message}';
              }
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              codeSent = true;
              isLoading = false;
              secondsRemaining = 60;
              this.verificationId = verificationId;
            });
            _startTimer();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              isLoading = false;
              codeSent = false;
            });
          }
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          _phoneError = 'خطا در ارسال کد: ${e.toString()}';
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        timer.cancel();
        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted) {
          setState(() => secondsRemaining--);
        }
      }
    });
  }

  Future<void> verifyCode(String code) async {
    if (code.isEmpty) {
      if (mounted) {
        setState(() {
          _otpError = 'کد تایید را وارد کنید';
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        isVerifying = true;
        _otpError = null;
      });
    }
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          isVerifying = false;
          if (e.code == 'invalid-verification-code') {
            _otpError = 'کد تایید نامعتبر است';
          } else {
            _otpError = 'خطا در تایید کد: ${e.message}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isVerifying = false;
          _otpError = 'خطا در تایید کد: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      if (mounted) {
        setState(() {
          isVerifying = true;
        });
      }
      // دریافت AuthProvider قبل از عملیات async
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null) {
        // بررسی اینکه آیا کاربر قبلاً ثبت‌نام کرده است
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          // اگر کاربر جدید است، اطلاعات اولیه را ذخیره کن
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'phone': phoneNumber,
            'name': 'کاربر مهمان',
            'role': UserRole.normaluser.name,
            'createdAt': DateTime.now().toIso8601String(),
            'isActive': true,
          });
        }
        // به‌روزرسانی AuthProvider
        await authProvider.initialize();
        // بررسی مجدد mounted قبل از استفاده از context
        if (mounted) {
          // هدایت به صفحه مناسب بر اساس نقش کاربر
          _navigateToDashboard(authProvider.userRole);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          isVerifying = false;
          _otpError = 'خطا در ورود: ${e.message}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isVerifying = false;
          _otpError = 'خطای غیرمنتظره: ${e.toString()}';
        });
      }
    }
  }

  void _navigateToDashboard(UserRole? role) {
    if (!mounted) return;
    String route;
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
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
        // تعریف رنگ خطا متناسب با حالت روز و شب
        final errorColor = isDarkMode ? Colors.red[300]! : Colors.red[800]!;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('ورود با شماره موبایل'),
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
                                Icons.phone_android,
                                size: 64,
                                color:
                                    isDarkMode ? Colors.white : Colors.black87,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'ورود با شماره موبایل',
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
                                'کد تایید به شماره شما ارسال خواهد شد',
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
                        if (!codeSent) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.black.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: IntlPhoneField(
                                    controller: _phoneController,
                                    initialCountryCode: 'IR',
                                    decoration: InputDecoration(
                                      labelText: 'شماره موبایل',
                                      hintText: '9123456789',
                                      border: InputBorder.none,
                                      prefixIcon: const Icon(Icons.phone),
                                      filled: true,
                                      fillColor: Colors.transparent,
                                      errorStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: errorColor,
                                      ),
                                      errorText: _phoneError,
                                      alignLabelWithHint: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 16, horizontal: 12),
                                      hintStyle: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                      labelStyle: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                    onChanged: (phone) {
                                      phoneNumber = phone.completeNumber;
                                    },
                                    validator: (phone) {
                                      if (phone == null ||
                                          phone.number.isEmpty) {
                                        return 'شماره موبایل را وارد کنید';
                                      } else if (!phone.number
                                          .startsWith('9')) {
                                        return 'شماره موبایل باید با 9 شروع شود';
                                      } else if (!RegExp(r'^[0-9]{10}$')
                                          .hasMatch(phone.number)) {
                                        return 'شماره موبایل باید 10 رقم باشد';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Text(
                                    'شماره موبایل خود را بدون صفر وارد کنید',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'فقط شماره موبایل‌های ایرانی (شروع با ۹) مجاز هستند',
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (isLoading)
                            const CircularProgressIndicator()
                          else
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _phoneError == null ? sendOtp : null,
                                icon: const Icon(Icons.send),
                                label: const Text('ارسال کد تایید'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                        ] else ...[
                          const Text(
                            'کد تایید را وارد کنید:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OtpTextField(
                            numberOfFields: 6,
                            borderColor: Colors.indigo,
                            focusedBorderColor: Colors.deepOrange,
                            showFieldAsBox: true,
                            fieldWidth: 40,
                            borderRadius: BorderRadius.circular(8),
                            fillColor: isDarkMode
                                ? Colors.white.withOpacity(0.1)
                                : Colors.white.withOpacity(0.7),
                            textStyle: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            onSubmit: verifyCode,
                          ),
                          if (_otpError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _otpError!,
                              style: TextStyle(
                                color: errorColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (isVerifying)
                            const CircularProgressIndicator()
                          else if (isLoading)
                            Text(
                              'ارسال مجدد تا $secondsRemaining ثانیه دیگر',
                              textAlign: TextAlign.center,
                            )
                          else
                            TextButton(
                              onPressed: sendOtp,
                              child: const Text('ارسال مجدد کد'),
                            ),
                        ],
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
        );
      },
    );
  }
}
