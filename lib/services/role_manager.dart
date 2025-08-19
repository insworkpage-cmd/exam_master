import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_role.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class RoleManager {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ذخیره نقش کاربر
  static Future<void> saveUserRole(String uid, UserRole role) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role': role.name,
        'roleUpdatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Logger.error('Error saving user role: $e');
      rethrow;
    }
  }

  // دریافت نقش کاربر
  static Future<UserRole> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return UserRole.normaluser; // ← تغییر: کاربر جدید normaluser است
      }
      final roleString = doc.data()?['role'] ?? 'normaluser'; // ← تغییر پیش‌فرض
      return UserRole.values.firstWhere(
        (role) => role.name == roleString,
        orElse: () => UserRole.normaluser, // ← تغییر پیش‌فرض
      );
    } catch (e) {
      Logger.error('Error getting user role: $e');
      return UserRole.normaluser; // ← تغییر پیش‌فرض
    }
  }

  // ترفیع مقام کاربر
  static Future<void> promoteUser(String uid) async {
    try {
      final currentRole = await getUserRole(uid);
      UserRole newRole;

      switch (currentRole) {
        case UserRole.guest:
          newRole = UserRole.normaluser; // ← تغییر: registeredUser → normaluser
          break;
        case UserRole.normaluser:
          newRole = UserRole.student;
          break;
        case UserRole.student:
          newRole = UserRole.instructor;
          break;
        case UserRole.instructor:
          newRole = UserRole.moderator; // ← تغییر: contentModerator → moderator
          break;
        case UserRole.moderator:
          newRole = UserRole.admin;
          break;
        case UserRole.admin:
          throw Exception(
              'User already has the highest role'); // ← حذف superAdmin
      }

      await saveUserRole(uid, newRole);
    } catch (e) {
      Logger.error('Error promoting user: $e');
      rethrow;
    }
  }

  // تنزل مقام کاربر
  static Future<void> demoteUser(String uid) async {
    try {
      final currentRole = await getUserRole(uid);
      UserRole newRole;

      switch (currentRole) {
        case UserRole.admin:
          newRole = UserRole.moderator; // ← تغییر: contentModerator → moderator
          break;
        case UserRole.moderator:
          newRole = UserRole.instructor;
          break;
        case UserRole.instructor:
          newRole = UserRole.student;
          break;
        case UserRole.student:
          newRole = UserRole.normaluser; // ← تغییر: registeredUser → normaluser
          break;
        case UserRole.normaluser:
          newRole = UserRole.guest;
          break;
        case UserRole.guest:
          throw Exception('User already has the lowest role');
      }

      await saveUserRole(uid, newRole);
    } catch (e) {
      Logger.error('Error demoting user: $e');
      rethrow;
    }
  }

  // دریافت لیست کاربران بر اساس نقش
  static Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.name)
          .get();
      return query.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting users by role: $e');
      return [];
    }
  }

  // بررسی وجود کاربر با نقش خاص
  static Future<bool> userExistsWithRole(String uid, UserRole role) async {
    try {
      final userRole = await getUserRole(uid);
      return userRole == role;
    } catch (e) {
      Logger.error('Error checking user role: $e');
      return false;
    }
  }
}
