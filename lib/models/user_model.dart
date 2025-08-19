import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ← اضافه کردن import
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'role': role.name,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
      'phone': phone,
    };
  }

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
      // مدیریت صحیح Timestamp
      createdAt: _parseDateTime(map['createdAt']),
      lastLogin:
          map['lastLogin'] != null ? _parseDateTime(map['lastLogin']) : null,
      isActive: map['isActive'] ?? true,
      phone: map['phone'],
    );
  }

  // متد کمکی برای تبدیل Timestamp به DateTime
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
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
      ];
}
