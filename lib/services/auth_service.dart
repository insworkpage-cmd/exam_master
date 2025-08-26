import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../utils/logger.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  // اضافه کردن Stream برای تغییرات احراز هویت
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  void initialize() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        _currentUser = await _getUserData(user.uid);
        Logger.info('Auth state changed. User role: ${_currentUser?.role}');
      } else {
        _currentUser = null;
      }
    });
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        Logger.info('No current user found');
        return null;
      }
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        Logger.info('User document not found, creating new one');
        return await _createUserDocument(user);
      }
      Logger.info('User document found');
      final userModel = UserModel.fromMap(doc.data()!);
      Logger.info('Current user role: ${userModel.role}');
      return userModel;
    } catch (e) {
      Logger.error('Error getting current user: $e');
      return null;
    }
  }

  Future<UserModel> _createUserDocument(User user,
      {UserRole? role, String? phone}) async {
    Logger.info('Creating new user document for: ${user.uid}');
    // تعیین نقش پیش‌فرض
    UserRole userRole = role ?? UserRole.normaluser;
    // بررسی ادمین خاص
    if (user.email == 'insworkpage@gmail.com') {
      userRole = UserRole.admin;
    }

    final userModel = UserModel(
      id: user.uid,
      uid: user.uid,
      role: userRole,
      email: user.email ?? '',
      name: user.displayName ?? '',
      phone: phone, // اضافه کردن فیلد phone
      createdAt: DateTime.now(),
    );

    final docRef = _firestore.collection('users').doc(user.uid);
    await docRef.set(userModel.toMap());
    Logger.info(
        'User document created successfully with role: ${userModel.role}');
    final updatedDoc = await docRef.get();
    return UserModel.fromMap(updatedDoc.data()!);
  }

  Future<UserModel?> signIn(String email, String password) async {
    try {
      _isLoading = true;
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = await _getUserData(userCredential.user!.uid);
      Logger.info('User signed in. Role: ${_currentUser?.role}');
      _isLoading = false;
      return _currentUser;
    } on FirebaseAuthException catch (e) {
      Logger.error('Sign in error: ${e.code}');
      _isLoading = false;
      rethrow;
    } catch (e) {
      Logger.error('Unexpected sign in error: $e');
      _isLoading = false;
      rethrow;
    }
  }

  Future<UserModel?> register(
    String email,
    String password,
    String name, {
    UserRole? role,
    String? phone, // اضافه کردن پارامتر phone
  }) async {
    try {
      _isLoading = true;
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      // ایجاد سند کاربر با نقش و شماره تلفن مشخص شده
      _currentUser = await _createUserDocument(
        userCredential.user!,
        role: role ?? UserRole.normaluser,
        phone: phone,
      );
      _isLoading = false;
      return _currentUser;
    } on FirebaseAuthException catch (e) {
      Logger.error('Register error: ${e.code}');
      _isLoading = false;
      rethrow;
    } catch (e) {
      Logger.error('Unexpected register error: $e');
      _isLoading = false;
      rethrow;
    }
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      Logger.info('Updating user role for: $uid to ${role.name}');
      await _firestore.collection('users').doc(uid).update({
        'role': role.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      // به‌روزرسانی کاربر فعلی اگر همان کاربر باشد
      if (_currentUser?.uid == uid) {
        _currentUser = _currentUser?.copyWith(role: role);
      }
      Logger.info('User role updated successfully');
    } catch (e) {
      Logger.error('Error updating user role: $e');
      rethrow;
    }
  }

  // متد جدید برای به‌روزرسانی اطلاعات کاربر
  Future<void> updateUser(UserModel user) async {
    try {
      Logger.info('Updating user data for: ${user.id}');
      // به‌روزرسانی اطلاعات کاربر در Firestore
      await _firestore.collection('users').doc(user.id).update(user.toMap());
      // به‌روزرسانی اطلاعات کاربر در Firebase Auth
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null && firebaseUser.uid == user.id) {
        await firebaseUser.updateDisplayName(user.name);
      }
      // به‌روزرسانی کاربر فعلی در حالت محلی
      if (_currentUser?.id == user.id) {
        _currentUser = user;
      }
      Logger.info('User data updated successfully');
    } catch (e) {
      Logger.error('Error updating user data: $e');
      rethrow;
    }
  }

  // متد جدید برای دریافت لیست همه کاربران به صورت Stream
  Stream<List<UserModel>> getUsersStream() {
    Logger.info('Getting users stream');
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // اضافه کردن ID به داده‌ها
        return UserModel.fromMap(data);
      }).toList();
    });
  }

  // متد جدید برای دریافت لیست کاربران به صورت Future
  Future<List<UserModel>> getAllUsers() async {
    try {
      Logger.info('Getting all users');
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // اضافه کردن ID به داده‌ها
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      Logger.error('Error getting all users: $e');
      rethrow;
    }
  }

  // متد جدید برای حذف کاربر
  Future<void> deleteUser(String uid) async {
    try {
      Logger.info('Deleting user: $uid');
      // حذف سند کاربر از Firestore
      await _firestore.collection('users').doc(uid).delete();
      // اگر کاربر فعلی حذف شده، متغیر محلی رو هم پاک کن
      if (_currentUser?.uid == uid) {
        _currentUser = null;
        // خروج از حساب کاربری اگر کاربر فعلی حذف شده
        await _auth.signOut();
      }
      Logger.info('User deleted successfully');
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase auth error deleting user: ${e.code}');
      // اگر کاربر در Firebase Auth وجود نداشت، فقط سند رو حذف می‌کنیم
      if (e.code == 'user-not-found') {
        await _firestore.collection('users').doc(uid).delete();
        if (_currentUser?.uid == uid) {
          _currentUser = null;
        }
        Logger.info('User document deleted (user not found in auth)');
      } else {
        rethrow;
      }
    } catch (e) {
      Logger.error('Error deleting user: $e');
      rethrow;
    }
  }

  // متد جدید برای به‌روزرسانی اطلاعات کاربر (بدون نیاز به مدل کامل)
  Future<void> updateUserFields(String uid, Map<String, dynamic> fields) async {
    try {
      Logger.info('Updating user fields for: $uid with fields: $fields');
      // به‌روزرسانی فیلدها در Firestore
      await _firestore.collection('users').doc(uid).update(fields);
      // اگر کاربر فعلی هست، اطلاعات محلی رو هم به‌روز کن
      if (_currentUser?.uid == uid) {
        _currentUser = await _getUserData(uid);
      }
      Logger.info('User fields updated successfully');
    } catch (e) {
      Logger.error('Error updating user fields: $e');
      rethrow;
    }
  }

  Future<bool> hasAccess(String uid, UserRole requiredRole) async {
    try {
      Logger.info(
          'Checking access for user: $uid with required role: ${requiredRole.name}');
      final user = await _getUserData(uid);
      if (user == null) {
        Logger.warning('No user found for access check');
        return false;
      }
      // مقایسه سطح دسترسی بر اساس سطح نقش
      final hasAccess = user.role.index >= requiredRole.index;
      Logger.info('Access ${hasAccess ? 'granted' : 'denied'} for user: $uid');
      return hasAccess;
    } catch (e) {
      Logger.error('Error checking access: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      Logger.info('User signing out');
      await _auth.signOut();
      _currentUser = null;
      Logger.info('User signed out successfully');
    } catch (e) {
      Logger.error('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Logger.info('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      Logger.error('Error sending password reset email: ${e.code}');
      rethrow;
    } catch (e) {
      Logger.error('Unexpected error sending password reset email: $e');
      rethrow;
    }
  }

  // اضافه کردن متد verifyEmail
  Future<void> verifyEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      Logger.info('Email verification sent');
    } catch (e) {
      Logger.error('Error sending email verification: $e');
      rethrow;
    }
  }

  // اضافه کردن متد resetPassword
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Logger.info('Password reset email sent to: $email');
    } catch (e) {
      Logger.error('Error sending password reset email: $e');
      rethrow;
    }
  }

  Future<UserModel?> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        Logger.warning('User document not found for uid: $uid');
        return null;
      }
      final data = doc.data()!;
      Logger.info('User data from Firestore: $data');
      final userModel = UserModel.fromMap(data);
      Logger.info('Parsed user role: ${userModel.role}');
      return userModel;
    } catch (e) {
      Logger.error('Error getting user data: $e');
      return null;
    }
  }
}
