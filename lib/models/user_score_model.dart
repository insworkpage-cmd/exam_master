// lib/models/user_score_model.dart
import 'package:equatable/equatable.dart';

class UserScoreModel extends Equatable {
  final String userId;
  final int totalScore;
  final int level;
  final int xp;
  final List<Achievement> achievements;
  final int rank;

  const UserScoreModel({
    required this.userId,
    required this.totalScore,
    required this.level,
    required this.xp,
    required this.achievements,
    required this.rank,
  });

  UserScoreModel copyWith({
    String? userId,
    int? totalScore,
    int? level,
    int? xp,
    List<Achievement>? achievements,
    int? rank,
  }) {
    return UserScoreModel(
      userId: userId ?? this.userId,
      totalScore: totalScore ?? this.totalScore,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      achievements: achievements ?? this.achievements,
      rank: rank ?? this.rank,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalScore': totalScore,
      'level': level,
      'xp': xp,
      'achievements': achievements.map((a) => a.toMap()).toList(),
      'rank': rank,
    };
  }

  factory UserScoreModel.fromMap(Map<String, dynamic> map) {
    return UserScoreModel(
      userId: map['userId'] ?? '',
      totalScore: map['totalScore'] ?? 0,
      level: map['level'] ?? 1,
      xp: map['xp'] ?? 0,
      achievements: (map['achievements'] as List<dynamic>? ?? [])
          .map((a) => Achievement.fromMap(a))
          .toList(),
      rank: map['rank'] ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [userId, totalScore, level, xp, achievements, rank];
}

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'unlockedAt': unlockedAt.toIso8601String(),
    };
  }

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      unlockedAt:
          DateTime.parse(map['unlockedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [id, title, description, icon, unlockedAt];
}
