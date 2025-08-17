import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  @override
  void initState() {
    super.initState();
    markAsGuest(); // ذخیره وضعیت مهمان
  }

  Future<void> markAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خوش آمدید - مهمان'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'شما به صورت مهمان وارد شده‌اید.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                key: const ValueKey('guestQuizButton'),
                onPressed: () {
                  Navigator.pushNamed(context, '/quiz');
                },
                icon: const Icon(Icons.quiz),
                label: const Text('آزمون نمایشی'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const ValueKey('guestRegisterButton'),
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('ثبت‌نام برای دسترسی کامل'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
