import 'package:exam_master/screens/auth/email_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailLoginPage', () {
    testWidgets('نمایش فیلدهای ایمیل، رمز، کپچا', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));
      expect(find.byKey(const ValueKey('emailField')), findsOneWidget);
      expect(find.byKey(const ValueKey('passwordField')), findsOneWidget);
      expect(find.byKey(const ValueKey('captchaField')), findsOneWidget);
    });

    testWidgets('نمایش خطا در صورت خالی بودن ایمیل', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));
      await tester.tap(find.byKey(const ValueKey('loginButton')));
      await tester.pump();
      expect(find.text('ایمیل را وارد کنید'), findsOneWidget);
    });

    testWidgets('نمایش خطا در صورت رمز کوتاه', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: EmailLoginPage()));

      await tester.enterText(
          find.byKey(const ValueKey('emailField')), 'test@example.com');
      await tester.enterText(
          find.byKey(const ValueKey('passwordField')), '123');

      await tester.tap(find.byKey(const ValueKey('loginButton')));
      await tester.pump();

      expect(find.text('حداقل ۶ کاراکتر وارد کنید'), findsOneWidget);
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

      await tester.tap(find.byKey(const ValueKey('goToRegisterButton')));
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

      await tester.tap(find.byKey(const ValueKey('goToResetPasswordButton')));
      await tester.pumpAndSettle();

      expect(find.text('Reset Page'), findsOneWidget);
    });
  });
}
