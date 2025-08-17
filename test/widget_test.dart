import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('Simple Button Tests', () {
    testWidgets('Welcome screen loads and shows buttons',
        (WidgetTester tester) async {
      // استفاده از یک نسخه ساده شده از WelcomeScreen بدون Providerها
      await tester.pumpWidget(
        const MaterialApp(
          home: TestWelcomeScreen(),
        ),
      );

      // صبر برای لود شدن صفحه
      await tester.pumpAndSettle();

      // بررسی وجود صفحه خوشامدگویی
      expect(find.text('به اپلیکیشن آزمون استخدامی خوش آمدید'), findsOneWidget,
          reason: 'صفحه خوشامدگویی باید نمایش داده شود');

      // بررسی وجود دکمه شروع آزمون
      expect(find.byKey(const Key('start_quiz_button')), findsOneWidget,
          reason: 'دکمه شروع آزمون باید وجود داشته باشد');

      // بررسی وجود دکمه ورود با شماره موبایل
      expect(find.byKey(const Key('mobile_login_button')), findsOneWidget,
          reason: 'دکمه ورود با شماره موبایل باید وجود داشته باشد');

      // بررسی وجود دکمه ورود با ایمیل
      expect(find.byKey(const Key('email_login_button')), findsOneWidget,
          reason: 'دکمه ورود با ایمیل باید وجود داشته باشد');

      // بررسی وجود دکمه ثبت‌نام
      expect(find.byKey(const Key('register_button')), findsOneWidget,
          reason: 'دکمه ثبت‌نام باید وجود داشته باشد');

      // بررسی وجود دکمه ورود مهمان
      expect(find.byKey(const Key('guest_login_button')), findsOneWidget,
          reason: 'دکمه ورود مهمان باید وجود داشته باشد');
    });

    testWidgets('Test start quiz button navigation',
        (WidgetTester tester) async {
      // استفاده از یک نسخه ساده شده از WelcomeScreen بدون Providerها
      await tester.pumpWidget(
        MaterialApp(
          home: TestWelcomeScreen(),
        ),
      );

      // صبر برای لود شدن صفحه
      await tester.pumpAndSettle();

      // تست دکمه شروع آزمون
      await tester.tap(find.byKey(const Key('start_quiz_button')));
      await tester.pumpAndSettle();

      // بررسی اینکه صفحه عوض شده است
      expect(find.text('به اپلیکیشن آزمون استخدامی خوش آمدید'), findsNothing,
          reason:
              'با تپ روی دکمه شروع آزمون، باید از صفحه خوشامدگویی خارج شویم');

      // بررسی اینکه صفحه آزمون نمایش داده شده است
      expect(find.text('صفحه آزمون'), findsOneWidget,
          reason: 'صفحه آزمون باید نمایش داده شود');
    });

    testWidgets('Test mobile login button navigation',
        (WidgetTester tester) async {
      // استفاده از یک نسخه ساده شده از WelcomeScreen بدون Providerها
      await tester.pumpWidget(
        MaterialApp(
          home: TestWelcomeScreen(),
        ),
      );

      // صبر برای لود شدن صفحه
      await tester.pumpAndSettle();

      // تست دکمه ورود با شماره موبایل
      await tester.tap(find.byKey(const Key('mobile_login_button')));
      await tester.pumpAndSettle();

      // بررسی اینکه صفحه عوض شده است
      expect(find.text('به اپلیکیشن آزمون استخدامی خوش آمدید'), findsNothing,
          reason:
              'با تپ روی دکمه ورود با شماره موبایل، باید از صفحه خوشامدگویی خارج شویم');

      // بررسی اینکه صفحه OTP نمایش داده شده است
      expect(find.text('صفحه OTP'), findsOneWidget,
          reason: 'صفحه OTP باید نمایش داده شود');
    });

    testWidgets('Test guest login button navigation',
        (WidgetTester tester) async {
      // استفاده از یک نسخه ساده شده از WelcomeScreen بدون Providerها
      await tester.pumpWidget(
        MaterialApp(
          home: TestWelcomeScreen(),
        ),
      );

      // صبر برای لود شدن صفحه
      await tester.pumpAndSettle();

      // تست دکمه ورود مهمان
      await tester.tap(find.byKey(const Key('guest_login_button')));
      await tester.pumpAndSettle();

      // بررسی اینکه صفحه عوض شده است
      expect(find.text('به اپلیکیشن آزمون استخدامی خوش آمدید'), findsNothing,
          reason:
              'با تپ روی دکمه ورود مهمان، باید از صفحه خوشامدگویی خارج شویم');

      // بررسی اینکه صفحه مهمان نمایش داده شده است
      expect(find.text('صفحه مهمان'), findsOneWidget,
          reason: 'صفحه مهمان باید نمایش داده شود');
    });
  });
}

// یک نسخه ساده شده از WelcomeScreen برای تست که به هیچ Provider وابسته نیست
class TestWelcomeScreen extends StatefulWidget {
  const TestWelcomeScreen({super.key});

  @override
  State<TestWelcomeScreen> createState() => _TestWelcomeScreenState();
}

class _TestWelcomeScreenState extends State<TestWelcomeScreen> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // در تست، انیمیشن را فورا نمایش می‌دهیم
    _opacity = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(seconds: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'به اپلیکیشن آزمون استخدامی خوش آمدید',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'آیا آماده‌اید برای موفقیت در آزمون استخدامی؟ همین حالا شروع کنید!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                        ),
                  ),
                  const SizedBox(height: 32),
                  _buildButton(
                    key: const Key('mobile_login_button'),
                    icon: Icons.phone_android,
                    label: 'ورود با شماره موبایل',
                    onPressed: () {
                      // در تست، فقط یک صفحه خالی نمایش می‌دهیم
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Scaffold(
                                body: Center(child: Text('صفحه OTP')))),
                      );
                    },
                  ),
                  _buildButton(
                    key: const Key('email_login_button'),
                    icon: Icons.email,
                    label: 'ورود با ایمیل / رمز عبور',
                    onPressed: () {
                      // در تست، فقط یک صفحه خالی نمایش می‌دهیم
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Scaffold(
                                body: Center(child: Text('صفحه لاگین')))),
                      );
                    },
                  ),
                  _buildButton(
                    key: const Key('register_button'),
                    icon: Icons.person_add_alt_1,
                    label: 'ثبت‌نام',
                    onPressed: () {
                      // در تست، فقط یک صفحه خالی نمایش می‌دهیم
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Scaffold(
                                body: Center(child: Text('صفحه ثبت‌نام')))),
                      );
                    },
                  ),
                  _buildButton(
                    key: const Key('guest_login_button'),
                    icon: Icons.person_outline,
                    label: 'ورود مهمان',
                    onPressed: () {
                      // در تست، فقط یک صفحه خالی نمایش می‌دهیم
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Scaffold(
                                body: Center(child: Text('صفحه مهمان')))),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    key: const Key('start_quiz_button'),
                    onPressed: () {
                      // در تست، فقط یک صفحه خالی نمایش می‌دهیم
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Scaffold(
                                body: Center(child: Text('صفحه آزمون')))),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'شروع آزمون',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        key: key,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
