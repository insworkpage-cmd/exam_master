// lib/screens/instructor/class_detail_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

// جلوگیری از تداخل نام مدل‌ها

import 'package:exam_master/models/instructor_class_model.dart'
    as instructor_class_model;
import 'package:exam_master/models/student_model.dart';

class ClassDetailPage extends StatefulWidget {
  final instructor_class_model.InstructorClass instructorClass;

  const ClassDetailPage({super.key, required this.instructorClass});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  late instructor_class_model.InstructorClass _class;
  List<Student> _filteredStudents = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSortedByName = true;

  @override
  void initState() {
    super.initState();
    _class = widget.instructorClass;
    _filteredStudents = List.from(_class.students);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List.from(_class.students);
      } else {
        _filteredStudents = _class.students.where((s) {
          return s.name.toLowerCase().contains(query) ||
              s.uid.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _sortStudents() {
    setState(() {
      _isSortedByName = !_isSortedByName;
      _filteredStudents.sort((a, b) => _isSortedByName
          ? a.name.compareTo(b.name)
          : b.name.compareTo(a.name));
    });
  }

  Future<void> _renameClass() async {
    final controller = TextEditingController(text: _class.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش نام کلاس'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'نام جدید'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) Navigator.pop(ctx, newName);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _class = _class.copyWith(name: result);
      });
    }
  }

  Future<void> _editStudent(Student student, int index) async {
    final nameController = TextEditingController(text: student.name);
    final uidController = TextEditingController(text: student.uid);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش دانش‌آموز'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'نام'),
            ),
            TextField(
              controller: uidController,
              decoration: const InputDecoration(labelText: 'UID'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('لغو')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    if (result == true) {
      final updatedStudent = student.copyWith(
        name: nameController.text.trim(),
        uid: uidController.text.trim(),
      );
      setState(() {
        final students = List<Student>.from(_class.students);
        students[index] = updatedStudent;
        _class = _class.copyWith(students: students);
        _filteredStudents = List.from(students);
      });
    }
  }

  Future<void> _confirmRemoveStudent(int index) async {
    final student = _class.students[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: Text('آیا از حذف "${student.name}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) _removeStudent(index);
  }

  void _removeStudent(int index) {
    setState(() {
      final students = List<Student>.from(_class.students)..removeAt(index);
      _class = _class.copyWith(students: students);
      _filteredStudents = List.from(students);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('دانش‌آموز حذف شد')),
    );
  }

  Future<void> _exportExcel() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Students'];
      sheet.appendRow(['Name', 'UID']);
      for (final s in _class.students) {
        sheet.appendRow([s.name, s.uid]);
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = _class.name.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final file = File('${dir.path}/${safeName}_students.xlsx');
      await file.writeAsBytes(excel.encode()!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel ذخیره شد: ${file.path}')),
      );
    } catch (e) {
      _showError('خطا در ذخیره Excel: $e');
    }
  }

  Future<void> _exportPDF() async {
    try {
      final font = pw.Font.ttf(
          await rootBundle.load('lib/assets/fonts/Vazirmatn-Regular.ttf'));

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('کلاس: ${_class.name}',
                    style: pw.TextStyle(font: font, fontSize: 22)),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headers: ['نام دانش‌آموز', 'شماره دانشجویی'],
                  data: _class.students.map((s) => [s.name, s.uid]).toList(),
                  headerStyle: pw.TextStyle(font: font, fontSize: 14),
                  cellStyle: pw.TextStyle(font: font, fontSize: 12),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerRight,
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(1),
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      _showError('خطا در خروجی PDF: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _class.name,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'تغییر نام کلاس',
              onPressed: _renameClass),
          IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'خروجی PDF',
              onPressed: _exportPDF),
          IconButton(
              icon: const Icon(Icons.grid_on),
              tooltip: 'خروجی Excel',
              onPressed: _exportExcel),
          IconButton(
              icon: const Icon(Icons.sort_by_alpha),
              tooltip: 'مرتب‌سازی',
              onPressed: _sortStudents),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'جستجوی دانش‌آموز...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredStudents.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final student = _filteredStudents[index];
                final realIndex = _class.students.indexOf(student);

                return ListTile(
                  title: Text(student.name,
                      style: TextStyle(
                          color: isDark ? Colors.white : Colors.black)),
                  subtitle: Text(
                    student.uid,
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editStudent(student, realIndex),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmRemoveStudent(realIndex),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
