import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final String id;
  final String uid;
  final String name;
  final String email;
  final DateTime joinedAt;
  final double score;

  const Student({
    required this.id,
    required this.uid,
    required this.name,
    required this.email,
    required this.joinedAt,
    this.score = 0.0,
  });

  Student copyWith({
    String? id,
    String? uid,
    String? name,
    String? email,
    DateTime? joinedAt,
    double? score,
  }) {
    return Student(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      joinedAt: joinedAt ?? this.joinedAt,
      score: score ?? this.score,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'name': name,
        'email': email,
        'joinedAt': joinedAt.toIso8601String(),
        'score': score,
      };

  factory Student.fromMap(Map<String, dynamic> map) {
    final rawDate = map['joinedAt'];
    DateTime parsedDate;

    try {
      parsedDate = DateTime.parse(rawDate ?? '');
    } catch (_) {
      parsedDate = DateTime(2000); // یا هر مقدار پیش‌فرض
    }

    return Student(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      joinedAt: parsedDate,
      score: (map['score'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() =>
      'Student(name: $name, email: $email, uid: $uid, id: $id, score: $score)';

  @override
  List<Object> get props => [id, uid, name, email, joinedAt, score];
}
