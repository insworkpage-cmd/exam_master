import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

class OtpTestPage extends StatefulWidget {
  const OtpTestPage({super.key});

  @override
  State<OtpTestPage> createState() => _OtpTestPageState();
}

class _OtpTestPageState extends State<OtpTestPage> {
  String phoneNumber = '';
  bool codeSent = false;
  bool isLoading = false;
  int secondsRemaining = 0;
  Timer? _timer;

  void sendOtp() {
    setState(() {
      codeSent = true;
      isLoading = true;
      secondsRemaining = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        timer.cancel();
        setState(() => isLoading = false);
      } else {
        setState(() => secondsRemaining--);
      }
    });
  }

  void verifyCode(String code) {
    // در اینجا باید به Firebase Auth وصل بشه
    debugPrint('کد وارد شده: $code');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ورود با شماره موبایل'),
          backgroundColor: Colors.indigo,
        ),
        body: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!codeSent) ...[
                const Text('شماره موبایل خود را وارد کنید:'),
                const SizedBox(height: 8),
                IntlPhoneField(
                  initialCountryCode: 'IR',
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (phone) {
                    phoneNumber = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: phoneNumber.isEmpty ? null : sendOtp,
                  child: const Text('ارسال کد'),
                ),
              ] else ...[
                const Text('کد تایید را وارد کنید:'),
                const SizedBox(height: 8),
                OtpTextField(
                  numberOfFields: 6,
                  borderColor: Colors.indigo,
                  focusedBorderColor: Colors.deepOrange,
                  showFieldAsBox: true,
                  fieldWidth: 40,
                  onSubmit: verifyCode,
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  Text('ارسال مجدد تا $secondsRemaining ثانیه دیگر')
                else
                  TextButton(
                    onPressed: sendOtp,
                    child: const Text('ارسال مجدد کد'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
