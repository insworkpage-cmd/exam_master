import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

class TicketService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ایجاد تیکت جدید
  static Future<String> createTicket({
    required String userId,
    required String userEmail,
    required String userName,
    required String subject,
    required String description,
    required String category,
    String? questionId,
    String? relatedQuestionText,
  }) async {
    try {
      final ticketRef = await _firestore.collection('tickets').add({
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'subject': subject,
        'description': description,
        'category': category,
        'status': 'open',
        'priority': 'normal',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'questionId': questionId,
        'relatedQuestionText': relatedQuestionText,
        'responses': <Map<String, dynamic>>[],
        'assignedTo': null,
        'assignedAt': null,
        'resolvedAt': null,
        'resolution': null,
      });

      Logger.info('Ticket created successfully: ${ticketRef.id}');
      return ticketRef.id;
    } catch (e) {
      Logger.error('Error creating ticket: $e');
      rethrow;
    }
  }

  // دریافت تیکت‌های کاربر
  static Future<List<Map<String, dynamic>>> getUserTickets(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      Logger.error('Error getting user tickets: $e');
      return [];
    }
  }

  // دریافت تیکت‌های باز
  static Future<List<Map<String, dynamic>>> getOpenTickets() async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('status', whereIn: ['open', 'in_progress'])
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      Logger.error('Error getting open tickets: $e');
      return [];
    }
  }

  // دریافت تیکت‌های اختصاص داده شده به کاربر
  static Future<List<Map<String, dynamic>>> getAssignedTickets(
      String moderatorId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('assignedTo', isEqualTo: moderatorId)
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      Logger.error('Error getting assigned tickets: $e');
      return [];
    }
  }

  // دریافت جزئیات تیکت
  static Future<Map<String, dynamic>?> getTicketById(String ticketId) async {
    try {
      final doc = await _firestore.collection('tickets').doc(ticketId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      data['id'] = doc.id;
      return data;
    } catch (e) {
      Logger.error('Error getting ticket by ID: $e');
      return null;
    }
  }

  // افزودن پاسخ به تیکت
  static Future<bool> addResponse({
    required String ticketId,
    required String responderId,
    required String responderName,
    required String responderRole,
    required String response,
    required String responseRole,
  }) async {
    try {
      final ticketRef = _firestore.collection('tickets').doc(ticketId);

      // ایجاد پاسخ جدید
      final responseData = <String, dynamic>{
        'responderId': responderId,
        'responderName': responderName,
        'responderRole': responderRole,
        'response': response,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await ticketRef.update({
        'responses': FieldValue.arrayUnion([responseData]),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // اگر پاسخ توسط ناظر است، وضعیت تیکت را به "in_progress" تغییر می‌دهیم
      if (responseRole == 'moderator') {
        await ticketRef.update({
          'status': 'in_progress',
          'assignedTo': responderId,
          'assignedAt': DateTime.now().toIso8601String(),
        });
      }

      Logger.info('Response added to ticket: $ticketId');
      return true;
    } catch (e) {
      Logger.error('Error adding response to ticket: $e');
      return false;
    }
  }

  // اختصاص تیکت به ناظر
  static Future<bool> assignTicket({
    required String ticketId,
    required String moderatorId,
    required String moderatorName,
  }) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'assignedTo': moderatorId,
        'assignedToName': moderatorName,
        'assignedAt': DateTime.now().toIso8601String(),
        'status': 'in_progress',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      Logger.info('Ticket assigned to moderator: $ticketId');
      return true;
    } catch (e) {
      Logger.error('Error assigning ticket: $e');
      return false;
    }
  }

  // تغییر وضعیت تیکت
  static Future<bool> updateTicketStatus({
    required String ticketId,
    required String status,
    required String moderatorId,
    String? resolution,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (resolution != null) {
        updateData['resolution'] = resolution;
      }

      if (status == 'resolved') {
        updateData['resolvedAt'] = DateTime.now().toIso8601String();
      }

      await _firestore.collection('tickets').doc(ticketId).update(updateData);

      Logger.info('Ticket status updated: $ticketId -> $status');
      return true;
    } catch (e) {
      Logger.error('Error updating ticket status: $e');
      return false;
    }
  }

  // تغییر اولویت تیکت
  static Future<bool> updateTicketPriority({
    required String ticketId,
    required String priority,
  }) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'priority': priority,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      Logger.info('Ticket priority updated: $ticketId -> $priority');
      return true;
    } catch (e) {
      Logger.error('Error updating ticket priority: $e');
      return false;
    }
  }

  // بستن تیکت توسط کاربر
  static Future<bool> closeTicketByUser({
    required String ticketId,
    required String userId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'status': 'closed_by_user',
        'closedBy': userId,
        'closedAt': DateTime.now().toIso8601String(),
        'resolution': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      Logger.info('Ticket closed by user: $ticketId');
      return true;
    } catch (e) {
      Logger.error('Error closing ticket by user: $e');
      return false;
    }
  }

  // بازگشتن تیکت توسط ناظر
  static Future<bool> reopenTicket({
    required String ticketId,
    required String moderatorId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update({
        'status': 'reopened',
        'reopenedBy': moderatorId,
        'reopenedAt': DateTime.now().toIso8601String(),
        'reopenedReason': reason,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      Logger.info('Ticket reopened: $ticketId');
      return true;
    } catch (e) {
      Logger.error('Error reopening ticket: $e');
      return false;
    }
  }

  // دریافت آمار تیکت‌ها
  static Future<Map<String, dynamic>> getTicketStats() async {
    try {
      final openSnapshot = await _firestore
          .collection('tickets')
          .where('status', whereIn: ['open', 'in_progress']).get();

      final closedSnapshot = await _firestore
          .collection('tickets')
          .where('status', whereIn: ['resolved', 'closed_by_user']).get();

      final openCount = openSnapshot.size;
      final closedCount = closedSnapshot.size;

      // گروه‌بندی بر اساس دسته‌بندی
      final categories = <String, int>{};
      for (var doc in openSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'other';
        categories[category] = (categories[category] ?? 0) + 1;
      }

      // گروه‌بندی بر اساس اولویت
      final priorities = <String, int>{};
      for (var doc in openSnapshot.docs) {
        final data = doc.data();
        final priority = data['priority'] as String? ?? 'normal';
        priorities[priority] = (priorities[priority] ?? 0) + 1;
      }

      return {
        'totalTickets': openCount + closedCount,
        'openTickets': openCount,
        'closedTickets': closedCount,
        'categories': categories,
        'priorities': priorities,
      };
    } catch (e) {
      Logger.error('Error getting ticket stats: $e');
      return {};
    }
  }

  // جستجوی تیکت‌ها - اصلاح شده
  static Future<List<Map<String, dynamic>>> searchTickets({
    String? category,
    String? status,
    String? priority,
    String? assignedTo,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('tickets');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (priority != null) {
        query = query.where('priority', isEqualTo: priority);
      }
      if (assignedTo != null) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs.map((doc) {
        final data =
            doc.data() as Map<String, dynamic>; // اصلاح خطا: تبدیل نوع صریح
        final result = Map<String, dynamic>.from(data); // اصلاح خطا: ایجاد کپی
        result['id'] = doc.id;
        return result;
      }).toList();
    } catch (e) {
      Logger.error('Error searching tickets: $e');
      return [];
    }
  }

  // دریافت تیکت‌های مرتبط با سوال خاص
  static Future<List<Map<String, dynamic>>> getTicketsForQuestion(
      String questionId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('questionId', isEqualTo: questionId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      Logger.error('Error getting tickets for question: $e');
      return [];
    }
  }
}
