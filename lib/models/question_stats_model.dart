// در lib/models/question_stats_model.dart
class QuestionStats {
  final int total;
  final int pending;
  final int approved;
  final int rejected;

  const QuestionStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
  });

  factory QuestionStats.fromMap(Map<String, dynamic> map) {
    return QuestionStats(
      total: map['total'] ?? 0,
      pending: map['pending'] ?? 0,
      approved: map['approved'] ?? 0,
      rejected: map['rejected'] ?? 0,
    );
  }

  QuestionStats copyWith({
    int? total,
    int? pending,
    int? approved,
    int? rejected,
  }) {
    return QuestionStats(
      total: total ?? this.total,
      pending: pending ?? this.pending,
      approved: approved ?? this.approved,
      rejected: rejected ?? this.rejected,
    );
  }
}
