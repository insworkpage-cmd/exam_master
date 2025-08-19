import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/question_model.dart';
import '../utils/logger.dart';
import '../models/question_stats_model.dart'; // ← اضافه کردن import

class QuestionService {
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;
  QuestionService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // تغییر اصلی: تبدیل خروجی به QuestionStats
  Future<QuestionStats> getQuestionStats() async {
    try {
      final snapshot = await _firestore.collection('questions').get();
      final questions = snapshot.docs.map((doc) => doc.data()).toList();

      return QuestionStats(
        total: questions.length,
        pending: questions.where((q) => q['status'] == 'pending').length,
        approved: questions.where((q) => q['status'] == 'approved').length,
        rejected: questions.where((q) => q['status'] == 'rejected').length,
      );
    } catch (e) {
      Logger.error('Error getting question stats: $e');
      return const QuestionStats(
        total: 0,
        pending: 0,
        approved: 0,
        rejected: 0,
      );
    }
  }

  Future<List<Question>> getAllQuestions() async {
    try {
      final snapshot = await _firestore.collection('questions').get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting all questions: $e');
      return [];
    }
  }

  Future<List<Question>> getQuestionsByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('status', isEqualTo: status)
          .get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting questions by status: $e');
      return [];
    }
  }

  Future<List<Question>> getQuestionsByInstructor(String instructorId) async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('instructorId', isEqualTo: instructorId)
          .get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting questions by instructor: $e');
      return [];
    }
  }

  Future<Question?> getQuestionById(String questionId) async {
    try {
      final doc =
          await _firestore.collection('questions').doc(questionId).get();
      if (!doc.exists) return null;
      return Question.fromMap(doc.data()!);
    } catch (e) {
      Logger.error('Error getting question by ID: $e');
      return null;
    }
  }

  Future<Question> addQuestion(Question question) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final questionWithMeta = question.copyWith(
        instructorId: user.uid,
        createdAt: DateTime.now(),
      );
      final docRef = _firestore.collection('questions').doc(question.id);
      await docRef.set(questionWithMeta.toMap());
      Logger.info('Question added successfully: ${question.id}');
      return questionWithMeta;
    } catch (e) {
      Logger.error('Error adding question: $e');
      rethrow;
    }
  }

  Future<Question> updateQuestion(Question question) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final updatedQuestion = question.copyWith(
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection('questions')
          .doc(question.id)
          .update(updatedQuestion.toMap());
      Logger.info('Question updated successfully: ${question.id}');
      return updatedQuestion;
    } catch (e) {
      Logger.error('Error updating question: $e');
      rethrow;
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
      Logger.info('Question deleted successfully: $questionId');
    } catch (e) {
      Logger.error('Error deleting question: $e');
      rethrow;
    }
  }

  Future<Question> approveQuestion(
      String questionId, String moderatorId) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }
      final approvedQuestion = question.copyWithStatus('approved');
      await _firestore
          .collection('questions')
          .doc(questionId)
          .update(approvedQuestion.toMap());
      // ثبت عملیات تأیید
      await _firestore.collection('question_approvals').add({
        'questionId': questionId,
        'moderatorId': moderatorId,
        'action': 'approved',
        'timestamp': DateTime.now().toIso8601String(),
      });
      Logger.info('Question approved successfully: $questionId');
      return approvedQuestion;
    } catch (e) {
      Logger.error('Error approving question: $e');
      rethrow;
    }
  }

  Future<Question> rejectQuestion(
      String questionId, String moderatorId, String reason) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }
      final rejectedQuestion = question.copyWithStatus('rejected');
      await _firestore
          .collection('questions')
          .doc(questionId)
          .update(rejectedQuestion.toMap());
      // ثبت عملیات رد
      await _firestore.collection('question_approvals').add({
        'questionId': questionId,
        'moderatorId': moderatorId,
        'action': 'rejected',
        'reason': reason,
        'timestamp': DateTime.now().toIso8601String(),
      });
      Logger.info('Question rejected successfully: $questionId');
      return rejectedQuestion;
    } catch (e) {
      Logger.error('Error rejecting question: $e');
      rethrow;
    }
  }

  Future<List<Question>> getQuestionsForQuiz(String classId) async {
    try {
      final snapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('questions')
          .get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting questions for quiz: $e');
      return [];
    }
  }

  Future<void> bulkUpdateQuestions(List<Question> questions) async {
    try {
      final batch = _firestore.batch();
      for (final question in questions) {
        final docRef = _firestore.collection('questions').doc(question.id);
        batch.update(docRef, question.toMap());
      }
      await batch.commit();
      Logger.info('Bulk updated ${questions.length} questions successfully');
    } catch (e) {
      Logger.error('Error bulk updating questions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getQuestionAnalytics() async {
    try {
      final snapshot = await _firestore.collection('questions').get();
      final questions = snapshot.docs.map((doc) => doc.data()).toList();
      final totalQuestions = questions.length;
      final approvedQuestions =
          questions.where((q) => q['status'] == 'approved').length;
      final pendingQuestions =
          questions.where((q) => q['status'] == 'pending').length;
      final rejectedQuestions =
          questions.where((q) => q['status'] == 'rejected').length;
      // محاسبه آمار بر اساس سختی
      final easyQuestions = questions.where((q) => q['difficulty'] == 1).length;
      final mediumQuestions =
          questions.where((q) => q['difficulty'] == 2).length;
      final hardQuestions = questions.where((q) => q['difficulty'] == 3).length;
      // محاسبه آمار بر اساس دسته‌بندی
      final categories = <String, int>{};
      for (final question in questions) {
        final category = question['category'] as String? ?? 'uncategorized';
        categories[category] = (categories[category] ?? 0) + 1;
      }
      return {
        'total': totalQuestions,
        'approved': approvedQuestions,
        'pending': pendingQuestions,
        'rejected': rejectedQuestions,
        'difficulty': {
          'easy': easyQuestions,
          'medium': mediumQuestions,
          'hard': hardQuestions,
        },
        'categories': categories,
      };
    } catch (e) {
      Logger.error('Error getting question analytics: $e');
      return {};
    }
  }
}
