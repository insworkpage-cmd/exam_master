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

  void initialize() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        _currentUser = await _getUserData(user.uid);
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
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      Logger.error('Error getting current user: $e');
      return null;
    }
  }

  Future<UserModel> _createUserDocument(User user) async {
    Logger.info('Creating new user document for: ${user.uid}');
    final userModel = UserModel(
      id: '',
      uid: user.uid,
      role: UserRole.registeredUser,
      email: user.email ?? '',
      name: user.displayName ?? '',
      createdAt: DateTime.now(),
    );
    final docRef = _firestore.collection('users').doc(user.uid);
    await docRef.set(userModel.toMap());
    Logger.info('User document created successfully');
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
      String email, String password, String name) async {
    try {
      _isLoading = true;
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      _currentUser = await _createUserDocument(userCredential.user!);
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
      if (_currentUser?.uid == uid) {
        _currentUser = _currentUser?.copyWith(role: role);
      }
      Logger.info('User role updated successfully');
    } catch (e) {
      Logger.error('Error updating user role: $e');
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
      final hasAccess = user.role.level >= requiredRole.level;
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

  Future<UserModel?> _getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      Logger.error('Error getting user data: $e');
      return null;
    }
  }
}
