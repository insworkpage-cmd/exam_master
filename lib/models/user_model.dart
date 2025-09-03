import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shamsi_date/shamsi_date.dart';
import 'user_role.dart';

class UserModel extends Equatable {
  final String id;
  final String uid;
  final UserRole role;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;
  final String? phone;

  // فیلدهای جدید برای سیستم مدیریت ظرفیت پیشنهاد سوال
  final int questionProposalCapacity; // ← اضافه شد
  final DateTime? lastProposalDate; // ← اضافه شد
  final bool isProposalBlocked; // ← اضافه شد
  final DateTime? proposalBlockedAt; // ← اضافه شد
  final DateTime? proposalUnblockedAt; // ← اضافه شد

  const UserModel({
    required this.id,
    required this.uid,
    required this.role,
    required this.email,
    required this.name,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
    this.phone,
    // فیلدهای جدید با مقادیر پیش‌فرض
    this.questionProposalCapacity = 10, // ← اضافه شد
    this.lastProposalDate, // ← اضافه شد
    this.isProposalBlocked = false, // ← اضافه شد
    this.proposalBlockedAt, // ← اضافه شد
    this.proposalUnblockedAt, // ← اضافه شد
  });

  UserModel copyWith({
    String? id,
    String? uid,
    UserRole? role,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    String? phone,
    // فیلدهای جدید
    int? questionProposalCapacity, // ← اضافه شد
    DateTime? lastProposalDate, // ← اضافه شد
    bool? isProposalBlocked, // ← اضافه شد
    DateTime? proposalBlockedAt, // ← اضافه شد
    DateTime? proposalUnblockedAt, // ← اضافه شد
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      // فیلدهای جدید
      questionProposalCapacity: questionProposalCapacity ??
          this.questionProposalCapacity, // ← اضافه شد
      lastProposalDate: lastProposalDate ?? this.lastProposalDate, // ← اضافه شد
      isProposalBlocked:
          isProposalBlocked ?? this.isProposalBlocked, // ← اضافه شد
      proposalBlockedAt:
          proposalBlockedAt ?? this.proposalBlockedAt, // ← اضافه شد
      proposalUnblockedAt:
          proposalUnblockedAt ?? this.proposalUnblockedAt, // ← اضافه شد
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'role': role.name,
      'email': email,
      'name': name,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'isActive': isActive,
      'phone': phone,
      // فیلدهای جدید
      'questionProposalCapacity': questionProposalCapacity, // ← اضافه شد
      'lastProposalDate': lastProposalDate, // ← اضافه شد
      'isProposalBlocked': isProposalBlocked, // ← اضافه شد
      'proposalBlockedAt': proposalBlockedAt, // ← اضافه شد
      'proposalUnblockedAt': proposalUnblockedAt, // ← اضافه شد
    };
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == (map['role'] ?? 'normaluser'),
        orElse: () => UserRole.normaluser,
      ),
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      lastLogin: _parseDateTime(map['lastLogin']),
      isActive: map['isActive'] ?? true,
      phone: map['phone'],
      // فیلدهای جدید
      questionProposalCapacity:
          map['questionProposalCapacity'] ?? 10, // ← اضافه شد
      lastProposalDate: _parseDateTime(map['lastProposalDate']), // ← اضافه شد
      isProposalBlocked: map['isProposalBlocked'] ?? false, // ← اضافه شد
      proposalBlockedAt: _parseDateTime(map['proposalBlockedAt']), // ← اضافه شد
      proposalUnblockedAt:
          _parseDateTime(map['proposalUnblockedAt']), // ← اضافه شد
    );
  }

  // متد کمکی برای تبدیل Timestamp به DateTime
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return null;
  }

  // متدهای کمکی برای نمایش تاریخ به صورت شمسی
  String get persianCreatedAt {
    final jalili = Jalali.fromDateTime(createdAt);
    return '${jalili.year}/${jalili.month.toString().padLeft(2, '0')}/${jalili.day.toString().padLeft(2, '0')}';
  }

  String get persianLastLogin {
    if (lastLogin == null) return 'هرگز';
    final jalili = Jalali.fromDateTime(lastLogin!);
    return '${jalili.year}/${jalili.month.toString().padLeft(2, '0')}/${jalili.day.toString().padLeft(2, '0')}';
  }

  // متدهای کمکی برای نمایش تاریخ نسبی
  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    if (difference.inDays == 0) {
      return 'امروز';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} هفته پیش';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ماه پیش';
    } else {
      return '${(difference.inDays / 365).floor()} سال پیش';
    }
  }

  String get formattedLastLogin {
    if (lastLogin == null) return 'هرگز';
    final now = DateTime.now();
    final difference = now.difference(lastLogin!);
    if (difference.inDays == 0) {
      return 'امروز';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} هفته پیش';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ماه پیش';
    } else {
      return '${(difference.inDays / 365).floor()} سال پیش';
    }
  }

  // متدهای کمکی برای نمایش زمان
  String get createdAtTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get lastLoginTime {
    if (lastLogin == null) return '';
    return '${lastLogin!.hour.toString().padLeft(2, '0')}:${lastLogin!.minute.toString().padLeft(2, '0')}';
  }

  // متدهای کمکی برای بررسی سطح دسترسی
  bool hasAccess(UserRole requiredRole) {
    return role.index >= requiredRole.index;
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isModerator => role == UserRole.moderator;
  bool get isInstructor => role == UserRole.instructor;
  bool get isStudent => role == UserRole.student;
  bool get isNormalUser => role == UserRole.normaluser;

  // متد کمکی برای نمایش نام کامل
  String get displayName => name;

  // متد کمکی برای نمایش نقش به صورت متن
  String get roleText {
    switch (role) {
      case UserRole.admin:
        return 'ادمین';
      case UserRole.moderator:
        return 'ناظر';
      case UserRole.instructor:
        return 'استاد';
      case UserRole.student:
        return 'دانشجو';
      case UserRole.normaluser:
        return 'کاربر عادی';
      default:
        return 'ناشناخته';
    }
  }

  // متد کمکی برای نمایش وضعیت
  String get statusText => isActive ? 'فعال' : 'غیرفعال';

  // متد کمکی برای نمایش اطلاعات تماس
  String get contactInfo {
    if (phone != null && phone!.isNotEmpty) {
      return '$email - $phone';
    }
    return email;
  }

  // === متدهای جدید برای سیستم مدیریت ظرفیت پیشنهاد سوال ===

  // متد کمکی برای نمایش وضعیت پیشنهاد سوال
  String get proposalStatusText {
    // ← اضافه شد
    if (isProposalBlocked) {
      return 'مسدود شده';
    }
    if (questionProposalCapacity <= 0) {
      return 'ظرفیت تمام شده';
    }
    return 'فعال';
  }

  // متد کمکی برای نمایش رنگ وضعیت پیشنهاد سوال
  String get proposalStatusColor {
    // ← اضافه شد
    if (isProposalBlocked) {
      return 'red';
    }
    if (questionProposalCapacity <= 0) {
      return 'orange';
    }
    return 'green';
  }

  // متد کمکی برای نمایش متن ظرفیت
  String get capacityText {
    // ← اضافه شد
    return '$questionProposalCapacity از 10';
  }

  // متد کمکی برای بررسی آیا کاربر می‌تواند سوال پیشنهاد دهد
  bool get canProposeQuestion {
    // ← اضافه شد
    return !isProposalBlocked && questionProposalCapacity > 0;
  }

  // متد کمکی برای کاهش ظرفیت
  UserModel decreaseProposalCapacity() {
    // ← اضافه شد
    return copyWith(
      questionProposalCapacity: questionProposalCapacity - 1,
      lastProposalDate: DateTime.now(),
    );
  }

  // متد کمکی برای افزایش ظرفیت
  UserModel increaseProposalCapacity(int amount) {
    // ← اضافه شد
    return copyWith(
      questionProposalCapacity: questionProposalCapacity + amount,
    );
  }

  // متد کمکی برای مسدود کردن پیشنهاد سوال
  UserModel blockProposalService() {
    // ← اضافه شد
    return copyWith(
      isProposalBlocked: true,
      proposalBlockedAt: DateTime.now(),
    );
  }

  // متد کمکی برای رفع مسدودی پیشنهاد سوال
  UserModel unblockProposalService() {
    // ← اضافه شد
    return copyWith(
      isProposalBlocked: false,
      proposalUnblockedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        uid,
        role,
        email,
        name,
        createdAt,
        lastLogin,
        isActive,
        phone,
        // فیلدهای جدید
        questionProposalCapacity, // ← اضافه شد
        lastProposalDate, // ← اضافه شد
        isProposalBlocked, // ← اضافه شد
        proposalBlockedAt, // ← اضافه شد
        proposalUnblockedAt, // ← اضافه شد
      ];
}
