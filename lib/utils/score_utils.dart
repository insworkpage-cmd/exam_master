int calculateScore({
  required int correctAnswers,
  required int totalQuestions,
  required int secondsTaken,
}) {
  if (correctAnswers == 0 || totalQuestions == 0) return 0;
  double accuracy = correctAnswers / totalQuestions;
  double speedBonus = (300 / (secondsTaken + 1)).clamp(0.5, 2.0); // max 2x
  return (accuracy * 100 * speedBonus).toInt();
}

String getUserLevel(int score) {
  if (score >= 250) return 'طلایی';
  if (score >= 120) return 'نقره‌ای';
  return 'برنزی';
}
