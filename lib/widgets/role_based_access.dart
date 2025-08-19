import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart' as app_auth; // ← اصلاح import

class RoleBasedAccess extends StatelessWidget {
  final UserRole requiredRole;
  final Widget child;
  final Widget? fallback;
  final bool showLoading; // ← اضافه شد
  final String? customMessage; // ← اضافه شد

  const RoleBasedAccess({
    required this.requiredRole,
    required this.child,
    this.fallback,
    this.showLoading = true, // ← مقدار پیش‌فرض
    this.customMessage, // ← اضافه شد
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      // ← اصلاح Consumer
      builder: (context, authProvider, child) {
        // 1. بررسی وضعیت بارگذاری
        if (authProvider.isLoading && showLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. بررسی اینکه کاربر وارد شده یا نه
        if (authProvider.currentUser == null) {
          return fallback ??
              _buildAccessDenied(
                context: context,
                message: customMessage ?? 'لطفاً ابتدا وارد سیستم شوید',
                showBackButton: false,
              );
        }

        // 3. بررسی نقش کاربر
        final userRole = authProvider.userRole;
        if (userRole == null) {
          return fallback ??
              _buildAccessDenied(
                context: context,
                message: customMessage ?? 'نقش کاربر مشخص نیست',
              );
        }

        // 4. بررسی سطح دسترسی
        if (userRole.level < requiredRole.level) {
          return fallback ??
              _buildAccessDenied(
                context: context,
                message: customMessage ??
                    _getAccessDeniedMessage(userRole, requiredRole),
              );
        }

        // 5. اگر همه چیز OK بود، فرزند رو نمایش بده
        return child!;
      },
      child: child,
    );
  }

  Widget _buildAccessDenied({
    required BuildContext context,
    required String message,
    bool showBackButton = true,
  }) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),
              Text(
                'دسترسی محدود',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (showBackButton) ...[
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('بازگشت'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('ورود به سیستم'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAccessDeniedMessage(UserRole userRole, UserRole requiredRole) {
    final roleNames = {
      UserRole.guest: 'مهمان',
      UserRole.normaluser: 'کاربر عادی',
      UserRole.student: 'دانشجو',
      UserRole.instructor: 'استاد',
      UserRole.moderator: 'ناظر',
      UserRole.admin: 'مدیر',
    };

    return 'شما به عنوان ${roleNames[userRole]} دسترسی به این بخش را ندارید.\n'
        'این بخش فقط برای کاربران با نقش ${roleNames[requiredRole]} در دسترس است.';
  }
}

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'دسترسی محدود',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'شما اجازه دسترسی به این بخش را ندارید',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('بازگشت'),
            ),
          ],
        ),
      ),
    );
  }
}
