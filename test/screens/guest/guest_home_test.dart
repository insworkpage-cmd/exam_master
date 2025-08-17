import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exam_master/screens/guest/guest_home_page.dart';

void main() {
  group('GuestHomePage', () {
    testWidgets('نمایش پیام خوش‌آمد و دکمه‌ها', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: GuestHomePage()));

      expect(find.text('شما به صورت مهمان وارد شده‌اید.'), findsOneWidget);
      expect(find.byKey(const ValueKey('guestQuizButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('guestRegisterButton')), findsOneWidget);
    });

    testWidgets('کلیک روی دکمه آزمون نمایشی باید مسیر `/quiz` برود',
        (WidgetTester tester) async {
      var pushedRoute = '';
      await tester.pumpWidget(MaterialApp(
        home: const GuestHomePage(),
        onGenerateRoute: (settings) {
          pushedRoute = settings.name ?? '';
          return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('آزمون')));
        },
      ));

      await tester.tap(find.byKey(const ValueKey('guestQuizButton')));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/quiz');
    });

    testWidgets('کلیک روی دکمه ثبت‌نام باید مسیر `/register` برود',
        (WidgetTester tester) async {
      var pushedRoute = '';
      await tester.pumpWidget(MaterialApp(
        home: const GuestHomePage(),
        onGenerateRoute: (settings) {
          pushedRoute = settings.name ?? '';
          return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('ثبت‌نام')));
        },
      ));

      await tester.tap(find.byKey(const ValueKey('guestRegisterButton')));
      await tester.pumpAndSettle();

      expect(pushedRoute, '/register');
    });
  });
}
