import 'package:flutter/material.dart';

class NormalUserDashboard extends StatelessWidget {
  const NormalUserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل کاربری'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'خوش آمدید!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'شما به عنوان کاربر عادی وارد شده‌اید',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/join_class');
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                'جستجوی کلاس‌ها',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text(
                'پروفایل کاربری',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
