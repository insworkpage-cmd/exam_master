import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_master/screens/auth/email_login_page.dart';

void main() {
  group('EmailLoginPage', () {
    testWidgets('نمایش فیلدهای ایمیل، رمز و دکمه‌ها', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('نمایش خطا در صورت خالی بودن ایمیل', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('لطفاً ایمیل را وارد کنید'), findsOneWidget);
    });

    testWidgets('نمایش خطا در صورت رمز کوتاه', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));

      await tester.enterText(
          find.byType(TextFormField).first, 'test@example.com');
      await tester.enterText(find.byType(TextFormField).last, '123');

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('رمز عبور باید حداقل ۶ کاراکتر باشد'), findsOneWidget);
    });

    testWidgets('رفتن به صفحه ثبت‌نام با کلیک دکمه', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EmailLoginPage(),
          routes: {
            '/register': (context) =>
                const Scaffold(body: Text('Register Page')),
          },
        ),
      );

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(find.text('Register Page'), findsOneWidget);
    });

    testWidgets('رفتن به صفحه فراموشی رمز با کلیک دکمه', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EmailLoginPage(),
          routes: {
            '/reset-password': (context) =>
                const Scaffold(body: Text('Reset Page')),
          },
        ),
      );

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(find.text('Reset Page'), findsOneWidget);
    });
  });
}
