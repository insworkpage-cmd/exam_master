import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/instructor_class_model.dart' as instructor_class_model;
import '../models/student_model.dart';

class ClassProvider with ChangeNotifier {
  final List<instructor_class_model.InstructorClass> _classes = [];
  bool _isLoading = false;
  bool _hasLoaded = false; // اضافه کردن پرچم برای بررسی بارگذاری اولیه
  String? _errorMessage;

  // Getters
  List<instructor_class_model.InstructorClass> get classes => _classes;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // دریافت کلاس‌های استاد از Firestore
  Future<void> fetchInstructorClasses(String instructorId,
      {bool forceRefresh = false}) async {
    // اگر قبلاً بارگذاری شده و forceRefresh نباشه، دوباره بارگذاری نکن
    if (_hasLoaded && !forceRefresh && _classes.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .where('instructorId', isEqualTo: instructorId)
          .orderBy('createdAt', descending: true)
          .get();

      _classes.clear();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // مدیریت بهتر Timestamp
        DateTime createdAt;
        try {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        } catch (e) {
          createdAt = DateTime.now();
          debugPrint('Error parsing createdAt: $e');
        }

        // مدیریت بهتر لیست دانشجویان
        List<Student> students = [];
        try {
          students = (data['students'] as List<dynamic>?)
                  ?.map((s) => Student.fromMap(s as Map<String, dynamic>))
                  .toList() ??
              [];
        } catch (e) {
          debugPrint('Error parsing students: $e');
        }

        _classes.add(instructor_class_model.InstructorClass(
          id: doc.id,
          name: data['name'] ?? '',
          code: data['code'] ?? '',
          instructorId: data['instructorId'] ?? '',
          description: data['description'],
          students: students,
          createdAt: createdAt,
        ));
      }

      _hasLoaded = true;
      debugPrint('Successfully loaded ${_classes.length} classes');
    } catch (e) {
      _errorMessage = 'خطا در دریافت کلاس‌ها: ${e.toString()}';
      debugPrint(_errorMessage);
      // اگر خطا رخ داد، پرچم رو هم تنظیم می‌کنیم تا از تلاش‌های بی‌نتیجه جلوگیری بشه
      _hasLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ایجاد کلاس جدید
  Future<void> createClass({
    required String name,
    required String instructorId,
    String? description,
    String? schedule,
    int? maxCapacity,
    List<String>? tags,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final classCode = _generateClassCode();
      final newClassData = {
        'name': name,
        'code': classCode,
        'instructorId': instructorId,
        'description': description,
        'schedule': schedule,
        'maxCapacity': maxCapacity,
        'tags': tags,
        'isActive': isActive ?? true,
        'students': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('classes').add(newClassData);

      final newClass = instructor_class_model.InstructorClass(
        id: docRef.id,
        name: name,
        code: classCode,
        instructorId: instructorId,
        description: description,
        schedule: schedule,
        maxCapacity: maxCapacity,
        tags: tags,
        isActive: isActive ?? true,
        students: [],
        createdAt: DateTime.now(),
      );

      _classes.add(newClass);
      debugPrint('Successfully created class: $name');
    } catch (e) {
      _errorMessage = 'خطا در ایجاد کلاس: ${e.toString()}';
      debugPrint(_errorMessage);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // به‌روزرسانی کلاس
  Future<void> updateClass(
      instructor_class_model.InstructorClass classModel) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore.collection('classes').doc(classModel.id).update({
        'name': classModel.name,
        'description': classModel.description,
        'schedule': classModel.schedule,
        'maxCapacity': classModel.maxCapacity,
        'tags': classModel.tags,
        'isActive': classModel.isActive,
      });

      final index = _classes.indexWhere((c) => c.id == classModel.id);
      if (index != -1) {
        _classes[index] = classModel;
        debugPrint('Successfully updated class: ${classModel.name}');
      }
    } catch (e) {
      _errorMessage = 'خطا در به‌روزرسانی کلاس: ${e.toString()}';
      debugPrint(_errorMessage);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // حذف کلاس
  Future<void> deleteClass(String classId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firestore.collection('classes').doc(classId).delete();
      _classes.removeWhere((c) => c.id == classId);
      debugPrint('Successfully deleted class with ID: $classId');
    } catch (e) {
      _errorMessage = 'خطا در حذف کلاس: ${e.toString()}';
      debugPrint(_errorMessage);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // تولید کد کلاس تصادفی
  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = StringBuffer();
    for (var i = 0; i < 6; i++) {
      code.write(chars[random % chars.length]);
    }
    return code.toString();
  }

  // پاک کردن خطاها
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ریست کردن وضعیت برای خروج از حساب کاربری
  void reset() {
    _classes.clear();
    _isLoading = false;
    _hasLoaded = false;
    _errorMessage = null;
    notifyListeners();
  }
}
