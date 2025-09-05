import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class CapacityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // کاهش ظرفیت پیشنهاد سوال
  static Future<bool> decreaseProposalCapacity(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) return false;

      final user = UserModel.fromMap(userSnapshot.data()!);
      if (user.questionProposalCapacity <= 0) return false;

      await userDoc.update({
        'questionProposalCapacity': user.questionProposalCapacity - 1,
        'lastProposalDate': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Logger.error('Error decreasing proposal capacity: $e');
      return false;
    }
  }

  // بازگشت ظرفیت در صورت تایید یا رد عادی
  static Future<bool> restoreProposalCapacity(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) return false;

      final user = UserModel.fromMap(userSnapshot.data()!);
      await userDoc.update({
        'questionProposalCapacity': user.questionProposalCapacity + 1,
      });

      return true;
    } catch (e) {
      Logger.error('Error restoring proposal capacity: $e');
      return false;
    }
  }

  // افزایش ظرفیت توسط ناظر
  static Future<bool> increaseProposalCapacity(
      String userId, int amount) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      await userDoc.update({
        'questionProposalCapacity': FieldValue.increment(amount),
      });

      return true;
    } catch (e) {
      Logger.error('Error increasing proposal capacity: $e');
      return false;
    }
  }

  // مسدود کردن پیشنهاد سوال توسط ادمین
  static Future<bool> blockProposalService(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isProposalBlocked': true,
        'proposalBlockedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Logger.error('Error blocking proposal service: $e');
      return false;
    }
  }

  // رفع مسدودی پیشنهاد سوال توسط ادمین
  static Future<bool> unblockProposalService(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isProposalBlocked': false,
        'proposalUnblockedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Logger.error('Error unblocking proposal service: $e');
      return false;
    }
  }

  // بررسی وضعیت ظرفیت کاربر
  static Future<Map<String, dynamic>> getUserCapacityStatus(
      String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        return {'capacity': 0, 'isBlocked': true};
      }

      final user = UserModel.fromMap(userSnapshot.data()!);

      return {
        'capacity': user.questionProposalCapacity,
        'isBlocked': user.isProposalBlocked,
        'lastProposalDate': user.lastProposalDate,
      };
    } catch (e) {
      Logger.error('Error getting user capacity status: $e');
      return {'capacity': 0, 'isBlocked': true};
    }
  }
}
