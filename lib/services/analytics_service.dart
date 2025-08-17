import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/question_model.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

class AnalyticsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // دریافت تحلیل‌های کلی داشبورد
  static Future<Map<String, dynamic>> getDashboardAnalytics() async {
    try {
      final results = await Future.wait([
        _getUserGrowthData(),
        _getQuizPerformanceData(),
        _getQuestionStatsData(),
        _getActivityTrendsData(),
      ]);
      return {
        'userGrowth': results[0],
        'quizPerformance': results[1],
        'questionStats': results[2],
        'activityTrends': results[3],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting dashboard analytics: $e');
      rethrow;
    }
  }

  // دریافت داده‌های رشد کاربران
  static Future<Map<String, dynamic>> _getUserGrowthData() async {
    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();
      final users =
          snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      // گروه‌بندی بر اساس روز
      final Map<String, int> dailyGrowth = {};
      for (var i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyGrowth[dateKey] = 0;
      }
      for (var user in users) {
        final dateKey =
            '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}-${user.createdAt.day.toString().padLeft(2, '0')}';
        if (dailyGrowth.containsKey(dateKey)) {
          dailyGrowth[dateKey] = (dailyGrowth[dateKey] ?? 0) + 1;
        }
      }
      // محاسبه نرخ رشد
      final totalUsers = users.length;
      final previousPeriodSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isLessThan: thirtyDaysAgo)
          .count()
          .get();
      final previousPeriodUsers = previousPeriodSnapshot.count ?? 0;
      final growthRate = previousPeriodUsers > 0
          ? ((totalUsers - previousPeriodUsers) / previousPeriodUsers * 100)
          : 0.0;
      return {
        'totalUsers': totalUsers,
        'newUsers': totalUsers,
        'growthRate': growthRate.toStringAsFixed(1),
        'dailyGrowth': dailyGrowth,
        'period': '30 days',
      };
    } catch (e) {
      Logger.error('Error getting user growth data: $e');
      rethrow;
    }
  }

  // دریافت داده‌های عملکرد آزمون‌ها
  static Future<Map<String, dynamic>> _getQuizPerformanceData() async {
    try {
      final snapshot = await _firestore.collection('quiz_results').get();
      final results = snapshot.docs.map((doc) => doc.data()).toList();
      if (results.isEmpty) {
        return {
          'totalQuizzes': 0,
          'averageScore': '0',
          'completionRate': '0',
          'scoreDistribution': {},
          'subjectPerformance': {},
        };
      }
      final totalQuizzes = results.length;
      final totalParticipants = results.fold(
          0, (total, quiz) => total + (quiz['participants'] as int? ?? 0));
      final averageScore = results.fold(
              0.0, (total, quiz) => total + (quiz['averageScore'] ?? 0.0)) /
          totalQuizzes;
      final completedQuizzes =
          results.where((quiz) => quiz['completed'] == true).length;
      final completionRate =
          totalQuizzes > 0 ? (completedQuizzes / totalQuizzes * 100) : 0.0;
      // توزیع نمرات
      final Map<String, int> scoreDistribution = {
        '0-20': 0,
        '21-40': 0,
        '41-60': 0,
        '61-80': 0,
        '81-100': 0,
      };
      for (var result in results) {
        final score = result['averageScore'] ?? 0;
        if (score <= 20) {
          scoreDistribution['0-20'] = (scoreDistribution['0-20'] ?? 0) + 1;
        } else if (score <= 40) {
          scoreDistribution['21-40'] = (scoreDistribution['21-40'] ?? 0) + 1;
        } else if (score <= 60) {
          scoreDistribution['41-60'] = (scoreDistribution['41-60'] ?? 0) + 1;
        } else if (score <= 80) {
          scoreDistribution['61-80'] = (scoreDistribution['61-80'] ?? 0) + 1;
        } else {
          scoreDistribution['81-100'] = (scoreDistribution['81-100'] ?? 0) + 1;
        }
      }
      // عملکرد بر اساس درس (فرضی)
      final Map<String, double> subjectPerformance = {
        'ریاضی': 75.5,
        'فیزیک': 68.2,
        'شیمی': 82.1,
        'زیست': 71.8,
      };
      return {
        'totalQuizzes': totalQuizzes,
        'averageScore': averageScore.toStringAsFixed(1),
        'completionRate': completionRate.toStringAsFixed(1),
        'totalParticipants': totalParticipants,
        'scoreDistribution': scoreDistribution,
        'subjectPerformance': subjectPerformance,
      };
    } catch (e) {
      Logger.error('Error getting quiz performance data: $e');
      rethrow;
    }
  }

  // دریافت آمار سوالات
  static Future<Map<String, dynamic>> _getQuestionStatsData() async {
    try {
      final snapshot = await _firestore.collection('questions').get();
      final questions =
          snapshot.docs.map((doc) => Question.fromMap(doc.data())).toList();
      final totalQuestions = questions.length;
      final pendingQuestions =
          questions.where((q) => q.status == 'pending').length;
      final approvedQuestions =
          questions.where((q) => q.status == 'approved').length;
      final rejectedQuestions =
          questions.where((q) => q.status == 'rejected').length;
      // آمار بر اساس دسته‌بندی (فرضی)
      final Map<String, int> categoryStats = {
        'ریاضی': 45,
        'فیزیک': 32,
        'شیمی': 28,
        'زیست': 38,
      };
      // آمار بر اساس سطح دشواری (فرضی)
      final Map<String, int> difficultyStats = {
        'آسان': 35,
        'متوسط': 68,
        'سخت': 40,
      };
      return {
        'totalQuestions': totalQuestions,
        'pendingQuestions': pendingQuestions,
        'approvedQuestions': approvedQuestions,
        'rejectedQuestions': rejectedQuestions,
        'approvalRate': totalQuestions > 0
            ? ((approvedQuestions / totalQuestions) * 100).toStringAsFixed(1)
            : '0',
        'categoryStats': categoryStats,
        'difficultyStats': difficultyStats,
      };
    } catch (e) {
      Logger.error('Error getting question stats data: $e');
      rethrow;
    }
  }

  // دریافت روندهای فعالیت
  static Future<Map<String, dynamic>> _getActivityTrendsData() async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('activities')
          .where('timestamp', isGreaterThanOrEqualTo: sevenDaysAgo)
          .get();
      final activities = snapshot.docs.map((doc) => doc.data()).toList();
      // گروه‌بندی بر اساس روز
      final Map<String, int> dailyActivity = {};
      for (var i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        dailyActivity[dateKey] = 0;
      }
      // گروه‌بندی بر اساس نوع فعالیت
      final Map<String, int> activityTypes = {};
      for (var activity in activities) {
        final timestamp = (activity['timestamp'] as Timestamp).toDate();
        final dateKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
        final type = activity['type'] ?? 'unknown';
        if (dailyActivity.containsKey(dateKey)) {
          dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
        }
        activityTypes[type] = (activityTypes[type] ?? 0) + 1;
      }
      // محاسبه ساعت‌های پربازدید
      final Map<int, int> hourlyActivity = {};
      for (var i = 0; i < 24; i++) {
        hourlyActivity[i] = 0;
      }
      for (var activity in activities) {
        final timestamp = (activity['timestamp'] as Timestamp).toDate();
        final hour = timestamp.hour;
        hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;
      }
      return {
        'totalActivities': activities.length,
        'dailyActivity': dailyActivity,
        'activityTypes': activityTypes,
        'hourlyActivity': hourlyActivity,
        'peakHours': _getPeakHours(hourlyActivity),
      };
    } catch (e) {
      Logger.error('Error getting activity trends data: $e');
      rethrow;
    }
  }

  // دریافت تحلیل عملکرد کاربر خاص
  static Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    try {
      final results = await Future.wait([
        _getUserQuizHistory(userId),
        _getUserPerformanceTrend(userId),
        _getUserStrengthsWeaknesses(userId),
      ]);
      return {
        'quizHistory': results[0],
        'performanceTrend': results[1],
        'strengthsWeaknesses': results[2],
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error getting user analytics: $e');
      rethrow;
    }
  }

  // دریافت تاریخچه آزمون‌های کاربر
  static Future<Map<String, dynamic>> _getUserQuizHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('quiz_results')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();
      final results = snapshot.docs.map((doc) => doc.data()).toList();
      return {
        'totalQuizzes': results.length,
        'recentQuizzes': results,
        'averageScore': results.isNotEmpty
            ? (results.fold(
                        0.0, (total, quiz) => total + (quiz['score'] ?? 0.0)) /
                    results.length)
                .toStringAsFixed(1)
            : '0',
        'bestScore': results.isNotEmpty
            ? results
                .map((q) => q['score'] ?? 0)
                .reduce((a, b) => a > b ? a : b)
            : 0,
        'improvementTrend': _calculateImprovementTrend(results),
      };
    } catch (e) {
      Logger.error('Error getting user quiz history: $e');
      rethrow;
    }
  }

  // دریافت روند عملکرد کاربر
  static Future<Map<String, dynamic>> _getUserPerformanceTrend(
      String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('quiz_results')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();
      final results = snapshot.docs.map((doc) => doc.data()).toList();
      // گروه‌بندی بر اساس هفته
      final Map<String, List<double>> weeklyScores = {};
      for (var i = 0; i < 4; i++) {
        final weekKey = 'هفته ${i + 1}';
        weeklyScores[weekKey] = [];
      }
      for (var result in results) {
        final timestamp = (result['timestamp'] as Timestamp).toDate();
        final score = result['score'] ?? 0.0;
        for (var i = 0; i < 4; i++) {
          final weekStart = thirtyDaysAgo.add(Duration(days: i * 7));
          final weekEnd = weekStart.add(const Duration(days: 7));
          final weekKey = 'هفته ${i + 1}';
          if (timestamp.isAfter(weekStart) && timestamp.isBefore(weekEnd)) {
            weeklyScores[weekKey]?.add(score);
            break;
          }
        }
      }
      // محاسبه میانگین هفتگی
      final Map<String, double> weeklyAverages = {};
      weeklyScores.forEach((key, scores) {
        weeklyAverages[key] = scores.isNotEmpty
            ? scores.reduce((a, b) => a + b) / scores.length
            : 0.0;
      });
      return {
        'weeklyScores': weeklyScores,
        'weeklyAverages': weeklyAverages,
        'trend': _calculateTrend(weeklyAverages.values.toList()),
      };
    } catch (e) {
      Logger.error('Error getting user performance trend: $e');
      rethrow;
    }
  }

  // دریافت نقاط قوت و ضعف کاربر
  static Future<Map<String, dynamic>> _getUserStrengthsWeaknesses(
      String userId) async {
    try {
      // تحلیل بر اساس درس (فرضی)
      final Map<String, List<double>> subjectScores = {
        'ریاضی': [],
        'فیزیک': [],
        'شیمی': [],
        'زیست': [],
      };
      // در اینجا باید منطق تحلیل بر اساس درس پیاده‌سازی شود
      // فعلاً داده‌های فرضی برمی‌گردانیم
      subjectScores['ریاضی'] = [85.0, 78.0, 92.0];
      subjectScores['فیزیک'] = [65.0, 72.0, 68.0];
      subjectScores['شیمی'] = [88.0, 85.0, 90.0];
      subjectScores['زیست'] = [75.0, 80.0, 73.0];
      final Map<String, double> subjectAverages = {};
      subjectScores.forEach((subject, scores) {
        subjectAverages[subject] = scores.isNotEmpty
            ? scores.reduce((a, b) => a + b) / scores.length
            : 0.0;
      });
      // شناسایی نقاط قوت و ضعف
      final strengths = <String>[];
      final weaknesses = <String>[];
      final averageScore =
          subjectAverages.values.fold(0.0, (total, score) => total + score) /
              subjectAverages.length;
      subjectAverages.forEach((subject, score) {
        if (score >= averageScore + 5) {
          strengths.add(subject);
        } else if (score <= averageScore - 5) {
          weaknesses.add(subject);
        }
      });
      return {
        'subjectAverages': subjectAverages,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'overallAverage': averageScore.toStringAsFixed(1),
      };
    } catch (e) {
      Logger.error('Error getting user strengths and weaknesses: $e');
      rethrow;
    }
  }

  // متدهای کمکی
  static List<int> _getPeakHours(Map<int, int> hourlyActivity) {
    final sortedHours = hourlyActivity.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedHours.take(3).map((e) => e.key).toList();
  }

  static String _calculateImprovementTrend(List<Map<String, dynamic>> results) {
    if (results.length < 2) return 'کافی نیست';
    final recent = results.take(3).map((r) => r['score'] ?? 0.0).toList();
    final earlier =
        results.skip(3).take(3).map((r) => r['score'] ?? 0.0).toList();
    if (recent.isEmpty || earlier.isEmpty) return 'نامشخص';
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final earlierAvg = earlier.reduce((a, b) => a + b) / earlier.length;
    final improvement = ((recentAvg - earlierAvg) / earlierAvg * 100);
    if (improvement > 5) return 'بهبود';
    if (improvement < -5) return 'کاهش';
    return 'پایدار';
  }

  static String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'نامشخص';
    double totalChange = 0;
    for (int i = 1; i < values.length; i++) {
      totalChange += values[i] - values[i - 1];
    }
    final avgChange = totalChange / (values.length - 1);
    if (avgChange > 2) return 'صعودی';
    if (avgChange < -2) return 'نزولی';
    return 'پایدار';
  }
}
