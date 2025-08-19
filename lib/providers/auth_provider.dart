import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _pendingClassId;
  bool _isGuest = false;
  // اضافه کردن فیلد نقش کاربر
  UserRole? _userRole;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get pendingClassId => _pendingClassId;
  bool get isGuest => _isGuest;

  // تغییر گتر برای دریافت نقش کاربر
  UserRole? get userRole {
    if (_isGuest) return UserRole.guest; // اگر مهمان بود
    return _userRole ??
        _currentUser?.role; // در غیر این صورت نقش کاربر رو برگردون
  }

  AuthProvider() {
    _authService.initialize();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges().listen((user) async {
      if (user != null) {
        _currentUser = await _authService.getCurrentUser();
        _userRole = _currentUser?.role; // ذخیره نقش کاربر
        debugPrint('Auth state changed. User role: $_userRole');
      } else {
        _currentUser = null;
        _userRole = null;
      }
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    _currentUser = await _authService.getCurrentUser();
    _userRole = _currentUser?.role; // ذخیره نقش کاربر
    debugPrint('Initialized. User role: $_userRole');
    _isLoading = false;
    notifyListeners();
  }

  // متد جدید برای به‌روزرسانی نقش کاربر
  Future<void> updateUserRole(UserRole newRole) async {
    if (_currentUser == null) return;
    try {
      // به‌روزرسانی نقش در Firestore
      await _authService.updateUserRole(_currentUser!.id, newRole);
      // به‌روزرسانی نقش در حالت محلی
      _userRole = newRole;
      _currentUser = _currentUser?.copyWith(role: newRole);
      debugPrint('User role updated to: $newRole');
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }

  // متد جدید برای به‌روزرسانی اطلاعات کاربر
  Future<void> updateUser(UserModel updatedUser) async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // به‌روزرسانی اطلاعات کاربر در سرویس احراز هویت
      await _authService.updateUser(updatedUser);

      // به‌روزرسانی اطلاعات کاربر در حالت محلی
      _currentUser = updatedUser;
      _userRole = updatedUser.role;

      debugPrint('User updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.signIn(email, password);
      _userRole = _currentUser?.role; // ذخیره نقش کاربر
      debugPrint('Signed in. User role: $_userRole'); // ← اصلاح شد
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password, String name,
      {UserRole? role}) async {
    _isLoading = true;
    notifyListeners();
    try {
      // ثبت‌نام با نقش پیش‌فرض normaluser
      _currentUser = await _authService.register(
        email,
        password,
        name,
        role: role ?? UserRole.normaluser, // ← نقش پیش‌فرض
      );
      _userRole = role ?? UserRole.normaluser; // ← تنظیم نقش محلی
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    _userRole = null;
    _isGuest = false;
    notifyListeners();
  }

  Future<void> setGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    _isGuest = true;
    _userRole = UserRole.guest; // ← تنظیم نقش مهمان
    notifyListeners();
  }

  Future<void> setPendingClassId(String classId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingClassId', classId);
    _pendingClassId = classId;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }
}
