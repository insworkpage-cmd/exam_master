import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/user_model.dart';
import '../../models/user_role.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // متغیرهای کنترل جستجو و فیلتر
  final TextEditingController _searchController = TextEditingController();
  String _searchField = 'name';
  UserRole? _roleFilter;
  String _sortBy = 'createdAt';
  bool _sortDescending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مدیریت کاربران'),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddUserDialog(context),
              tooltip: 'افزودن کاربر جدید',
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'excel':
                    _exportToExcel(context);
                    break;
                  case 'pdf':
                    _exportToPDF(context);
                    break;
                  case 'csv':
                    _exportToCSV(context);
                    break;
                  case 'json':
                    _exportToJSON(context);
                    break;
                  case 'upload':
                    _uploadUsers(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.file_present),
                      SizedBox(width: 8),
                      Text('خروجی Excel'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text('خروجی PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart),
                      SizedBox(width: 8),
                      Text('خروجی CSV'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'json',
                  child: Row(
                    children: [
                      Icon(Icons.code),
                      SizedBox(width: 8),
                      Text('خروجی JSON'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'upload',
                  child: Row(
                    children: [
                      Icon(Icons.upload_file),
                      SizedBox(width: 8),
                      Text('بارگذاری گروهی'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // بخش جستجو و فیلتر
            _buildSearchAndFilterSection(),
            // بخش آمار و دکمه‌های عملیات
            _buildStatsAndActionsSection(),
            // لیست کاربران
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: Provider.of<app_auth.AuthProvider>(context)
                    .getUsersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('خطا: ${snapshot.error}'));
                  }
                  List<UserModel> users = snapshot.data ?? [];

                  // اعمال فیلترها
                  if (_searchController.text.isNotEmpty) {
                    users = users.where((user) {
                      switch (_searchField) {
                        case 'name':
                          return user.name
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase());
                        case 'email':
                          return user.email
                              .toLowerCase()
                              .contains(_searchController.text.toLowerCase());
                        default:
                          return user.name.toLowerCase().contains(
                                  _searchController.text.toLowerCase()) ||
                              user.email.toLowerCase().contains(
                                  _searchController.text.toLowerCase());
                      }
                    }).toList();
                  }

                  if (_roleFilter != null) {
                    users = users
                        .where((user) => user.role == _roleFilter)
                        .toList();
                  }

                  // اعمال مرتب‌سازی
                  users.sort((a, b) {
                    int comparison = 0;
                    switch (_sortBy) {
                      case 'name':
                        comparison = a.name.compareTo(b.name);
                        break;
                      case 'email':
                        comparison = a.email.compareTo(b.email);
                        break;
                      case 'role':
                        comparison = a.role.index.compareTo(b.role.index);
                        break;
                      case 'createdAt':
                        comparison = a.createdAt.compareTo(b.createdAt);
                        break;
                    }
                    return _sortDescending ? -comparison : comparison;
                  });

                  if (users.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'هیچ کاربری یافت نشد',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'با تغییر فیلترها یا جستجو دوباره تلاش کنید',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return _buildUserCard(context, user);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بخش جستجو و فیلتر
  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'جستجو (نام، ایمیل)',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
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
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _searchField,
                  items: const [
                    DropdownMenuItem(
                        value: 'name', child: Text('جستجو بر اساس نام')),
                    DropdownMenuItem(
                        value: 'email', child: Text('جستجو بر اساس ایمیل')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _searchField = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'فیلد جستجو',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<UserRole?>(
                  value: _roleFilter,
                  items: [
                    const DropdownMenuItem<UserRole?>(
                      value: null,
                      child: Text('همه نقش‌ها'),
                    ),
                    ...UserRole.values.map((role) {
                      return DropdownMenuItem<UserRole?>(
                        value: role,
                        child: Text(role.persianName),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _roleFilter = value;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'فیلتر نقش',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(
                        value: 'name', child: Text('مرتب‌سازی بر اساس نام')),
                    DropdownMenuItem(
                        value: 'email', child: Text('مرتب‌سازی بر اساس ایمیل')),
                    DropdownMenuItem(
                        value: 'role', child: Text('مرتب‌سازی بر اساس نقش')),
                    DropdownMenuItem(
                        value: 'createdAt',
                        child: Text('مرتب‌سازی بر اساس تاریخ عضویت')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'مرتب‌سازی',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'مرتب‌سازی نزولی',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Switch(
                        value: _sortDescending,
                        onChanged: (value) {
                          setState(() {
                            _sortDescending = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بخش آمار و دکمه‌های عملیات
  Widget _buildStatsAndActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'لیست همه کاربران',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('افزودن کاربر'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showBatchActionsDialog(context),
                icon: const Icon(Icons.select_all),
                label: const Text('عملیات گروهی'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // کارت کاربر
  Widget _buildUserCard(BuildContext context, UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Icon(
            _getRoleIcon(user.role),
            color: Colors.white,
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                _editUser(context, user);
                break;
              case 'delete':
                _deleteUser(context, user);
                break;
              case 'change_role':
                _changeUserRole(context, user);
                break;
              case 'view_details':
                _viewUserDetails(context, user);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('ویرایش'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'change_role',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz),
                  SizedBox(width: 8),
                  Text('تغییر نقش'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'view_details',
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Text('جزئیات'),
                ],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'نقش: ${user.role.persianName}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.calendar_today,
                        size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'عضویت: ${_formatDate(user.createdAt)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                if (user.lastLogin != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.login, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'آخرین ورود: ${_formatDate(user.lastLogin!)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'ID: ${user.id}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دیالوگ افزودن کاربر
  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    UserRole selectedRole = UserRole.normaluser;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('افزودن کاربر جدید'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'نام کاربر'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'ایمیل'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration:
                      const InputDecoration(labelText: 'تلفن (اختیاری)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'رمز عبور'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.persianName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'نقش کاربر',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty ||
                    passwordController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('لطفاً تمام فیلدهای ضروری را پر کنید')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  final authProvider = Provider.of<app_auth.AuthProvider>(
                      context,
                      listen: false);
                  await authProvider.register(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                    nameController.text.trim(),
                    phone: phoneController.text.trim().isNotEmpty
                        ? phoneController.text.trim()
                        : null,
                    role: selectedRole,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('کاربر با موفقیت افزوده شد')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطا در افزودن کاربر: $e')),
                    );
                  }
                }
              },
              child: const Text('افزودن'),
            ),
          ],
        ),
      ),
    );
  }

  // دیالوگ عملیات گروهی
  void _showBatchActionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('عملیات گروهی'),
        content: const Text(
          'لطفاً عملیات مورد نظر را انتخاب کنید',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadUsers(context);
            },
            child: const Text('بارگذاری گروهی کاربران'),
          ),
        ],
      ),
    );
  }

  // ویرایش کاربر
  void _editUser(BuildContext context, UserModel user) {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ویرایش کاربر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'نام'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'ایمیل'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'تلفن'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authProvider =
                    Provider.of<app_auth.AuthProvider>(context, listen: false);
                await authProvider.updateUserFields(user.id, {
                  'name': nameController.text,
                  'email': emailController.text,
                  'phone': phoneController.text,
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('کاربر با موفقیت ویرایش شد')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطا در ویرایش کاربر: $e')),
                  );
                }
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }

  // حذف کاربر
  void _deleteUser(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف کاربر'),
        content: Text('آیا از حذف "${user.name}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                final authProvider =
                    Provider.of<app_auth.AuthProvider>(context, listen: false);
                await authProvider.deleteUser(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('کاربر با موفقیت حذف شد')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطا در حذف کاربر: $e')),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  // تغییر نقش کاربر
  void _changeUserRole(BuildContext context, UserModel user) {
    UserRole currentRole = user.role;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تغییر نقش کاربر'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('نقش فعلی: ${currentRole.persianName}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<UserRole>(
                value: currentRole,
                items: UserRole.values.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.persianName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      currentRole = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'نقش جدید',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('لغو'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final authProvider = Provider.of<app_auth.AuthProvider>(
                      context,
                      listen: false);
                  await authProvider.updateUserFields(user.id, {
                    'role': currentRole.name,
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'نقش کاربر به ${currentRole.persianName} تغییر یافت')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطا در تغییر نقش کاربر: $e')),
                    );
                  }
                }
              },
              child: const Text('تغییر نقش'),
            ),
          ],
        ),
      ),
    );
  }

  // نمایش جزئیات کاربر
  void _viewUserDetails(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('جزئیات کاربر'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(Icons.person, 'نام', user.name),
              _buildDetailRow(Icons.email, 'ایمیل', user.email),
              if (user.phone != null)
                _buildDetailRow(Icons.phone, 'تلفن', user.phone!),
              _buildDetailRow(Icons.badge, 'نقش', user.role.persianName),
              _buildDetailRow(Icons.calendar_today, 'تاریخ عضویت',
                  _formatDate(user.createdAt)),
              if (user.lastLogin != null)
                _buildDetailRow(
                    Icons.login, 'آخرین ورود', _formatDate(user.lastLogin!)),
              _buildDetailRow(Icons.perm_identity, 'ID', user.id),
              _buildDetailRow(Icons.fingerprint, 'UID', user.uid),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  // ویجت ردیف جزئیات
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // خروجی Excel
  Future<void> _exportToExcel(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال آماده‌سازی خروجی Excel...')),
      );

      final users =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();
      var excelObj = excel.Excel.createExcel();
      var sheet = excelObj['Users'];

      // ایجاد هدر
      sheet.appendRow([
        'نام',
        'ایمیل',
        'تلفن',
        'نقش',
        'تاریخ عضویت',
        'آخرین ورود',
        'ID',
        'UID'
      ]);

      // افزودن داده‌ها
      for (var user in users) {
        sheet.appendRow([
          user.name,
          user.email,
          user.phone ?? '',
          user.role.persianName,
          _formatDate(user.createdAt),
          user.lastLogin != null ? _formatDate(user.lastLogin!) : 'هرگز',
          user.id,
          user.uid
        ]);
      }

      // ذخیره فایل
      final bytes = excelObj.save();
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute(
            'download', 'users_${DateTime.now().millisecondsSinceEpoch}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خروجی Excel با موفقیت دانلود شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در خروجی Excel: $e')),
        );
      }
    }
  }

  // خروجی PDF
  Future<void> _exportToPDF(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('در حال آماده‌سازی خروجی PDF...')),
    );
    // در اینجا می‌توانید از پکیج pdf استفاده کنید
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('این قابلیت در حال توسعه است')),
    );
  }

  // خروجی CSV
  Future<void> _exportToCSV(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال آماده‌سازی خروجی CSV...')),
      );

      final users =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();

      // ایجاد محتوای CSV
      String csvContent = "نام,ایمیل,تلفن,نقش,تاریخ عضویت,آخرین ورود,ID,UID\n";

      for (var user in users) {
        csvContent +=
            "${user.name},${user.email},${user.phone ?? ''},${user.role.persianName},${_formatDate(user.createdAt)},${user.lastLogin != null ? _formatDate(user.lastLogin!) : 'هرگز'},${user.id},${user.uid}\n";
      }

      // ذخیره فایل
      final blob = html.Blob([csvContent], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute(
            'download', 'users_${DateTime.now().millisecondsSinceEpoch}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خروجی CSV با موفقیت دانلود شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در خروجی CSV: $e')),
        );
      }
    }
  }

  // خروجی JSON
  Future<void> _exportToJSON(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال آماده‌سازی خروجی JSON...')),
      );

      final users =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();
      final jsonData = users.map((user) => user.toMap()).toList();
      final jsonString = json.encode(jsonData);

      final blob = html.Blob([jsonString], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download',
            'users_backup_${DateTime.now().millisecondsSinceEpoch}.json')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خروجی JSON با موفقیت دانلود شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در خروجی JSON: $e')),
        );
      }
    }
  }

  // بارگذاری گروهی کاربران
  Future<void> _uploadUsers(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال انتخاب فایل...')),
      );

      // انتخاب فایل
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هیچ فایلی انتخاب نشد')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال پردازش فایل...')),
      );

      // در اینجا باید منطق پردازش فایل و افزودن کاربران را پیاده‌سازی کنید
      // این یک نمونه ساده است

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('این قابلیت در حال توسعه است')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری فایل: $e')),
        );
      }
    }
  }

  // فرمت‌بندی تاریخ
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'امروز ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} هفته پیش';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} ماه پیش';
    } else {
      return '${(difference.inDays / 365).floor()} سال پیش';
    }
  }

  // دریافت رنگ بر اساس نقش
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.moderator:
        return Colors.orange;
      case UserRole.instructor:
        return Colors.green;
      case UserRole.student:
        return Colors.blue;
      case UserRole.normaluser:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // دریافت آیکون بر اساس نقش
  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings;
      case UserRole.moderator:
        return Icons.content_paste;
      case UserRole.instructor:
        return Icons.school;
      case UserRole.student:
        return Icons.person;
      case UserRole.normaluser:
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }
}
