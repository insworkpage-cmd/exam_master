import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:exam_master/screens/auth/reset_password_page.dart';

void main() {
  group('ResetPasswordPage Tests (Mock)', () {
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: ResetPasswordPage(auth: mockAuth),
      );
    }

    testWidgets('نمایش فیلد ایمیل و دکمه بازیابی', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byKey(const ValueKey('emailField')), findsOneWidget);
      expect(find.byKey(const ValueKey('resetButton')), findsOneWidget);
    });

    testWidgets('نمایش پیام خطا اگر ایمیل خالی باشد', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byKey(const ValueKey('resetButton')));
      await tester.pump();

      expect(find.text('ایمیل را وارد کنید'), findsOneWidget);
    });

    testWidgets('نمایش پیام موفقیت پس از ارسال ایمیل بازیابی', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(
          find.byKey(const ValueKey('emailField')), 'test@example.com');

      await tester.tap(find.byKey(const ValueKey('resetButton')));
      await tester.pump(const Duration(milliseconds: 500)); // صبر برای setState

      expect(find.text('لینک بازیابی رمز عبور ارسال شد.'), findsOneWidget);
    });
  });
}
