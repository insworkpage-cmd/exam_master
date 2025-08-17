// lib/core/question_model.dart

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String? source;
  final String? explanation;
  final String? instructorId;
  final String status;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    this.source,
    this.explanation,
    this.instructorId,
    this.status = 'pending',
  });

  // اضافه کردن متد copyWith
  Question copyWith({
    String? id,
    String? text,
    List<String>? options,
    int? correctAnswerIndex,
    String? source,
    String? explanation,
    String? instructorId,
    String? status,
  }) {
    return Question(
      id: id ?? this.id,
      text: text ?? this.text,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      source: source ?? this.source,
      explanation: explanation ?? this.explanation,
      instructorId: instructorId ?? this.instructorId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'source': source,
      'explanation': explanation,
      'instructorId': instructorId,
      'status': status,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      source: map['source'],
      explanation: map['explanation'],
      instructorId: map['instructorId'],
      status: map['status'] ?? 'pending',
    );
  }

  // متدهای کمکی برای وضعیت
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  // متد کمکی برای تغییر وضعیت
  Question copyWithStatus(String newStatus) {
    return copyWith(status: newStatus);
  }
}
