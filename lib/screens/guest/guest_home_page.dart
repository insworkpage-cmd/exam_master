import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/theme_provider.dart';

class GuestHomePage extends StatefulWidget {
  const GuestHomePage({super.key});

  @override
  State<GuestHomePage> createState() => _GuestHomePageState();
}

class _GuestHomePageState extends State<GuestHomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // افزودن لاگ برای تشخیص مشکل
    debugPrint('=== GUEST HOME DEBUG ===');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      debugPrint('Is Guest: ${authProvider.isGuest}');
      debugPrint('User Role: ${authProvider.userRole}');
      debugPrint('Is Logged In: ${authProvider.isLoggedIn}');
      debugPrint('====================');
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

            return Scaffold(
              appBar: AppBar(
                title: const Text('داشبورد مهمان'),
                backgroundColor: Colors.amber[700],
                centerTitle: true,
                // اصلاح: جابجایی دکمه‌ها و افزودن tooltip
                automaticallyImplyLeading: false,
                actions: [
                  // دکمه حالت دارک مود در سمت چپ
                  IconButton(
                    icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
                    tooltip: isDarkMode ? 'حالت روشن' : 'حالت تاریک',
                    onPressed: () {
                      themeProvider.toggleTheme();
                    },
                  ),
                  // دکمه بازگشت در سمت راست
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'بازگشت',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                            const Color(0xFF1a1a2e),
                            const Color(0xFF16213e),
                            const Color(0xFF0f3460),
                          ]
                        : [
                            const Color(0xFF667eea),
                            const Color(0xFF764ba2),
                            const Color(0xFFf093fb),
                          ],
                  ),
                ),
                child: SafeArea(
                  child: Directionality(
                    // اصلاح: راست‌چین کردن متن‌های فارسی
                    textDirection: TextDirection.rtl,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildLogo(isDarkMode),
                            const SizedBox(height: 32),
                            _buildWelcomeText(isDarkMode),
                            const SizedBox(height: 24),
                            _buildGuestNoticeBox(isDarkMode),
                            const SizedBox(height: 24),
                            _buildActionButtons(
                                context, authProvider, isDarkMode),
                            const SizedBox(height: 24),
                            _buildFeaturesSection(isDarkMode),
                            const SizedBox(height: 32),
                            _buildFooter(isDarkMode),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogo(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school,
            size: 64,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          const SizedBox(height: 12),
          Text(
            'آزمون استخدامی',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            'Master',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText(bool isDarkMode) {
    return Column(
      children: [
        Text(
          'به پلتفرم آزمون استخدامی خوش آمدید!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'با استفاده از این پلتفرم می‌توانید:',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGuestNoticeBox(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info,
                color: Colors.amber[800],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'شما به عنوان مهمان وارد شده‌اید',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[900],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'برای دسترسی به تمام امکانات پلتفرم، لطفاً وارد حساب کاربری خود شوید یا ثبت‌نام کنید.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.amber[800],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    app_auth.AuthProvider authProvider,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        _buildActionButton(
          context,
          'ورود با ایمیل',
          Icons.email,
          () async {
            debugPrint('Navigating to login...');
            Navigator.pushNamed(context, '/login');
          },
          isDarkMode,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          'ثبت‌نام',
          Icons.person_add,
          () async {
            debugPrint('Navigating to register...');
            Navigator.pushNamed(context, '/register');
          },
          isDarkMode,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          context,
          'ادامه به عنوان مهمان',
          Icons.person_outline,
          () async {
            debugPrint('Setting guest mode...');
            await authProvider.setGuestMode();
            if (mounted) {
              debugPrint('Navigating to guest home...');
              Navigator.pushReplacementNamed(context, '/guest_home');
            }
          },
          isDarkMode,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
    bool isDarkMode, [
    Color? buttonColor,
  ]) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor ??
              (isDarkMode
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1)),
          foregroundColor: isDarkMode ? Colors.white : Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ویژگی‌های پلتفرم:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            'بانک سوالات جامع',
            Icons.quiz,
            'دسترسی به هزاران سوال آزمون استخدامی',
            isDarkMode,
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            'آزمون‌های شبیه‌سازی شده',
            Icons.timer,
            'تجربه آزمون واقعی با محدودیت زمانی',
            isDarkMode,
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            'تحلیل عملکرد',
            Icons.analytics,
            'گزارش تحلیلی از عملکرد شما',
            isDarkMode,
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            'دسترسی از هر دستگاهی',
            Icons.devices,
            'دسترسی از موبایل، تبلت و کامپیوتر',
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    String title,
    IconData icon,
    String description,
    bool isDarkMode,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDarkMode) {
    return Column(
      children: [
        Text(
          'نسخه ۱.۰.۰',
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.white38 : Colors.black26,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© ۲۰۲۴ آزمون استخدامی مستر. تمامی حقوق محفوظ است.',
          style: TextStyle(
            fontSize: 10,
            color: isDarkMode ? Colors.white38 : Colors.black26,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
