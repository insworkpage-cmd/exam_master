import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/instructor_class_model.dart' as instructor_class_model;
import '../../providers/class_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;

class CreateClassPage extends StatefulWidget {
  final instructor_class_model.InstructorClass? classItem;

  const CreateClassPage({super.key, this.classItem});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _maxCapacityController = TextEditingController();
  final _tagsController = TextEditingController();

  bool _isLoading = false;
  bool _isActive = true;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    // اگر در حال ویرایش کلاس هستیم، فیلدها را پر می‌کنیم
    if (widget.classItem != null) {
      _nameController.text = widget.classItem!.name;
      _descriptionController.text = widget.classItem!.description ?? '';
      _scheduleController.text = widget.classItem!.schedule ?? '';
      _maxCapacityController.text =
          widget.classItem!.maxCapacity?.toString() ?? '';
      _tags = List<String>.from(widget.classItem!.tags ?? []);
      _isActive = widget.classItem!.isActive;
      _updateTagsText();
    }
  }

  void _updateTagsText() {
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scheduleController.dispose();
    _maxCapacityController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final classProvider = Provider.of<ClassProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      // پردازش تگ‌ها
      final tagsText = _tagsController.text.trim();
      if (tagsText.isNotEmpty) {
        _tags = tagsText.split(',').map((tag) => tag.trim()).toList();
      }

      // پردازش ظرفیت
      int? maxCapacity;
      if (_maxCapacityController.text.trim().isNotEmpty) {
        maxCapacity = int.tryParse(_maxCapacityController.text.trim());
      }

      if (widget.classItem == null) {
        // ایجاد کلاس جدید
        await classProvider.createClass(
          name: _nameController.text.trim(),
          instructorId: authProvider.currentUser!.uid,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          schedule: _scheduleController.text.trim().isNotEmpty
              ? _scheduleController.text.trim()
              : null,
          maxCapacity: maxCapacity,
          tags: _tags.isNotEmpty ? _tags : null,
          isActive: _isActive,
        );
      } else {
        // ویرایش کلاس موجود
        final updatedClass = widget.classItem!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          schedule: _scheduleController.text.trim().isNotEmpty
              ? _scheduleController.text.trim()
              : null,
          maxCapacity: maxCapacity,
          tags: _tags.isNotEmpty ? _tags : null,
          isActive: _isActive,
        );

        await classProvider.updateClass(updatedClass);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.classItem == null
                ? 'کلاس با موفقیت ایجاد شد'
                : 'کلاس با موفقیت ویرایش شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.classItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش کلاس' : 'ایجاد کلاس جدید'),
        backgroundColor: Colors.blue[700],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // نام کلاس
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'نام کلاس *',
                  hintText: 'مثال: ریاضی پیشرفته',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'لطفاً نام کلاس را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // توضیحات
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'توضیحات',
                  hintText: 'توضیحات مربوط به کلاس (اختیاری)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // زمان‌بندی
              TextFormField(
                controller: _scheduleController,
                decoration: const InputDecoration(
                  labelText: 'زمان‌بندی',
                  hintText: 'مثال: شنبه‌ها ۱۰-۱۲',
                  prefixIcon: Icon(Icons.schedule),
                ),
              ),
              const SizedBox(height: 16),

              // ظرفیت کلاس
              TextFormField(
                controller: _maxCapacityController,
                decoration: const InputDecoration(
                  labelText: 'ظرفیت کلاس',
                  hintText: 'حداکثر تعداد دانشجویان (اختیاری)',
                  prefixIcon: Icon(Icons.group),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // تگ‌ها
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'تگ‌ها',
                  hintText: 'مثال: ریاضی, پایه, پیشرفته (با کاما جدا کنید)',
                  prefixIcon: Icon(Icons.tag),
                ),
                onChanged: (value) {
                  // پردازش تگ‌ها در زمان تغییر
                  if (value.trim().isEmpty) {
                    _tags = [];
                  } else {
                    _tags = value.split(',').map((tag) => tag.trim()).toList();
                  }
                },
              ),
              const SizedBox(height: 16),

              // وضعیت فعال
              SwitchListTile(
                  title: const Text('کلاس فعال'),
                  subtitle: const Text(
                      'اگر غیرفعال باشد، دانشجویان جدید نمی‌توانند عضو شوند'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  secondary: const Icon(Icons.check_circle)),
              const SizedBox(height: 32),

              // دکمه ذخیره
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditing ? 'ذخیره تغییرات' : 'ایجاد کلاس',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
