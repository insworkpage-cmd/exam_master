import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/quiz/quiz_page.dart';
import 'screens/otp/otp_test_page.dart';
import 'screens/profile/user_profile_page.dart';
import 'screens/auth/email_login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/auth/reset_password_page.dart';
import 'screens/guest/guest_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/instructor/class_list_page.dart';
import 'providers/auth_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/class_provider.dart';
import 'screens/test/question_management_test_page.dart';
import 'screens/instructor/question_management_page.dart';
import 'screens/moderator/question_approval_page.dart';
import 'screens/admin/admin_panel_page.dart';
import 'screens/admin/user_management_page.dart';
import 'screens/admin/class_management_page.dart';
import 'screens/admin/reports_page.dart';
import 'screens/admin/system_monitor_page.dart';
import 'screens/admin/settings_page.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'models/user_role.dart';
import 'widgets/role_based_access.dart';
import 'models/user_model.dart';
import 'screens/normal_user_dashboard.dart'; // ← اضافه شد

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.student,
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 80, color: Colors.green),
              SizedBox(height: 16),
              Text(
                'پنل دانشجو',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('دسترسی دانشجو'),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.admin,
      child: const Scaffold(
        // ← const حذف شد
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'پنل مدیریت کل سیستم',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('دسترسی ادمین'),
            ],
          ),
        ),
      ),
    );
  }
}

class ModeratorDashboard extends StatelessWidget {
  const ModeratorDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.moderator,
      child: const Scaffold(
        // ← const حذف شد
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.content_paste, size: 80, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'پنل ناظر',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('دسترسی ناظر'),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase با موفقیت مقداردهی اولیه شد!');
    debugPrint('📦 Project ID: ${Firebase.app().options.projectId}');
  } catch (e) {
    debugPrint('❌ خطا در اتصال به Firebase: $e');
  }
  final prefs = await SharedPreferences.getInstance();
  final isGuest = prefs.getBool('isGuest') ?? false;
  if (isGuest) {
    await prefs.remove('isGuest');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ExamMasterApp(),
    ),
  );
}

class ExamMasterApp extends StatelessWidget {
  const ExamMasterApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'آزمون استخدامی',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(child: Text('صفحه یافت نشد')),
              ),
            );
          },
          home: const WelcomeScreen(),
          routes: {
            // مسیرهای عمومی و کاربران
            '/test-questions': (_) => const QuestionManagementTestPage(),
            '/profile': (_) => const UserProfilePage(),
            '/login': (_) => const EmailLoginPage(),
            '/register': (_) => const RegisterPage(),
            '/reset-password': (_) => ResetPasswordPage(),
            '/guest_home': (_) =>
                const GuestHomePage(), // ← اصلاح: guest-home → guest_home
            '/quiz': (_) => const QuizPage(),
            // مسیرهای دانشجو و مدرس
            '/student_dashboard': (_) =>
                const StudentDashboard(), // ← اصلاح: student-dashboard → student_dashboard
            '/instructor_dashboard': (_) =>
                const InstructorClassListPage(), // ← اصلاح: instructor-classes → instructor_dashboard
            // مسیرهای مدیریت سوالات
            '/instructor_question_management': (_) =>
                const QuestionManagementPage(), // ← اصلاح: instructor-question-management
            '/moderator_question_approval': (_) =>
                const QuestionApprovalPage(), // ← اصلاح: moderator-question-approval
            // مسیرهای مدیریتی
            '/admin_dashboard': (_) =>
                const AdminDashboard(), // ← اصلاح: admin-dashboard → admin_dashboard
            '/moderator_dashboard': (_) =>
                const ModeratorDashboard(), // ← اصلاح: moderator-dashboard → moderator_dashboard
            '/admin_panel': (_) => const AdminPanelPage(),
            '/user_management': (_) => const UserManagementPage(),
            '/class_management': (_) => const ClassManagementPage(),
            '/reports': (_) => const ReportsPage(),
            '/system_monitor': (_) => const SystemMonitorPage(),
            '/settings': (_) => const SettingsPage(),
            // مسیرهای جدید
            '/normaluser_dashboard': (_) =>
                const NormalUserDashboard(), // ← اضافه شد
          },
        );
      },
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  double _opacity = 0.0;
  @override
  void initState() {
    super.initState();
    bool isTesting = false;
    assert(() {
      isTesting = true;
      return true;
    }());
    if (isTesting) {
      _opacity = 1.0;
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _opacity = 1.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (authProvider.isLoggedIn) {
          return _DashboardRouter(user: authProvider.currentUser!);
        }
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedOpacity(
                  opacity: _opacity,
                  duration: const Duration(seconds: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.school,
                        size: 80,
                        color: AppTheme.primaryColor,
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OtpTestPage()),
                        ),
                      ),
                      _buildButton(
                        key: const Key('email_login_button'),
                        icon: Icons.email,
                        label: 'ورود با ایمیل / رمز عبور',
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                      ),
                      _buildButton(
                        key: const Key('register_button'),
                        icon: Icons.person_add_alt_1,
                        label: 'ثبت‌نام',
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                      ),
                      _buildButton(
                        key: const Key('guest_login_button'),
                        icon: Icons.person_outline,
                        label: 'ورود مهمان',
                        onPressed: () async {
                          await authProvider.setGuestMode();
                          if (!context.mounted) return;
                          Navigator.pushNamed(context, '/guest_home');
                        },
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        key: const Key('start_quiz_button'),
                        onPressed: () => Navigator.pushNamed(context, '/quiz'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
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
      },
    );
  }

  Widget _buildButton({
    Key? key,
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
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _DashboardRouter extends StatelessWidget {
  final UserModel user;
  const _DashboardRouter({required this.user});
  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.moderator: // ← اصلاح: contentModerator → moderator
        return const ModeratorDashboard();
      case UserRole.instructor:
        return const InstructorClassListPage();
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.normaluser: // ← اضافه شد
        return const NormalUserDashboard();
      default:
        return const Scaffold(
          body: Center(child: Text('داشبورد کاربر')),
        );
    }
  }
}
