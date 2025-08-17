import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../instructor/class_detail_page.dart';
import '../../models/instructor_class_model.dart' as instructor_class_model;

class InstructorClassListPage extends StatefulWidget {
  const InstructorClassListPage({super.key});

  @override
  State<InstructorClassListPage> createState() =>
      _InstructorClassListPageState();
}

class _InstructorClassListPageState extends State<InstructorClassListPage> {
  final List<instructor_class_model.InstructorClass> _classes = [];

  void _createNewClass() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ایجاد کلاس جدید'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'نام کلاس'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx, name);
              }
            },
            child: const Text('ایجاد'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _classes.add(instructor_class_model.InstructorClass(
          id: const Uuid().v4(),
          name: result,
          code: _generateClassCode(),
          instructorId: 'instructor-id-temp',
          students: [],
          createdAt: DateTime.now(),
        ));
      });
    }
  }

  String _generateClassCode() {
    final uuid = const Uuid().v4();
    return uuid.substring(0, 6).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('کلاس‌های من'),
          // در بخش actions اپبار
          actions: [
            IconButton(
              onPressed: _createNewClass,
              icon: const Icon(Icons.add),
              tooltip: 'ایجاد کلاس جدید',
            ),
            IconButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/question-management'),
              icon: const Icon(Icons.question_answer),
              tooltip: 'مدیریت سوالات',
            ),
          ],
        ),
        body: _classes.isEmpty
            ? const Center(child: Text('هنوز کلاسی ایجاد نکرده‌اید.'))
            : ListView.builder(
                itemCount: _classes.length,
                itemBuilder: (ctx, i) {
                  final c = _classes[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.class_),
                      title: Text(c.name),
                      subtitle: Text('کد کلاس: ${c.code}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClassDetailPage(
                              instructorClass: c,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
