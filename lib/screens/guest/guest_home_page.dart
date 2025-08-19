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
  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, child) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

            return Scaffold(
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
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLogo(isDarkMode),
                        const SizedBox(height: 48),
                        _buildWelcomeText(isDarkMode),
                        const SizedBox(height: 64),
                        _buildActionButtons(context, authProvider, isDarkMode),
                        const SizedBox(height: 32),
                        _buildFeaturesSection(isDarkMode),
                        const SizedBox(height: 48),
                        _buildFooter(isDarkMode),
                      ],
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
            size: 80,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          const SizedBox(height: 16),
          Text(
            'آزمون استخدامی',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            'Master',
            style: TextStyle(
              fontSize: 16,
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'با استفاده از این پلتفرم می‌توانید:',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
          () => Navigator.pushNamed(context, '/login'),
          isDarkMode,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          context,
          'ثبت‌نام',
          Icons.person_add,
          () => Navigator.pushNamed(context, '/register'),
          isDarkMode,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          context,
          'ورود مهمان',
          Icons.person_outline,
          () async {
            await authProvider.setGuestMode();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/guest_home');
            }
          },
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
    bool isDarkMode,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode
            ? Colors.white.withOpacity(0.2)
            : Colors.black.withOpacity(0.1),
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            'بانک سوالات جامع',
            Icons.quiz,
            'دسترسی به هزاران سوال آزمون استخدامی',
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            'آزمون‌های شبیه‌سازی شده',
            Icons.timer,
            'تجربه آزمون واقعی با محدودیت زمانی',
            isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildFeatureItem(
            'تحلیل عملکرد',
            Icons.analytics,
            'گزارش تحلیلی از عملکرد شما',
            isDarkMode,
          ),
          const SizedBox(height: 12),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
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
          'نسخه 1.0.0',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white54 : Colors.black38,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '© 2024 آزمون استخدامی مستر. تمامی حقوق محفوظ است.',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white54 : Colors.black38,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
