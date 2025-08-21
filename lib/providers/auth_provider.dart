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

  Future<void> updateUserRole(UserRole newRole) async {
    if (_currentUser == null) return;
    try {
      await _authService.updateUserRole(_currentUser!.id, newRole);
      _userRole = newRole;
      _currentUser = _currentUser?.copyWith(role: newRole);
      debugPrint('User role updated to: $newRole');
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
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

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.signIn(email, password);
      _userRole = _currentUser?.role;

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
      _currentUser = await _authService.register(
        email,
        password,
        name,
        role: role ?? UserRole.normaluser,
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      _currentUser = await _authService.getCurrentUser();
      _userRole = _currentUser?.role;

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

  Future<void> autoSignInAfterRegistration(
      String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          _currentUser = await _authService.signIn(email, password);
          _userRole = _currentUser?.role;
          if (_currentUser != null) {
            break;
          }
        } catch (e) {
          debugPrint('Attempt $i failed: $e');
          if (i == 4) rethrow;
        }
      }

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

  // متد اصلاح شده برای خروج از حساب کاربری
  Future<void> signOut() async {
    try {
      debugPrint('=== AUTH PROVIDER SIGN OUT STARTED ===');

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
      rethrow; // پرتاب خطا برای مدیریت در UI
    }
  }

  Future<void> setGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    _isGuest = true;
    _userRole = UserRole.guest;
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
