import 'student_model.dart';

class ClassModel {
  final String id;
  final String name;
  final String? description;
  final String code;
  final String instructorId;
  final List<Student> students;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? schedule;
  final bool isActive;
  final List<String>? tags;
  final int? maxCapacity;
  final String? imageUrl;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
    required this.code,
    required this.instructorId,
    required this.students,
    required this.createdAt,
    this.updatedAt,
    this.schedule,
    this.isActive = true,
    this.tags,
    this.maxCapacity,
    this.imageUrl,
  });

  ClassModel copyWith({
    String? id,
    String? name,
    String? description,
    String? code,
    String? instructorId,
    List<Student>? students,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? schedule,
    bool? isActive,
    List<String>? tags,
    int? maxCapacity,
    String? imageUrl,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      code: code ?? this.code,
      instructorId: instructorId ?? this.instructorId,
      students: students ?? this.students,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'code': code,
      'instructorId': instructorId,
      'students': students.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'schedule': schedule,
      'isActive': isActive,
      'tags': tags,
      'maxCapacity': maxCapacity,
      'imageUrl': imageUrl,
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      code: map['code'] ?? '',
      instructorId: map['instructorId'] ?? '',
      students: (map['students'] as List<dynamic>? ?? [])
          .map((s) => Student.fromMap(s))
          .toList(),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt:
          map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt']) : null,
      schedule: map['schedule'],
      isActive: map['isActive'] ?? true,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      maxCapacity: map['maxCapacity'],
      imageUrl: map['imageUrl'],
    );
  }

  @override
  String toString() => 'کلاس: $name ($code)';
}
