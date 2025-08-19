import 'package:uuid/uuid.dart';

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String? source;
  final String? explanation;
  final String? instructorId;
  final String status;
  final DateTime createdAt; // ← اضافه شد
  final DateTime? updatedAt; // ← اضافه شد
  final String? category; // ← اضافه شد
  final int difficulty; // ← اضافه شد
  final int? timeLimit; // ← اضافه شد
  final List<String>? tags; // ← اضافه شد

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    this.source,
    this.explanation,
    this.instructorId,
    this.status = 'pending',
    required this.createdAt, // ← الزامی شد
    this.updatedAt, // ← اضافه شد
    this.category, // ← اضافه شد
    this.difficulty = 1, // ← اضافه شد با مقدار پیش‌فرض
    this.timeLimit, // ← اضافه شد
    this.tags, // ← اضافه شد
  });

  // متد copyWith کامل‌تر
  Question copyWith({
    String? id,
    String? text,
    List<String>? options,
    int? correctAnswerIndex,
    String? source,
    String? explanation,
    String? instructorId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    int? difficulty,
    int? timeLimit,
    List<String>? tags,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      timeLimit: timeLimit ?? this.timeLimit,
      tags: tags ?? this.tags,
    );
  }

  // تبدیل به Map برای ذخیره در Firestore
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
      'createdAt': createdAt.toIso8601String(), // ← تبدیل به رشته
      'updatedAt': updatedAt?.toIso8601String(), // ← تبدیل به رشته
      'category': category,
      'difficulty': difficulty,
      'timeLimit': timeLimit,
      'tags': tags ?? [],
    };
  }

  // ساخت از Map برای خواندن از Firestore
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
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ??
          DateTime.now(), // ← مدیریت خطا
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null, // ← مدیریت خطا
      category: map['category'],
      difficulty: map['difficulty'] ?? 1,
      timeLimit: map['timeLimit'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // متدهای کمکی برای وضعیت
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  // متد کمکی برای تغییر وضعیت
  Question copyWithStatus(String newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(), // ← به‌روزرسانی زمان تغییر
    );
  }

  // متدهای کمکی برای سطح دشواری
  bool get isEasy => difficulty == 1;
  bool get isMedium => difficulty == 2;
  bool get isHard => difficulty == 3;

  // متد کمکی برای تغییر سطح دشواری
  Question copyWithDifficulty(int newDifficulty) {
    return copyWith(
      difficulty: newDifficulty,
      updatedAt: DateTime.now(),
    );
  }

  // متد کمکی برای افزودن تگ
  Question copyWithAddedTag(String tag) {
    final newTags = List<String>.from(tags ?? []);
    if (!newTags.contains(tag)) {
      newTags.add(tag);
    }
    return copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }

  // متد کمکی برای حذف تگ
  Question copyWithRemovedTag(String tag) {
    final newTags = List<String>.from(tags ?? []);
    newTags.remove(tag);
    return copyWith(
      tags: newTags,
      updatedAt: DateTime.now(),
    );
  }

  // متد کمکی برای بررسی صحت سوال
  bool get isValid {
    return text.trim().isNotEmpty &&
        options.length >= 2 && // حداقل 2 گزینه
        options.length <= 6 && // حداکثر 6 گزینه
        correctAnswerIndex >= 0 &&
        correctAnswerIndex < options.length &&
        options.every((option) => option.trim().isNotEmpty);
  }

  // متد کمکی برای دریافت گزینه صحیح
  String get correctOption {
    if (correctAnswerIndex >= 0 && correctAnswerIndex < options.length) {
      return options[correctAnswerIndex];
    }
    return '';
  }

  // متد کمکی برای دریافت همه گزینه‌ها به صورت فرمت‌شده
  List<Map<String, dynamic>> get formattedOptions {
    return options.asMap().entries.map((entry) {
      return {
        'index': entry.key,
        'text': entry.value,
        'isCorrect': entry.key == correctAnswerIndex,
      };
    }).toList();
  }

  // متد کمکی برای نمایش خلاصه سوال
  String get summary {
    if (text.length <= 50) return text;
    return '${text.substring(0, 47)}...';
  }

  // متد کمکی برای محاسبه درصد پیشرفت (مثلاً برای آزمون)
  double getProgressPercentage(int selectedAnswerIndex) {
    if (selectedAnswerIndex == correctAnswerIndex) return 100.0;
    return 0.0;
  }

  // متد کمکی برای مقایسه با سوال دیگر
  bool isSameAs(Question other) {
    return id == other.id;
  }

  // متد کمکی برای کلون کردن سوال
  Question clone() {
    return Question(
      id: const Uuid().v4(), // ← نیاز به import 'package:uuid/uuid.dart'
      text: text,
      options: List<String>.from(options),
      correctAnswerIndex: correctAnswerIndex,
      source: source,
      explanation: explanation,
      instructorId: instructorId,
      status: 'pending',
      createdAt: DateTime.now(),
      category: category,
      difficulty: difficulty,
      timeLimit: timeLimit,
      tags: tags,
    );
  }

  @override
  String toString() {
    return 'Question(id: $id, text: $summary, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
