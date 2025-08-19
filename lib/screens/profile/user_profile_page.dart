import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/user_role.dart';
import '../../models/user_model.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isLoading = false;
  UserModel? _userModel;
  User? _firebaseUser;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // متد جدید برای ساخت آیکون نمایش/مخفی کردن رمز عبور
  Widget _buildPasswordIcon(bool isObscured, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
      onPressed: onPressed,
    );
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      _userModel = authProvider.currentUser;
      _firebaseUser = FirebaseAuth.instance.currentUser;
      if (_userModel != null) {
        _nameController.text = _userModel!.name;
        _phoneController.text = _userModel!.phone ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگیری اطلاعات: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_userModel == null) return;
    setState(() => _isLoading = true);
    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      // به‌روزرسانی نام در Firebase Auth
      await _firebaseUser?.updateDisplayName(_nameController.text.trim());
      // به‌روزرسانی اطلاعات در مدل محلی
      final updatedUser = _userModel!.copyWith(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      // به‌روزرسانی در authProvider با استفاده از متد جدید
      await authProvider.updateUser(updatedUser);
      setState(() {
        _userModel = updatedUser;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پروفایل با موفقیت به‌روزرسانی شد')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در به‌روزرسانی پروفایل: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool obscureCurrent = true;
          bool obscureNew = true;
          bool obscureConfirm = true;

          return AlertDialog(
            title: const Text('تغییر رمز عبور'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'رمز عبور فعلی',
                    border: const OutlineInputBorder(),
                    suffixIcon: _buildPasswordIcon(obscureCurrent, () {
                      setState(() => obscureCurrent = !obscureCurrent);
                    }),
                  ),
                  obscureText: obscureCurrent,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'رمز عبور جدید',
                    border: const OutlineInputBorder(),
                    suffixIcon: _buildPasswordIcon(obscureNew, () {
                      setState(() => obscureNew = !obscureNew);
                    }),
                  ),
                  obscureText: obscureNew,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'تکرار رمز عبور جدید',
                    border: const OutlineInputBorder(),
                    suffixIcon: _buildPasswordIcon(obscureConfirm, () {
                      setState(() => obscureConfirm = !obscureConfirm);
                    }),
                  ),
                  obscureText: obscureConfirm,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('لغو'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (newPasswordController.text ==
                          confirmPasswordController.text &&
                      newPasswordController.text.length >= 6) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('تغییر رمز'),
              ),
            ],
          );
        },
      ),
    );

    // Dispose controllers
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (result == true && mounted) {
      try {
        final user = _firebaseUser;
        if (user != null) {
          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPasswordController.text,
          );
          await user.reauthenticateWithCredential(credential);
          await user.updatePassword(newPasswordController.text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('رمز عبور با موفقیت تغییر کرد')),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'خطا در تغییر رمز عبور';
        if (e.code == 'wrong-password') {
          message = 'رمز عبور فعلی اشتباه است';
        } else if (e.code == 'weak-password') {
          message = 'رمز عبور جدید ضعیف است';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا: $e')),
          );
        }
      }
    }
  }

  Future<void> _shareProfile() async {
    if (_userModel == null) return;
    final text = '''
پروفایل کاربری من در اپلیکیشن آزمون استخدامی
نام: ${_userModel!.name}
ایمیل: ${_userModel!.email}
نقش: ${_userModel!.role.persianName}
تاریخ عضویت: ${_formatDate(_userModel!.createdAt)}
    ''';
    try {
      await Share.share(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در اشتراک‌گذاری: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _contactSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@exammaster.com',
      query:
          'subject=${Uri.encodeComponent('درخواست پشتیبانی از پروفایل کاربری')}',
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در باز کردن ایمیل: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروج از حساب'),
        content: const Text('آیا از خروج از حساب کاربری خود اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        final authProvider =
            Provider.of<app_auth.AuthProvider>(context, listen: false);
        await authProvider.signOut();
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در خروج: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('پروفایل کاربر'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareProfile,
              tooltip: 'اشتراک‌گذاری پروفایل',
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _contactSupport,
              tooltip: 'تماس با پشتیبانی',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _userModel == null
                ? const Center(child: Text('هیچ کاربری وارد نشده'))
                : RefreshIndicator(
                    onRefresh: _loadUserData,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // هدر پروفایل
                          _buildProfileHeader(),
                          const SizedBox(height: 24),
                          // بخش اطلاعات حساب
                          _buildAccountInfo(),
                          const SizedBox(height: 24),
                          // بخش ویرایش پروفایل
                          _buildProfileEdit(),
                          const SizedBox(height: 24),
                          // بخش تنظیمات امنیتی
                          _buildSecuritySettings(),
                          const SizedBox(height: 24),
                          // بخش اطلاعات سیستم
                          _buildSystemInfo(),
                          const SizedBox(height: 32),
                          // دکمه خروج
                          _buildSignOutButton(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            border: Border.all(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.person,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _userModel!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.verified_user,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _userModel!.role.persianName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfo() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات حساب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('📧', 'ایمیل', _userModel!.email),
            _buildInfoRow('🆔', 'شناسه کاربری', _userModel!.uid),
            _buildInfoRow(
                '📅', 'تاریخ عضویت', _formatDate(_userModel!.createdAt)),
            if (_userModel!.phone != null)
              _buildInfoRow('📱', 'شماره تلفن', _userModel!.phone!),
            _buildInfoRow(
                '⏱️', 'وضعیت حساب', _userModel!.isActive ? 'فعال' : 'غیرفعال'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileEdit() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ویرایش پروفایل',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'نام و نام خانوادگی',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'شماره تلفن (اختیاری)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateProfile,
                icon: const Icon(Icons.save),
                label: const Text('ذخیره تغییرات'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettings() {
    bool twoFactorEnabled = false;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تنظیمات امنیتی',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.blue),
              title: const Text('تغییر رمز عبور'),
              subtitle: const Text('رمز عبور خود را تغییر دهید'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _changePassword,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.security, color: Colors.orange),
              title: const Text('احراز دو مرحله‌ای'),
              subtitle: const Text('فعال‌سازی ورود دو مرحله‌ای'),
              trailing: Switch(
                value: twoFactorEnabled,
                onChanged: (value) {
                  setState(() {
                    twoFactorEnabled = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ویژگی احراز دو مرحله‌ای در حال توسعه است'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات سیستم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('📱', 'نسخه اپلیکیشن', '1.0.0'),
            _buildInfoRow('🔧', 'محیط اجرا', 'Flutter'),
            _buildInfoRow('🆔', 'شناسه منحصر به فرد', _userModel!.uid),
            _buildInfoRow(
                '⏰',
                'آخرین ورود',
                _formatDate(
                    _firebaseUser?.metadata.lastSignInTime ?? DateTime.now())),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout),
        label: const Text('خروج از حساب'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
