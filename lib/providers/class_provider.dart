import 'package:flutter/material.dart';
import '../models/class_model.dart';

class ClassProvider with ChangeNotifier {
  final List<ClassModel> _classes = [];

  List<ClassModel> get classes => _classes;

  void addClass(ClassModel classModel) {
    _classes.add(classModel);
    notifyListeners();
  }

  void updateClass(ClassModel classModel) {
    final index = _classes.indexWhere((c) => c.id == classModel.id);
    if (index != -1) {
      _classes[index] = classModel;
      notifyListeners();
    }
  }

  void removeClass(String id) {
    _classes.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  ClassModel? getClassById(String id) {
    try {
      return _classes.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }
}
