import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await widget.auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      setState(() {
        _statusMessage = 'لینک بازیابی رمز عبور ارسال شد.';
      });
    } on FirebaseAuthException catch (e) {
      String message = 'خطا در ارسال ایمیل بازیابی.';
      if (e.code == 'user-not-found') {
        message = 'کاربری با این ایمیل یافت نشد.';
      } else if (e.code == 'invalid-email') {
        message = 'ایمیل وارد شده نامعتبر است.';
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('بازیابی رمز عبور')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  key: const ValueKey('emailField'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'ایمیل',
                    hintText: 'example@example.com',
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'ایمیل را وارد کنید'
                      : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        key: const ValueKey('resetButton'),
                        onPressed: _resetPassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('ارسال ایمیل بازیابی'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                const SizedBox(height: 24),
                if (_statusMessage != null)
                  Text(
                    _statusMessage!,
                    key: const ValueKey('statusMessage'),
                    style: TextStyle(
                      color: _statusMessage!.contains('خطا')
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
