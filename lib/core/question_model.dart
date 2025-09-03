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
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? category;
  final int difficulty;
  final int? timeLimit;
  final List<String>? tags;

  // فیلدهای جدید برای نیازمندی‌های جدید
  final String? classId; // ← اضافه شد
  final String? proposedBy; // ← اضافه شد
  final String? reviewedBy; // ← اضافه شد
  final DateTime? reviewDate; // ← اضافه شد
  final String? reviewComment; // ← اضافه شد

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    this.source,
    this.explanation,
    this.instructorId,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.category,
    this.difficulty = 1,
    this.timeLimit,
    this.tags,
    // فیلدهای جدید
    this.classId, // ← اضافه شد
    this.proposedBy, // ← اضافه شد
    this.reviewedBy, // ← اضافه شد
    this.reviewDate, // ← اضافه شد
    this.reviewComment, // ← اضافه شد
  });

  // متد copyWith کامل‌تر با فیلدهای جدید
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
    // فیلدهای جدید
    String? classId, // ← اضافه شد
    String? proposedBy, // ← اضافه شد
    String? reviewedBy, // ← اضافه شد
    DateTime? reviewDate, // ← اضافه شد
    String? reviewComment, // ← اضافه شد
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
      // فیلدهای جدید
      classId: classId ?? this.classId, // ← اضافه شد
      proposedBy: proposedBy ?? this.proposedBy, // ← اضافه شد
      reviewedBy: reviewedBy ?? this.reviewedBy, // ← اضافه شد
      reviewDate: reviewDate ?? this.reviewDate, // ← اضافه شد
      reviewComment: reviewComment ?? this.reviewComment, // ← اضافه شد
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'category': category,
      'difficulty': difficulty,
      'timeLimit': timeLimit,
      'tags': tags ?? [],
      // فیلدهای جدید
      'classId': classId, // ← اضافه شد
      'proposedBy': proposedBy, // ← اضافه شد
      'reviewedBy': reviewedBy, // ← اضافه شد
      'reviewDate': reviewDate?.toIso8601String(), // ← اضافه شد
      'reviewComment': reviewComment, // ← اضافه شد
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
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      category: map['category'],
      difficulty: map['difficulty'] ?? 1,
      timeLimit: map['timeLimit'],
      tags: List<String>.from(map['tags'] ?? []),
      // فیلدهای جدید
      classId: map['classId'], // ← اضافه شد
      proposedBy: map['proposedBy'], // ← اضافه شد
      reviewedBy: map['reviewedBy'], // ← اضافه شد
      reviewDate: map['reviewDate'] != null
          ? DateTime.tryParse(map['reviewDate'])
          : null, // ← اضافه شد
      reviewComment: map['reviewComment'], // ← اضافه شد
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
      updatedAt: DateTime.now(),
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
      id: const Uuid().v4(),
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
      // فیلدهای جدید
      classId: classId, // ← اضافه شد
      proposedBy: proposedBy, // ← اضافه شد
      reviewedBy: null, // ← ریست شود
      reviewDate: null, // ← ریست شود
      reviewComment: null, // ← ریست شود
    );
  }

  // === متدهای جدید برای نیازمندی‌های جدید ===

  // متدهای کمکی برای نوع سوال
  bool get isClassQuestion => classId != null; // ← اضافه شد
  bool get isPublicQuestion => classId == null; // ← اضافه شد

  // متدهای کمکی برای پیشنهاد سوال
  bool get isProposedByUser => proposedBy != null; // ← اضافه شد
  bool get isCreatedByInstructor => instructorId != null; // ← اضافه شد

  // متد کمکی برای بررسی نیاز به تایید
  bool get needsApproval => isPublicQuestion && isPending; // ← اضافه شد

  // متد کمکی برای بررسی قابلیت نمایش عمومی
  bool get isPubliclyVisible =>
      isApproved || (isClassQuestion && instructorId != null); // ← اضافه شد

  // متد کمکی برای بررسی دسترسی ویرایش
  bool canBeEditedBy(String userId, String userRole) {
    // ← اضافه شد
    if (userRole == 'admin') return true;
    if (userRole == 'moderator' && isPending) return true;
    if (isClassQuestion && instructorId == userId) return true;
    if (isProposedByUser && proposedBy == userId && isPending) return true;
    return false;
  }

  // متد کمکی برای بررسی دسترسی حذف
  bool canBeDeletedBy(String userId, String userRole) {
    // ← اضافه شد
    if (userRole == 'admin') return true;
    if (isClassQuestion && instructorId == userId) return true;
    if (isProposedByUser && proposedBy == userId && isPending) return true;
    return false;
  }

  // متد کمکی برای تایید سوال
  Question approve(String moderatorId, {String? comment}) {
    // ← اضافه شد
    return copyWith(
      status: 'approved',
      reviewedBy: moderatorId,
      reviewDate: DateTime.now(),
      reviewComment: comment,
      updatedAt: DateTime.now(),
    );
  }

  // متد کمکی برای رد سوال
  Question reject(String moderatorId, String comment) {
    // ← اضافه شد
    return copyWith(
      status: 'rejected',
      reviewedBy: moderatorId,
      reviewDate: DateTime.now(),
      reviewComment: comment,
      updatedAt: DateTime.now(),
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
