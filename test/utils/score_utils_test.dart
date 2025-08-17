import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Score Calculation', () {
    test('returns correct score based on correct answers and time', () {
      final score = calculateScore(
        correctAnswers: 8,
        totalQuestions: 10,
        secondsTaken: 120,
      );

      expect(score, greaterThan(0));
    });

    test('returns 0 score if no correct answers', () {
      final score = calculateScore(
        correctAnswers: 0,
        totalQuestions: 10,
        secondsTaken: 60,
      );

      expect(score, equals(0));
    });
  });

  group('User Level', () {
    test('Bronze level for low scores', () {
      expect(getUserLevel(50), equals('برنزی'));
    });

    test('Silver level for mid scores', () {
      expect(getUserLevel(150), equals('نقره‌ای'));
    });

    test('Gold level for high scores', () {
      expect(getUserLevel(300), equals('طلایی'));
    });
  });
}

int calculateScore({
  required int correctAnswers,
  required int totalQuestions,
  required int secondsTaken,
}) {
  if (correctAnswers == 0 || totalQuestions == 0) return 0;
  double accuracy = correctAnswers / totalQuestions;
  double speedBonus = (300 / (secondsTaken + 1)).clamp(0.5, 2.0); // max: 2x
  return (accuracy * 100 * speedBonus).toInt();
}

String getUserLevel(int score) {
  if (score >= 250) return 'طلایی';
  if (score >= 120) return 'نقره‌ای';
  return 'برنزی';
}
