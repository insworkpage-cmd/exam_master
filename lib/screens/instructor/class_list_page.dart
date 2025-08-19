import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../instructor/class_detail_page.dart';
import '../../models/instructor_class_model.dart' as instructor_class_model;
import '../../providers/auth_provider.dart' as app_auth;
import 'package:flutter/services.dart';

class InstructorClassListPage extends StatefulWidget {
  const InstructorClassListPage({super.key});

  @override
  State<InstructorClassListPage> createState() =>
      _InstructorClassListPageState();
}

class _InstructorClassListPageState extends State<InstructorClassListPage> {
  List<instructor_class_model.InstructorClass> _classes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _sortOption = 'name'; // name, date, students
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);

      if (authProvider.currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }

      // شبیه‌سازی دریافت کلاس‌ها از Firestore
      // در حالت واقعی باید از Firestore دریافت بشه
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _classes = [
          instructor_class_model.InstructorClass(
            id: const Uuid().v4(),
            name: 'کلاس ریاضی پیشرفته',
            code: _generateClassCode(),
            instructorId: authProvider.currentUser!.uid,
            students: [],
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
          ),
          instructor_class_model.InstructorClass(
            id: const Uuid().v4(),
            name: 'کلاس فیزیک پایه',
            code: _generateClassCode(),
            instructorId: authProvider.currentUser!.uid,
            students: [],
            createdAt: DateTime.now().subtract(const Duration(days: 15)),
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<instructor_class_model.InstructorClass> _getFilteredAndSortedClasses() {
    var filtered = _classes.where((c) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.code.toLowerCase().contains(query) ||
          (c.description?.toLowerCase().contains(query) ?? false);
    }).toList();

    // مرتب‌سازی
    filtered.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'date':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'students':
          comparison = a.students.length.compareTo(b.students.length);
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }
      return _isAscending ? comparison : -comparison;
    });

    return filtered;
  }

  Future<void> _createNewClass() async {
    _nameController.clear();
    _descriptionController.clear();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('ایجاد کلاس جدید'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'نام کلاس *',
                    hintText: 'مثال: ریاضی پیشرفته',
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    hintText: 'توضیحات مربوط به کلاس (اختیاری)',
                  ),
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('لغو'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.trim().isNotEmpty) {
                    Navigator.pop(ctx, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).primaryColor,
                ),
                child: const Text('ایجاد کلاس'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      try {
        final authProvider =
            Provider.of<app_auth.AuthProvider>(context, listen: false);

        final newClass = instructor_class_model.InstructorClass(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          code: _generateClassCode(),
          instructorId: authProvider.currentUser!.uid,
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          students: [],
          createdAt: DateTime.now(),
        );

        // در حالت واقعی باید در Firestore ذخیره بشه
        setState(() {
          _classes.add(newClass);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('کلاس با موفقیت ایجاد شد'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در ایجاد کلاس: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _generateClassCode() {
    final uuid = const Uuid().v4();
    return uuid.substring(0, 6).toUpperCase();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'مرتب‌سازی بر اساس',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...['name', 'date', 'students'].map((option) {
              final titles = {
                'name': 'نام کلاس',
                'date': 'تاریخ ایجاد',
                'students': 'تعداد دانشجو',
              };
              return ListTile(
                title: Text(titles[option]!),
                trailing: _sortOption == option
                    ? Icon(_isAscending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : null,
                onTap: () {
                  setState(() {
                    if (_sortOption == option) {
                      _isAscending = !_isAscending;
                    } else {
                      _sortOption = option;
                      _isAscending = true;
                    }
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showClassOptions(instructor_class_model.InstructorClass classItem) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'گزینه‌های کلاس: ${classItem.name}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('ویرایش اطلاعات'),
              onTap: () {
                Navigator.pop(context);
                _editClass(classItem);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('اشتراک‌گذاری کلاس'),
              onTap: () {
                Navigator.pop(context);
                _shareClass(classItem);
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('نمایش کد دعوت'),
              onTap: () {
                Navigator.pop(context);
                _showInviteCode(classItem);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title:
                  const Text('حذف کلاس', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteClass(classItem);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editClass(
      instructor_class_model.InstructorClass classItem) async {
    _nameController.text = classItem.name;
    _descriptionController.text = classItem.description ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ویرایش کلاس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'نام کلاس *',
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'توضیحات',
              ),
              textDirection: TextDirection.rtl,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        final index = _classes.indexWhere((c) => c.id == classItem.id);
        if (index != -1) {
          _classes[index] = classItem.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isNotEmpty
                ? _descriptionController.text.trim()
                : null,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کلاس با موفقیت ویرایش شد'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _shareClass(instructor_class_model.InstructorClass classItem) {
    final text =
        'کلاس: ${classItem.name}\nکد دعوت: ${classItem.code}\n\nبه کلاس من بپیوندید!';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
          label: 'کپی',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('متن کپی شد')),
            );
          },
        ),
      ),
    );
  }

  void _showInviteCode(instructor_class_model.InstructorClass classItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('کد دعوت کلاس'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'کد دعوت برای کلاس "${classItem.name}":',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Text(
                classItem.code,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: classItem.code));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('کد کپی شد')),
              );
            },
            child: const Text('کپی کد'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteClass(
      instructor_class_model.InstructorClass classItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف کلاس'),
        content: Text(
          'آیا از حذف کلاس "${classItem.name}" اطمینان دارید؟\nاین عمل غیرقابل بازگشت است.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف کلاس'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _classes.removeWhere((c) => c.id == classItem.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('کلاس با موفقیت حذف شد'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredClasses = _getFilteredAndSortedClasses();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('کلاس‌های من'),
          actions: [
            IconButton(
              onPressed: _createNewClass,
              icon: const Icon(Icons.add),
              tooltip: 'ایجاد کلاس جدید',
            ),
            IconButton(
              onPressed: _showSortOptions,
              icon: const Icon(Icons.sort),
              tooltip: 'مرتب‌سازی',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(
                  context, '/instructor_question_management'),
              icon: const Icon(Icons.question_answer),
              tooltip: 'مدیریت سوالات',
            ),
          ],
        ),
        body: Column(
          children: [
            // بخش جستجو
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'جستجوی کلاس...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            // بخش آمار
            if (_classes.isNotEmpty) _buildStatsCard(),
            // بخش لیست کلاس‌ها
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? _buildErrorState()
                      : filteredClasses.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadClasses,
                              child: ListView.builder(
                                itemCount: filteredClasses.length,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemBuilder: (ctx, i) {
                                  final c = filteredClasses[i];
                                  return _buildClassCard(c);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final totalClasses = _classes.length;
    final totalStudents = _classes.fold(0, (sum, c) => sum + c.students.length);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                  'تعداد کلاس‌ها', totalClasses.toString(), Icons.class_),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatItem(
                  'کل دانشجوها', totalStudents.toString(), Icons.people),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildClassCard(instructor_class_model.InstructorClass classItem) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailPage(
                instructorClass: classItem,
              ),
            ),
          );
        },
        onLongPress: () => _showClassOptions(classItem),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      classItem.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      classItem.code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
              if (classItem.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  classItem.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${classItem.students.length} دانشجو',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${classItem.createdAt.day}/${classItem.createdAt.month}/${classItem.createdAt.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'خطا در بارگیری کلاس‌ها',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadClasses,
            child: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'کلاسی با این مشخصات یافت نشد'
                : 'هنوز کلاسی ایجاد نکرده‌اید',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'از کلیدواژه دیگری استفاده کنید'
                : 'برای ایجاد کلاس جدید روی + ضربه بزنید',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
