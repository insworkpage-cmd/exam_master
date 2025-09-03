import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/question_model.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class ReportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // دریافت گزارش کلی سوالات
  static Future<Map<String, dynamic>> getQuestionsReport() async {
    try {
      final snapshot = await _firestore.collection('questions').get();
      final questions =
          snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();

      final totalQuestions = questions.length;
      final pendingQuestions = questions.where((q) => q.isPending).length;
      final approvedQuestions = questions.where((q) => q.isApproved).length;
      final rejectedQuestions = questions.where((q) => q.isRejected).length;

      // گروه‌بندی بر اساس مدرس
      final Map<String, int> instructorStats = {};
      for (var question in questions) {
        if (question.instructorId != null) {
          instructorStats[question.instructorId!] =
              (instructorStats[question.instructorId!] ?? 0) + 1;
        }
      }

      // گروه‌بندی بر اساس کلاس (جدید)
      final Map<String, int> classStats = {};
      for (var question in questions) {
        if (question.classId != null) {
          classStats[question.classId!] =
              (classStats[question.classId!] ?? 0) + 1;
        }
      }

      // گروه‌بندی بر اساس کاربر پیشنهاددهنده (جدید)
      final Map<String, int> proposedByStats = {};
      for (var question in questions) {
        if (question.proposedBy != null) {
          proposedByStats[question.proposedBy!] =
              (proposedByStats[question.proposedBy!] ?? 0) + 1;
        }
      }

      return {
        'total': totalQuestions,
        'pending': pendingQuestions,
        'approved': approvedQuestions,
        'rejected': rejectedQuestions,
        'instructorStats': instructorStats,
        'classStats': classStats, // ← اضافه شد
        'proposedByStats': proposedByStats, // ← اضافه شد
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting questions report: $e');
      rethrow;
    }
  }

  // دریافت گزارش کاربران
  static Future<Map<String, dynamic>> getUsersReport() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users =
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();

      final totalUsers = users.length;
      final activeUsers = users.where((u) => u.isActive).length;
      final inactiveUsers = users.where((u) => !u.isActive).length;

      // گروه‌بندی بر اساس نقش
      final Map<String, int> roleStats = {};
      for (var user in users) {
        roleStats[user.role.name] = (roleStats[user.role.name] ?? 0) + 1;
      }

      return {
        'total': totalUsers,
        'active': activeUsers,
        'inactive': inactiveUsers,
        'roleStats': roleStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting users report: $e');
      rethrow;
    }
  }

  // دریافت گزارش آزمون‌ها
  static Future<Map<String, dynamic>> getQuizzesReport() async {
    try {
      final snapshot = await _firestore.collection('quiz_results').get();
      final quizzes = snapshot.docs.map((doc) => doc.data()).toList();

      final totalQuizzes = quizzes.length;
      double averageScore = 0;
      int totalParticipants = 0;

      if (quizzes.isNotEmpty) {
        // محاسبه تعداد کل شرکت‌کنندگان با تبدیل نوع صریح
        totalParticipants = quizzes
            .map<int>((quiz) => quiz['participants'] ?? 0)
            .reduce((a, b) => a + b);
        // محاسبه میانگین امتیازات با تبدیل نوع صریح
        averageScore = quizzes
                .map<double>((quiz) => quiz['averageScore'] ?? 0.0)
                .reduce((a, b) => a + b) /
            quizzes.length;
      }

      return {
        'total': totalQuizzes,
        'averageScore': averageScore.toStringAsFixed(2),
        'totalParticipants': totalParticipants,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting quizzes report: $e');
      rethrow;
    }
  }

  // دریافت گزارش فعالیت‌های روزانه
  static Future<Map<String, dynamic>> getActivityReport({int days = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('activities')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .get();

      final activities = snapshot.docs.map((doc) => doc.data()).toList();

      // گروه‌بندی بر اساس نوع فعالیت
      final Map<String, int> activityTypes = {};
      for (var activity in activities) {
        final type = activity['type'] ?? 'unknown';
        activityTypes[type] = (activityTypes[type] ?? 0) + 1;
      }

      // گروه‌بندی بر اساس روز
      final Map<String, int> dailyActivities = {};
      for (var i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyActivities[dateKey] = 0;
      }

      for (var activity in activities) {
        final timestamp = (activity['timestamp'] as Timestamp).toDate();
        final dateKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        if (dailyActivities.containsKey(dateKey)) {
          dailyActivities[dateKey] = (dailyActivities[dateKey] ?? 0) + 1;
        }
      }

      return {
        'totalActivities': activities.length,
        'activityTypes': activityTypes,
        'dailyActivities': dailyActivities,
        'period': '$days days',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting activity report: $e');
      rethrow;
    }
  }

  // دریافت گزارش عملکرد کاربران
  static Future<Map<String, dynamic>> getUserPerformanceReport(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('quiz_results')
          .where('userId', isEqualTo: userId)
          .get();

      final results = snapshot.docs.map((doc) => doc.data()).toList();

      if (results.isEmpty) {
        return {
          'totalQuizzes': 0,
          'averageScore': '0',
          'bestScore': 0,
          'worstScore': 0,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      }

      final scores = results.map<int>((r) => r['score'] ?? 0).toList();
      // محاسبه میانگین با تبدیل نوع صریح
      final averageScore =
          scores.fold<double>(0.0, (total, score) => total + score) /
              scores.length;
      // پیدا کردن بالاترین و پایین‌ترین امتیاز
      final bestScore =
          scores.reduce((max, score) => score > max ? score : max);
      final worstScore =
          scores.reduce((min, score) => score < min ? score : min);

      return {
        'totalQuizzes': results.length,
        'averageScore': averageScore.toStringAsFixed(2),
        'bestScore': bestScore,
        'worstScore': worstScore,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting user performance report: $e');
      rethrow;
    }
  }

  // دریافت گزارش پیشرفت کلاس‌ها
  static Future<Map<String, dynamic>> getClassProgressReport(
      String classId) async {
    try {
      final snapshot = await _firestore
          .collection('classes')
          .doc(classId)
          .collection('students')
          .get();

      final students = snapshot.docs.map((doc) => doc.data()).toList();
      final totalStudents = students.length;
      final activeStudents =
          students.where((s) => s['isActive'] ?? false).length;

      // محاسبه میانگین پیشرفت با استفاده از map و reduce
      final averageProgress = students.isNotEmpty
          ? students
                  .map<double>((s) => s['progress'] ?? 0.0)
                  .reduce((total, progress) => total + progress) /
              students.length
          : 0.0;

      return {
        'totalStudents': totalStudents,
        'activeStudents': activeStudents,
        'averageProgress': averageProgress.toStringAsFixed(2),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting class progress report: $e');
      rethrow;
    }
  }

  // دریافت گزارش آماری کلی
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final questionsReport = await getQuestionsReport();
      final usersReport = await getUsersReport();
      final quizzesReport = await getQuizzesReport();

      return {
        'questions': questionsReport,
        'users': usersReport,
        'quizzes': quizzesReport,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting dashboard stats: $e');
      rethrow;
    }
  }

  // === متدهای جدید برای نیازمندی‌های جدید ===

  // دریافت گزارش سوالات پیشنهادی توسط کاربران عادی (جدید)
  // دریافت گزارش سوالات پیشنهادی توسط کاربران عادی (جدید)
  static Future<Map<String, dynamic>> getProposedQuestionsReport() async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('proposedBy', isNotEqualTo: null) // اصلاح شده
          .get();

      final questions =
          snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();

      final totalProposed = questions.length;
      final pendingProposed = questions.where((q) => q.isPending).length;
      final approvedProposed = questions.where((q) => q.isApproved).length;
      final rejectedProposed = questions.where((q) => q.isRejected).length;

      // گروه‌بندی بر اساس کاربر پیشنهاددهنده
      final Map<String, int> userStats = {};
      for (var question in questions) {
        if (question.proposedBy != null) {
          userStats[question.proposedBy!] =
              (userStats[question.proposedBy!] ?? 0) + 1;
        }
      }

      // محاسبه میانگین زمان پاسخگویی (روز)
      double averageResponseTime = 0;
      final reviewedQuestions =
          questions.where((q) => q.reviewDate != null).toList();
      if (reviewedQuestions.isNotEmpty) {
        final totalDays = reviewedQuestions
            .map((q) => q.reviewDate!.difference(q.createdAt).inDays)
            .reduce((total, days) => total + days);
        averageResponseTime = totalDays / reviewedQuestions.length;
      }

      return {
        'totalProposed': totalProposed,
        'pendingProposed': pendingProposed,
        'approvedProposed': approvedProposed,
        'rejectedProposed': rejectedProposed,
        'userStats': userStats,
        'averageResponseTime': averageResponseTime.toStringAsFixed(1),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting proposed questions report: $e');
      rethrow;
    }
  }

  // دریافت گزارش سوالات بر اساس کلاس (جدید)
  static Future<Map<String, dynamic>> getClassQuestionsReport(
      String classId) async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('classId', isEqualTo: classId)
          .get();

      final questions =
          snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();

      final totalQuestions = questions.length;
      final pendingQuestions = questions.where((q) => q.isPending).length;
      final approvedQuestions = questions.where((q) => q.isApproved).length;
      final rejectedQuestions = questions.where((q) => q.isRejected).length;

      // گروه‌بندی بر اساس سطح دشواری
      final Map<String, int> difficultyStats = {};
      for (var question in questions) {
        final difficulty = question.difficulty == 1
            ? 'easy'
            : question.difficulty == 2
                ? 'medium'
                : 'hard';
        difficultyStats[difficulty] = (difficultyStats[difficulty] ?? 0) + 1;
      }

      // گروه‌بندی بر اساس دسته‌بندی
      final Map<String, int> categoryStats = {};
      for (var question in questions) {
        if (question.category != null) {
          categoryStats[question.category!] =
              (categoryStats[question.category!] ?? 0) + 1;
        }
      }

      return {
        'classId': classId,
        'totalQuestions': totalQuestions,
        'pendingQuestions': pendingQuestions,
        'approvedQuestions': approvedQuestions,
        'rejectedQuestions': rejectedQuestions,
        'difficultyStats': difficultyStats,
        'categoryStats': categoryStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting class questions report: $e');
      rethrow;
    }
  }

  // دریافت گزارش عملکرد ناظرها (جدید)
  static Future<Map<String, dynamic>> getModeratorPerformanceReport() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'moderator')
          .get();

      final moderators =
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();

      final Map<String, dynamic> moderatorStats = {};

      for (var moderator in moderators) {
        final questionsSnapshot = await _firestore
            .collection('questions')
            .where('reviewedBy', isEqualTo: moderator.id)
            .get();

        final reviewedQuestions = questionsSnapshot.docs
            .map((doc) => Question.fromMap(doc.data()))
            .toList();

        final totalReviewed = reviewedQuestions.length;
        final approvedCount =
            reviewedQuestions.where((q) => q.isApproved).length;
        final rejectedCount =
            reviewedQuestions.where((q) => q.isRejected).length;

        // محاسبه میانگین زمان پاسخگویی (روز)
        double averageResponseTime = 0;
        if (reviewedQuestions.isNotEmpty) {
          final totalDays = reviewedQuestions
              .map((q) => q.reviewDate!.difference(q.createdAt).inDays)
              .reduce((total, days) => total + days);
          averageResponseTime = totalDays / reviewedQuestions.length;
        }

        moderatorStats[moderator.id] = {
          'name': moderator.name,
          'totalReviewed': totalReviewed,
          'approvedCount': approvedCount,
          'rejectedCount': rejectedCount,
          'averageResponseTime': averageResponseTime.toStringAsFixed(1),
        };
      }

      return {
        'moderatorStats': moderatorStats,
        'totalModerators': moderators.length,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting moderator performance report: $e');
      rethrow;
    }
  }

  // دریافت گزارش سوالات تایید شده توسط هر ناظر (جدید)
  static Future<Map<String, dynamic>> getModeratorApprovedQuestionsReport(
      String moderatorId) async {
    try {
      final snapshot = await _firestore
          .collection('questions')
          .where('reviewedBy', isEqualTo: moderatorId)
          .where('status', isEqualTo: 'approved')
          .get();

      final questions =
          snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();

      final totalApproved = questions.length;

      // گروه‌بندی بر اساس دسته‌بندی
      final Map<String, int> categoryStats = {};
      for (var question in questions) {
        if (question.category != null) {
          categoryStats[question.category!] =
              (categoryStats[question.category!] ?? 0) + 1;
        }
      }

      // گروه‌بندی بر اساس ماه
      final Map<String, int> monthlyStats = {};
      for (var question in questions) {
        final monthKey =
            '${question.reviewDate!.year}-${question.reviewDate!.month.toString().padLeft(2, '0')}';
        monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
      }

      return {
        'moderatorId': moderatorId,
        'totalApproved': totalApproved,
        'categoryStats': categoryStats,
        'monthlyStats': monthlyStats,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting moderator approved questions report: $e');
      rethrow;
    }
  }
}
