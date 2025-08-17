import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_master/screens/auth/register_page.dart';

void main() {
  group('RegisterPage Tests', () {
    testWidgets('نمایش تمام فیلدها و دکمه ثبت‌نام',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      expect(find.byKey(const ValueKey('emailField')), findsOneWidget);
      expect(find.byKey(const ValueKey('passwordField')), findsOneWidget);
      expect(find.byKey(const ValueKey('confirmField')), findsOneWidget);
      expect(find.byKey(const ValueKey('captchaField')), findsOneWidget);
      expect(find.byKey(const ValueKey('registerButton')), findsOneWidget);
    });

    testWidgets('نمایش خطا در صورت وارد نکردن رمز و کپچا',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // وارد کردن ایمیل معتبر برای فعال شدن دکمه
      await tester.enterText(
          find.byKey(const ValueKey('emailField')), 'test@example.com');
      await tester.pump(); // اجرای live email validation

      // دکمه ثبت‌نام رو بزن
      await tester.tap(find.byKey(const ValueKey('registerButton')));
      await tester.pumpAndSettle();

      // بررسی ارورها
      expect(find.text('رمز باید حداقل ۶ کاراکتر باشد'), findsOneWidget);
      expect(find.text('پاسخ کپچا را وارد کنید'), findsOneWidget);
    });

    testWidgets('نمایش پیام خطا هنگام کپچای اشتباه',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      await tester.enterText(
          find.byKey(const ValueKey('emailField')), 'test@example.com');
      await tester.pump();

      await tester.enterText(
          find.byKey(const ValueKey('passwordField')), '123456');
      await tester.enterText(
          find.byKey(const ValueKey('confirmField')), '123456');
      await tester.enterText(
          find.byKey(const ValueKey('captchaField')), '999'); // اشتباه

      await tester.tap(find.byKey(const ValueKey('registerButton')));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('پاسخ کپچا اشتباه است'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('غیرفعال بودن دکمه ثبت‌نام قبل از ورود ایمیل معتبر',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      await tester.enterText(
          find.byKey(const ValueKey('emailField')), 'invalid-email');
      await tester.pump();

      final ElevatedButton button =
          tester.widget(find.byKey(const ValueKey('registerButton')));
      expect(button.onPressed, isNull); // غیرفعال
    });
  });
}
