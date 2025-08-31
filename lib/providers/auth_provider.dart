import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  UserRole? _userRole;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get pendingClassId => _pendingClassId;
  bool get isGuest => _isGuest;
  UserRole? get userRole {
    if (_isGuest) return UserRole.guest;
    return _userRole ?? _currentUser?.role;
  }

  AuthProvider() {
    _authService.initialize();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges().listen((user) async {
      if (user != null) {
        _currentUser = await _authService.getCurrentUser();
        _userRole = _currentUser?.role;
        debugPrint('Auth state changed. User role: $_userRole');
      } else {
        _currentUser = null;
        _userRole = null;
        _isGuest = false;
      }
      notifyListeners();
    });
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.getCurrentUser();
      _userRole = _currentUser?.role;
      debugPrint('Initialized. User role: $_userRole');
    } catch (e) {
      debugPrint('Error initializing auth provider: $e');
      _userRole = UserRole.normaluser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool hasAccess(UserRole requiredRole) {
    if (_isGuest && requiredRole == UserRole.guest) return true;
    if (_currentUser == null) return false;
    return _userRole == requiredRole || _userRole == UserRole.admin;
  }

  Future<void> updateUserRole(UserRole newRole) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updateUserRole(_currentUser!.id, newRole);
      _userRole = newRole;
      _currentUser = _currentUser?.copyWith(role: newRole);
      debugPrint('User role updated to: $newRole');
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(UserModel updatedUser) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updateUser(updatedUser);
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

  Stream<List<UserModel>> getUsersStream() {
    return _authService.getUsersStream();
  }

  Future<List<UserModel>> getAllUsers() async {
    _isLoading = true;
    notifyListeners();
    try {
      final users = await _authService.getAllUsers();
      return users;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteUser(String userId) async {
    if (_currentUser?.id == userId) {
      throw Exception('نمی‌توانید حساب خود را حذف کنید');
    }
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.deleteUser(userId);
      debugPrint('User deleted successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) async {
    if (_currentUser == null && userId != _currentUser?.id) {
      throw Exception('کاربر لاگین نیست یا دسترسی ندارد');
    }
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.updateUserFields(userId, fields);
      // اگر کاربر فعلی هست، اطلاعات رو به‌روز کن
      if (_currentUser?.id == userId) {
        _currentUser = await _authService.getCurrentUser();
        _userRole = _currentUser?.role;
      }
      debugPrint('User fields updated successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user fields: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // متد جدید برای افزودن فیلد lastLogin به همه کاربران
  Future<void> addLastLoginFieldToAllUsers() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('lastLogin')) {
          await doc.reference.update({
            'lastLogin': null,
          });
        }
      }

      debugPrint('فیلد lastLogin برای همه کاربران اضافه شد');
    } catch (e) {
      debugPrint('خطا در اضافه کردن فیلد lastLogin: $e');
      rethrow;
    }
  }

  // متد به‌روزرسانی شده signIn
  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.signIn(email, password);
      _userRole = _currentUser?.role;

      // به‌روزرسانی فیلد lastLogin در Firestore
      if (_currentUser != null) {
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // به‌روزرسانی مدل کاربر محلی
        _currentUser = _currentUser!.copyWith(lastLogin: DateTime.now());
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

  // متد به‌روزرسانی شده register
  Future<void> register(
    String email,
    String password,
    String name, {
    UserRole? role,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.register(
        email,
        password,
        name,
        role: role ?? UserRole.normaluser,
        phone: phone,
      );

      // به‌روزرسانی فیلد lastLogin در Firestore
      if (_currentUser != null) {
        await _firestore.collection('users').doc(_currentUser!.id).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // به‌روزرسانی مدل کاربر محلی
        _currentUser = _currentUser!.copyWith(lastLogin: DateTime.now());
      }

      _userRole = _currentUser?.role;
      debugPrint('Registered. User role: $_userRole');
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('=== AUTH PROVIDER SIGN OUT STARTED ===');
      _isLoading = true;
      notifyListeners();

      // پاک کردن SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // خروج از Firebase
      await _authService.signOut();

      // ریست کردن متغیرهای حالت
      _currentUser = null;
      _userRole = null;
      _isGuest = false;
      _pendingClassId = null;

      debugPrint('=== AUTH PROVIDER SIGN OUT COMPLETED ===');
      notifyListeners();
    } catch (e) {
      debugPrint('=== AUTH PROVIDER SIGN OUT ERROR: $e ===');
      // ریست کردن متغیرهای حالت حتی در صورت خطا
      _currentUser = null;
      _userRole = null;
      _isGuest = false;
      _pendingClassId = null;
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setGuestMode({bool isGuest = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', isGuest);
    _isGuest = isGuest;
    if (isGuest) {
      _userRole = UserRole.guest;
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> setPendingClassId(String classId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pendingClassId', classId);
    _pendingClassId = classId;
    notifyListeners();
  }

  Future<void> verifyEmail() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.verifyEmail();
      debugPrint('Email verification sent');
    } catch (e) {
      debugPrint('Error sending email verification: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.resetPassword(email);
      debugPrint('Password reset email sent');
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
