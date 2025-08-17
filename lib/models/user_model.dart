import 'package:equatable/equatable.dart';
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

  const UserModel({
    required this.id,
    required this.uid,
    required this.role,
    required this.email,
    required this.name,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
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
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == (map['role'] ?? 'guest'),
        orElse: () => UserRole.guest,
      ),
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      lastLogin:
          map['lastLogin'] != null ? DateTime.tryParse(map['lastLogin']) : null,
      isActive: map['isActive'] ?? true,
    );
  }

  @override
  @override
  List<Object?> get props =>
      [id, uid, role, email, name, createdAt, lastLogin, isActive];
}
