import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/question_model.dart';
import '../utils/logger.dart';

class QuestionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'questions';

  // دریافت تمام سوالات
  static Future<List<Question>> getAllQuestions() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting all questions: $e');
      rethrow;
    }
  }

  // دریافت سوالات بر اساس مدرس
  static Future<List<Question>> getQuestionsByInstructor(
      String instructorId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('instructorId', isEqualTo: instructorId)
          .get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting questions by instructor: $e');
      rethrow;
    }
  }

  // دریافت سوالات بر اساس وضعیت
  static Future<List<Question>> getQuestionsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: status)
          .get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting questions by status: $e');
      rethrow;
    }
  }

  // افزودن سوال جدید
  static Future<void> addQuestion(Question question) async {
    try {
      final docRef = _firestore.collection(_collection).doc();
      final newQuestion = question.copyWith(id: docRef.id);
      await docRef.set(newQuestion.toMap());
      Logger.info('Question added successfully: ${docRef.id}');
    } catch (e) {
      Logger.error('Error adding question: $e');
      rethrow;
    }
  }

  // به‌روزرسانی سوال
  static Future<void> updateQuestion(Question question) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(question.id)
          .update(question.toMap());
      Logger.info('Question updated successfully: ${question.id}');
    } catch (e) {
      Logger.error('Error updating question: $e');
      rethrow;
    }
  }

  // حذف سوال
  static Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection(_collection).doc(questionId).delete();
      Logger.info('Question deleted successfully: $questionId');
    } catch (e) {
      Logger.error('Error deleting question: $e');
      rethrow;
    }
  }

  // تأیید سوال
  static Future<void> approveQuestion(
      String questionId, String approvedBy) async {
    try {
      await _firestore.collection(_collection).doc(questionId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedAt': DateTime.now().toIso8601String(),
      });
      Logger.info('Question approved successfully: $questionId');
    } catch (e) {
      Logger.error('Error approving question: $e');
      rethrow;
    }
  }

  // رد سوال
  static Future<void> rejectQuestion(
      String questionId, String rejectedBy, String reason) async {
    try {
      await _firestore.collection(_collection).doc(questionId).update({
        'status': 'rejected',
        'rejectedBy': rejectedBy,
        'rejectedAt': DateTime.now().toIso8601String(),
        'rejectionReason': reason,
      });
      Logger.info('Question rejected successfully: $questionId');
    } catch (e) {
      Logger.error('Error rejecting question: $e');
      rethrow;
    }
  }

  // دریافت آمار سوالات
  static Future<Map<String, int>> getQuestionStats() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final questions =
          snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();

      return {
        'total': questions.length,
        'pending': questions.where((q) => q.status == 'pending').length,
        'approved': questions.where((q) => q.status == 'approved').length,
        'rejected': questions.where((q) => q.status == 'rejected').length,
      };
    } catch (e) {
      Logger.error('Error getting question stats: $e');
      rethrow;
    }
  }
}
