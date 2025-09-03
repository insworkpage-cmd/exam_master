import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/question_model.dart';
import '../utils/logger.dart';
import '../models/question_stats_model.dart';

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
      final questions =
          snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();

      return QuestionStats(
        total: questions.length,
        pending: questions.where((q) => q.isPending).length,
        approved: questions.where((q) => q.isApproved).length,
        rejected: questions.where((q) => q.isRejected).length,
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

  // متد جدید: دریافت سوالات بر اساس کلاس
  Future<List<Question>> getQuestionsByClass(String classId) async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('classId', isEqualTo: classId)
          .get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting questions by class: $e');
      return [];
    }
  }

  // متد جدید: دریافت سوالات پیشنهادی توسط کاربران
  Future<List<Question>> getProposedQuestions() async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('proposedBy', isNotEqualTo: null)
          .get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting proposed questions: $e');
      return [];
    }
  }

  // متد جدید: دریافت سوالات پیشنهادی توسط کاربر خاص
  Future<List<Question>> getQuestionsProposedByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('proposedBy', isEqualTo: userId)
          .get();
      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting questions proposed by user: $e');
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

  // اصلاح شده: پشتیبانی از ایجاد سوال برای کلاس و پیشنهاد سوال توسط کاربران
  Future<Question> addQuestion({
    required Question question,
    String? classId,
    String? proposedBy,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // ایجاد سوال با متادیتای مناسب
      final questionWithMeta = question.copyWith(
        instructorId: user.uid,
        classId: classId,
        proposedBy: proposedBy,
        createdAt: DateTime.now(),
        // سوالات کلاس مستقیماً تایید می‌شوند، سوالات عمومی نیاز به تایید دارند
        status: classId != null ? 'approved' : 'pending',
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

  // اصلاح شده: استفاده از متدهای جدید QuestionModel
  Future<Question> approveQuestion(
    String questionId,
    String moderatorId, {
    String? comment,
  }) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }

      final approvedQuestion = question.approve(moderatorId, comment: comment);

      await _firestore
          .collection('questions')
          .doc(questionId)
          .update(approvedQuestion.toMap());

      // ثبت عملیات تأیید
      await _firestore.collection('question_approvals').add({
        'questionId': questionId,
        'moderatorId': moderatorId,
        'action': 'approved',
        'comment': comment,
        'timestamp': DateTime.now().toIso8601String(),
      });

      Logger.info('Question approved successfully: $questionId');
      return approvedQuestion;
    } catch (e) {
      Logger.error('Error approving question: $e');
      rethrow;
    }
  }

  // اصلاح شده: استفاده از متدهای جدید QuestionModel
  Future<Question> rejectQuestion(
      String questionId, String moderatorId, String reason) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }

      final rejectedQuestion = question.reject(moderatorId, reason);

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

  // اصلاح شده: دریافت سوالات تایید شده برای کلاس
  Future<List<Question>> getQuestionsForQuiz(String classId) async {
    try {
      // دریافت سوالات کلاس و سوالات عمومی تایید شده
      final classQuestionsSnapshot = await _firestore
          .collection('questions')
          .where('classId', isEqualTo: classId)
          .get();

      final publicQuestionsSnapshot = await _firestore
          .collection('questions')
          .where('classId', isNull: true)
          .where('status', isEqualTo: 'approved')
          .get();

      final classQuestions = classQuestionsSnapshot.docs
          .map((doc) => Question.fromMap(doc.data()))
          .toList();

      final publicQuestions = publicQuestionsSnapshot.docs
          .map((doc) => Question.fromMap(doc.data()))
          .toList();

      return [...classQuestions, ...publicQuestions];
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

  // اصلاح شده: استفاده از متدهای جدید QuestionModel
  Future<Map<String, dynamic>> getQuestionAnalytics() async {
    try {
      final snapshot = await _firestore.collection('questions').get();
      final questions =
          snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();

      final totalQuestions = questions.length;
      final approvedQuestions = questions.where((q) => q.isApproved).length;
      final pendingQuestions = questions.where((q) => q.isPending).length;
      final rejectedQuestions = questions.where((q) => q.isRejected).length;

      // محاسبه آمار بر اساس سختی
      final easyQuestions = questions.where((q) => q.isEasy).length;
      final mediumQuestions = questions.where((q) => q.isMedium).length;
      final hardQuestions = questions.where((q) => q.isHard).length;

      // محاسبه آمار بر اساس دسته‌بندی
      final categories = <String, int>{};
      for (final question in questions) {
        final category = question.category ?? 'uncategorized';
        categories[category] = (categories[category] ?? 0) + 1;
      }

      // محاسبه آمار بر اساس نوع سوال
      final classQuestions = questions.where((q) => q.isClassQuestion).length;
      final publicQuestions = questions.where((q) => q.isPublicQuestion).length;
      final proposedQuestions =
          questions.where((q) => q.isProposedByUser).length;

      // محاسبه میانگین زمان تایید سوالات
      final approvedQuestionsWithReview =
          questions.where((q) => q.isApproved && q.reviewDate != null).toList();

      double averageApprovalTime = 0;
      if (approvedQuestionsWithReview.isNotEmpty) {
        final totalDays = approvedQuestionsWithReview
            .map((q) => q.reviewDate!.difference(q.createdAt).inDays)
            .reduce((total, days) => total + days);
        averageApprovalTime = totalDays / approvedQuestionsWithReview.length;
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
        'type': {
          'class': classQuestions,
          'public': publicQuestions,
          'proposed': proposedQuestions,
        },
        'averageApprovalTime': averageApprovalTime.toStringAsFixed(1),
      };
    } catch (e) {
      Logger.error('Error getting question analytics: $e');
      return {};
    }
  }

  // متد جدید: دریافت سوالات در انتظار تایید برای ناظر
  Future<List<Question>> getPendingQuestionsForModerator() async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('status', isEqualTo: 'pending')
          .where('classId',
              isNull: true) // فقط سوالات عمومی نیاز به تایید دارند
          .get();

      return snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
    } catch (e) {
      Logger.error('Error getting pending questions for moderator: $e');
      return [];
    }
  }

  // متد جدید: دریافت تاریخچه تایید/رد سوالات
  Future<List<Map<String, dynamic>>> getQuestionApprovalHistory(
      String questionId) async {
    try {
      final snapshot = await _firestore
          .collection('question_approvals')
          .where('questionId', isEqualTo: questionId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      Logger.error('Error getting question approval history: $e');
      return [];
    }
  }
}
