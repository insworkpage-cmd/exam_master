// lib/services/gamification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_score_model.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'user_scores';

  // دریافت امتیازات کاربر
  Future<UserScoreModel?> getUserScore(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      return UserScoreModel.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  // به‌روزرسانی امتیاز کاربر پس از آزمون
  Future<void> updateScore(String userId, int quizScore) async {
    final userScore = await getUserScore(userId);
    if (userScore == null) {
      // ایجاد امتیازات جدید برای کاربر
      final newUserScore = UserScoreModel(
        userId: userId,
        totalScore: quizScore,
        level: _calculateLevel(quizScore),
        xp: quizScore,
        achievements: const [],
        rank: 0,
      );
      await _firestore
          .collection(_collection)
          .doc(userId)
          .set(newUserScore.toMap());
    } else {
      // به‌روزرسانی امتیازات موجود
      final newTotalScore = userScore.totalScore + quizScore;
      final newXp = userScore.xp + quizScore;
      final newLevel = _calculateLevel(newXp);
      final updatedScore = userScore.copyWith(
        totalScore: newTotalScore,
        xp: newXp,
        level: newLevel,
      );
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update(updatedScore.toMap());
    }
  }

  // محاسبه سطح بر اساس XP
  int _calculateLevel(int xp) {
    return (xp / 100).floor() + 1;
  }

  // دریافت جدول امتیازات برتر
  Future<List<UserScoreModel>> getLeaderboard() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('totalScore', descending: true)
          .limit(10)
          .get();
      return snapshot.docs
          .map((doc) => UserScoreModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // بررسی و اعطای دستاوردها
  Future<void> checkAndAwardAchievements(String userId) async {
    // پیاده‌سازی منطق اعطای دستاوردها
  }
}
