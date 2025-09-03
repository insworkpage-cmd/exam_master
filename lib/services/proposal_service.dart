import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/question_model.dart';
import '../services/capacity_service.dart';
import '../utils/logger.dart';

class ProposalService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ارسال پیشنهاد سوال جدید
  static Future<bool> submitProposal({
    required Question question,
    required String userId,
  }) async {
    try {
      // بررسی ظرفیت کاربر
      final capacityStatus =
          await CapacityService.getUserCapacityStatus(userId);
      if (capacityStatus['isBlocked'] == true) {
        throw Exception('سرویس پیشنهاد سوال شما مسدود شده است');
      }
      if (capacityStatus['capacity'] <= 0) {
        throw Exception('ظرفیت پیشنهاد سوال شما تمام شده است');
      }

      // ایجاد سوال در Firestore
      await _firestore.collection('questions').add(question.toMap());

      // کاهش ظرفیت کاربر
      await CapacityService.decreaseProposalCapacity(userId);

      return true;
    } catch (e) {
      Logger.error('Error submitting proposal: $e');
      rethrow;
    }
  }

  // دریافت پیشنهادات کاربر
  static Future<List<Question>> getUserProposals(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('proposedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting user proposals: $e');
      return [];
    }
  }

  // دریافت درخواست‌های افزایش ظرفیت
  static Future<List<Map<String, dynamic>>> getCapacityRequests() async {
    try {
      final snapshot = await _firestore
          .collection('capacity_requests')
          .orderBy('requestedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      Logger.error('Error getting capacity requests: $e');
      return [];
    }
  }

  // ایجاد درخواست افزایش ظرفیت
  static Future<bool> createCapacityRequest({
    required String userId,
    required String userEmail,
    required String reason,
  }) async {
    try {
      await _firestore.collection('capacity_requests').add({
        'userId': userId,
        'userEmail': userEmail,
        'reason': reason,
        'status': 'pending',
        'requestedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Logger.error('Error creating capacity request: $e');
      return false;
    }
  }

  // به‌روزرسانی وضعیت درخواست افزایش ظرفیت
  static Future<bool> updateCapacityRequest({
    required String requestId,
    required String status,
    required String moderatorId,
    int? approvedAmount,
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'status': status,
        'moderatorId': moderatorId,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (approvedAmount != null) {
        updateData['approvedAmount'] =
            approvedAmount.toString(); // اصلاح خطا: تبدیل int به String
      }

      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await _firestore
          .collection('capacity_requests')
          .doc(requestId)
          .update(updateData);

      return true;
    } catch (e) {
      Logger.error('Error updating capacity request: $e');
      return false;
    }
  }

  // دریافت گزارش‌های سوالات
  static Future<List<Map<String, dynamic>>> getQuestionReports() async {
    try {
      final snapshot = await _firestore
          .collection('question_reports')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      Logger.error('Error getting question reports: $e');
      return [];
    }
  }

  // ایجاد گزارش سوال
  static Future<bool> createQuestionReport({
    required String questionId,
    required String userId,
    required String userEmail,
    required String reportType,
    String? description,
  }) async {
    try {
      await _firestore.collection('question_reports').add({
        'questionId': questionId,
        'userId': userId,
        'userEmail': userEmail,
        'reportType': reportType,
        'description': description,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      Logger.error('Error creating question report: $e');
      return false;
    }
  }

  // به‌روزرسانی وضعیت گزارش سوال
  static Future<bool> updateQuestionReport({
    required String reportId,
    required String status,
    required String moderatorId,
    String? resolution,
  }) async {
    try {
      final updateData = {
        'status': status,
        'moderatorId': moderatorId,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (resolution != null) {
        updateData['resolution'] = resolution;
      }

      await _firestore
          .collection('question_reports')
          .doc(reportId)
          .update(updateData);

      return true;
    } catch (e) {
      Logger.error('Error updating question report: $e');
      return false;
    }
  }
}
