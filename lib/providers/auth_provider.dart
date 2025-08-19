import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

        // اگر نقش کاربر null بود، از Firestore بخون
        if (_userRole == null) {
          try {
            final userDoc = await _firestore
                .collection('users')
                .doc(_currentUser!.uid)
                .get();

            if (userDoc.exists) {
              final roleData = userDoc.data()?['role'];
              _userRole = UserRole.values.firstWhere(
                (role) => role.name == (roleData ?? 'normaluser'),
                orElse: () => UserRole.normaluser,
              );

              // به‌روزرسانی کاربر با نقش جدید
              _currentUser = _currentUser?.copyWith(role: _userRole);
            } else {
              _userRole = UserRole.normaluser;
              _currentUser = _currentUser?.copyWith(role: _userRole);
            }
          } catch (e) {
            debugPrint('Error reading user role from Firestore: $e');
            _userRole = UserRole.normaluser;
            _currentUser = _currentUser?.copyWith(role: _userRole);
          }
        }

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

    try {
      _currentUser = await _authService.getCurrentUser();
      _userRole = _currentUser?.role; // ذخیره نقش کاربر

      // اگر نقش کاربر null بود، از Firestore بخون
      if (_userRole == null && _currentUser != null) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(_currentUser!.uid).get();

          if (userDoc.exists) {
            final roleData = userDoc.data()?['role'];
            _userRole = UserRole.values.firstWhere(
              (role) => role.name == (roleData ?? 'normaluser'),
              orElse: () => UserRole.normaluser,
            );

            // به‌روزرسانی کاربر با نقش جدید
            _currentUser = _currentUser?.copyWith(role: _userRole);
          } else {
            _userRole = UserRole.normaluser;
            _currentUser = _currentUser?.copyWith(role: _userRole);
          }
        } catch (e) {
          debugPrint('Error reading user role from Firestore: $e');
          _userRole = UserRole.normaluser;
          _currentUser = _currentUser?.copyWith(role: _userRole);
        }
      }

      debugPrint('Initialized. User role: $_userRole');
    } catch (e) {
      debugPrint('Error initializing auth provider: $e');
      _userRole = UserRole.normaluser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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

      // اگر نقش کاربر null بود، از Firestore بخون
      if (_userRole == null) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(_currentUser!.uid).get();

          if (userDoc.exists) {
            final roleData = userDoc.data()?['role'];
            _userRole = UserRole.values.firstWhere(
              (role) => role.name == (roleData ?? 'normaluser'),
              orElse: () => UserRole.normaluser,
            );

            // به‌روزرسانی کاربر با نقش جدید
            _currentUser = _currentUser?.copyWith(role: _userRole);
          } else {
            _userRole = UserRole.normaluser;
            _currentUser = _currentUser?.copyWith(role: _userRole);
          }
        } catch (e) {
          debugPrint('Error reading user role from Firestore: $e');
          _userRole = UserRole.normaluser;
          _currentUser = _currentUser?.copyWith(role: _userRole);
        }
      }

      debugPrint('Signed in. User role: $_userRole');
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

      // صبر کن تا اطلاعات کاربر در Firestore ذخیره بشه
      await Future.delayed(const Duration(milliseconds: 1500));

      // اطلاعات کاربر را دوباره از Firestore بخون
      _currentUser = await _authService.getCurrentUser();
      _userRole = _currentUser?.role;

      // اگر هنوز نقش null بود، به صورت دستی تنظیم کن
      if (_userRole == null) {
        _userRole = role ?? UserRole.normaluser;
        _currentUser = _currentUser?.copyWith(role: _userRole);
      }

      debugPrint('Registered. User role: $_userRole');
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // متد جدید برای ورود خودکار پس از ثبت‌نام
  Future<void> autoSignInAfterRegistration(
      String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // چند بار تلاش کن تا اطلاعات کاربر در Firestore ذخیره بشه
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          _currentUser = await _authService.signIn(email, password);
          _userRole = _currentUser?.role;

          // اگر ورود موفقیت‌آمیز بود، از حلقه خارج شو
          if (_currentUser != null) {
            break;
          }
        } catch (e) {
          debugPrint('Attempt $i failed: $e');
          // اگر آخرین تلاش بود، خطا را پرتاب کن
          if (i == 4) rethrow;
        }
      }

      // اگر نقش کاربر null بود، از Firestore بخون
      if (_userRole == null) {
        try {
          final userDoc =
              await _firestore.collection('users').doc(_currentUser!.uid).get();

          if (userDoc.exists) {
            final roleData = userDoc.data()?['role'];
            _userRole = UserRole.values.firstWhere(
              (role) => role.name == (roleData ?? 'normaluser'),
              orElse: () => UserRole.normaluser,
            );

            // به‌روزرسانی کاربر با نقش جدید
            _currentUser = _currentUser?.copyWith(role: _userRole);
          } else {
            _userRole = UserRole.normaluser;
            _currentUser = _currentUser?.copyWith(role: _userRole);
          }
        } catch (e) {
          debugPrint('Error reading user role from Firestore: $e');
          _userRole = UserRole.normaluser;
          _currentUser = _currentUser?.copyWith(role: _userRole);
        }
      }

      debugPrint('Auto sign-in successful. User role: $_userRole');
    } catch (e) {
      debugPrint('Auto sign-in error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _userRole = null;
      _isGuest = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
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
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }
}
