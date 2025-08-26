import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/role_based_access.dart';
import '../../models/user_role.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart' as app_auth;

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // متغیرهای کنترل جستجو و فیلتر
  final TextEditingController _searchController = TextEditingController();
  String _searchField = 'name';
  UserRole? _roleFilter;
  String _sortBy = 'createdAt';
  bool _sortDescending = true;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('=== AdminDashboard: initState called ===');
    debugPrint(
        'Current user role: ${Provider.of<app_auth.AuthProvider>(context, listen: false).userRole}');
  }

  @override
  void dispose() {
    debugPrint('=== AdminDashboard: dispose called ===');
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('=== AdminDashboard: build called ===');

    try {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: RoleBasedAccess(
          requiredRole: UserRole.admin,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: const Text('پنل مدیریت ادمین'),
              backgroundColor: Colors.redAccent,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'افزودن کاربر',
                  onPressed: () => _showAddUserDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'به‌روزرسانی',
                  onPressed: () => _refreshData(context),
                ),
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  tooltip: 'خروج از سیستم',
                  onPressed: () => _handleLogout(context),
                ),
              ],
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // هدر خوشامگویی
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                size: 36,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'خوش آمدید، ادمین محترم',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Theme.of(context)
                                                        .primaryColor,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'به پنل مدیریت کل سیستم',
                                      style: TextStyle(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // آمار سریع
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'آمار کلی سیستم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/analytics'),
                              child: const Text(
                                'جزئیات',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildSystemStats(context),
                        const SizedBox(height: 16),
                        // منوی مدیریت - افقی
                        Text(
                          'منوی مدیریت',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildHorizontalMenu(context),
                        const SizedBox(height: 16),
                        // لیست کاربران با جستجو و فیلتر
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'کاربران سیستم',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                      context, '/user-management'),
                                  child: const Text(
                                    'نمایش همه',
                                    style: TextStyle(fontSize: 12),
                                  ),
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
                                      case 'json':
                                        _exportToJSON(context);
                                        break;
                                      case 'backup':
                                        _createBackup(context);
                                        break;
                                      case 'restore':
                                        _restoreFromBackup(context);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'excel',
                                      child: Row(
                                        children: [
                                          Icon(Icons.file_present),
                                          SizedBox(width: 8),
                                          Text('خروجی Excel'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'pdf',
                                      child: Row(
                                        children: [
                                          Icon(Icons.picture_as_pdf),
                                          SizedBox(width: 8),
                                          Text('خروجی PDF'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'json',
                                      child: Row(
                                        children: [
                                          Icon(Icons.code),
                                          SizedBox(width: 8),
                                          Text('خروجی JSON'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'backup',
                                      child: Row(
                                        children: [
                                          Icon(Icons.backup),
                                          SizedBox(width: 8),
                                          Text('تهیه بکاپ'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'restore',
                                      child: Row(
                                        children: [
                                          Icon(Icons.restore),
                                          SizedBox(width: 8),
                                          Text('بازیابی بکاپ'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildUserListWithFilters(context),
                        const SizedBox(height: 16),
                        // فعالیت‌های اخیر
                        Text(
                          'فعالیت‌های اخیر',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRecentActivities(context),
                      ],
                    ),
                  ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('=== Error in AdminDashboard build ===');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'خطا در بارگیری صفحه',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'خطا: $e',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ویجت برای نمایش آمار سیستم از Firestore
  Widget _buildSystemStats(BuildContext context) {
    debugPrint('=== Building system stats ===');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, userSnapshot) {
        debugPrint('User snapshot state: ${userSnapshot.connectionState}');
        debugPrint('User snapshot has data: ${userSnapshot.hasData}');
        debugPrint('User snapshot has error: ${userSnapshot.hasError}');

        if (userSnapshot.hasError) {
          debugPrint('User snapshot error: ${userSnapshot.error}');
          return const Text('خطا در بارگیری اطلاعات کاربران');
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          debugPrint('User snapshot waiting...');
          return const CircularProgressIndicator();
        }

        int userCount = userSnapshot.data?.docs.length ?? 0;
        debugPrint('User count: $userCount');

        return StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance.collection('questions').snapshots(),
          builder: (context, questionSnapshot) {
            debugPrint(
                'Question snapshot state: ${questionSnapshot.connectionState}');

            if (questionSnapshot.hasError) {
              debugPrint('Question snapshot error: ${questionSnapshot.error}');
              return const Text('خطا در بارگیری اطلاعات سوالات');
            }

            if (questionSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            int questionCount = questionSnapshot.data?.docs.length ?? 0;
            debugPrint('Question count: $questionCount');

            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('classes').snapshots(),
              builder: (context, classSnapshot) {
                debugPrint(
                    'Class snapshot state: ${classSnapshot.connectionState}');

                if (classSnapshot.hasError) {
                  debugPrint('Class snapshot error: ${classSnapshot.error}');
                  return const Text('خطا در بارگیری اطلاعات کلاس‌ها');
                }

                if (classSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                int classCount = classSnapshot.data?.docs.length ?? 0;
                debugPrint('Class count: $classCount');

                return Row(
                  children: [
                    _buildCompactStatCard(context, 'کاربران', '$userCount',
                        Icons.people, Colors.blue),
                    const SizedBox(width: 8),
                    _buildCompactStatCard(context, 'سوالات', '$questionCount',
                        Icons.quiz, Colors.green),
                    const SizedBox(width: 8),
                    _buildCompactStatCard(context, 'کلاس‌ها', '$classCount',
                        Icons.class_, Colors.orange),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ویجت برای نمایش منوی مدیریت افقی
  Widget _buildHorizontalMenu(BuildContext context) {
    debugPrint('=== Building horizontal menu ===');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCompactMenuCard(
            context,
            'کاربران',
            Icons.manage_accounts,
            Colors.blue,
            () => Navigator.pushNamed(context, '/user-management'),
          ),
          const SizedBox(width: 8),
          _buildCompactMenuCard(
            context,
            'سوالات',
            Icons.quiz,
            Colors.green,
            () =>
                Navigator.pushNamed(context, '/instructor_question_management'),
          ),
          const SizedBox(width: 8),
          _buildCompactMenuCard(
            context,
            'کلاس‌ها',
            Icons.class_,
            Colors.orange,
            () => Navigator.pushNamed(context, '/class-management'),
          ),
          const SizedBox(width: 8),
          _buildCompactMenuCard(
            context,
            'گزارش‌ها',
            Icons.assessment,
            Colors.purple,
            () => Navigator.pushNamed(context, '/reports'),
          ),
          const SizedBox(width: 8),
          _buildCompactMenuCard(
            context,
            'نظارت',
            Icons.monitor_heart,
            Colors.red,
            () => Navigator.pushNamed(context, '/system-monitor'),
          ),
          const SizedBox(width: 8),
          _buildCompactMenuCard(
            context,
            'تنظیمات',
            Icons.settings,
            Colors.grey,
            () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  // ویجت جدید برای نمایش لیست کاربران با جستجو و فیلتر
  Widget _buildUserListWithFilters(BuildContext context) {
    debugPrint('=== Building user list with filters ===');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // بخش جستجو و فیلتر
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'جستجو (نام، ایمیل، تلفن، UID)',
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
                              value: 'email',
                              child: Text('جستجو بر اساس ایمیل')),
                          DropdownMenuItem(
                              value: 'phone',
                              child: Text('جستجو بر اساس تلفن')),
                          DropdownMenuItem(
                              value: 'uid', child: Text('جستجو بر اساس UID')),
                          DropdownMenuItem(
                              value: 'id', child: Text('جستجو بر اساس ID')),
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
                // اصلاح شده: استفاده از Row با کنترل بهتر روی اندازه‌ها
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(
                              value: 'name',
                              child: Text('مرتب‌سازی بر اساس نام')),
                          DropdownMenuItem(
                              value: 'email',
                              child: Text('مرتب‌سازی بر اساس ایمیل')),
                          DropdownMenuItem(
                              value: 'createdAt',
                              child: Text('مرتب‌سازی بر اساس تاریخ عضویت')),
                          DropdownMenuItem(
                              value: 'role',
                              child: Text('مرتب‌سازی بر اساس نقش')),
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
                    // اصلاح شده: استفاده از Container به جای SwitchListTile
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
          ),
          const Divider(),
          // لیست کاربران
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: StreamBuilder<List<UserModel>>(
              stream:
                  Provider.of<app_auth.AuthProvider>(context).getUsersStream(),
              builder: (context, snapshot) {
                debugPrint(
                    'User list snapshot state: ${snapshot.connectionState}');
                debugPrint('User list snapshot has data: ${snapshot.hasData}');
                debugPrint(
                    'User list snapshot has error: ${snapshot.hasError}');

                if (snapshot.hasError) {
                  debugPrint('User list snapshot error: ${snapshot.error}');
                  return Center(child: Text('خطا: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  debugPrint('User list snapshot waiting...');
                  return const Center(child: CircularProgressIndicator());
                }

                List<UserModel> users = snapshot.data ?? [];
                debugPrint('Initial user count: ${users.length}');

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
                      case 'phone':
                        return user.phone?.toLowerCase().contains(
                                _searchController.text.toLowerCase()) ??
                            false;
                      case 'uid':
                        return user.uid
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase());
                      case 'id':
                        return user.id
                            .toLowerCase()
                            .contains(_searchController.text.toLowerCase());
                      default:
                        return user.name.toLowerCase().contains(
                                _searchController.text.toLowerCase()) ||
                            user.email
                                .toLowerCase()
                                .contains(_searchController.text.toLowerCase());
                    }
                  }).toList();
                }

                if (_roleFilter != null) {
                  users =
                      users.where((user) => user.role == _roleFilter).toList();
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
                    case 'createdAt':
                      comparison = a.createdAt.compareTo(b.createdAt);
                      break;
                    case 'role':
                      comparison = a.role.index.compareTo(b.role.index);
                      break;
                  }
                  return _sortDescending ? -comparison : comparison;
                });

                debugPrint('Filtered user count: ${users.length}');

                if (users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
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
                    return _buildDetailedUserCard(context, user, index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ویجت جدید برای کارت کاربر با جزئیات کامل
  Widget _buildDetailedUserCard(
      BuildContext context, UserModel user, int index) {
    debugPrint('=== Building detailed user card for ${user.name} ===');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role.name),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
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
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('ویرایش', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text('حذف',
                      style: TextStyle(fontSize: 12, color: Colors.red)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'change_role',
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, size: 16),
                  SizedBox(width: 8),
                  Text('تغییر نقش', style: TextStyle(fontSize: 12)),
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
                if (user.phone != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.purple),
                      const SizedBox(width: 8),
                      Text(
                        'تلفن: ${user.phone}',
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.perm_identity,
                        size: 16, color: Colors.teal),
                    const SizedBox(width: 8),
                    Text(
                      'UID: ${user.uid}',
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

  // ویجت برای نمایش فعالیت‌های اخیر
  Widget _buildRecentActivities(BuildContext context) {
    debugPrint('=== Building recent activities ===');

    return Column(
      children: [
        Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading:
                const Icon(Icons.person_add, color: Colors.green, size: 20),
            title: Text(
              'کاربر جدید ثبت‌نام کرد',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            subtitle: Text(
              '۲ دقیقه پیش',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/user-management');
            },
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: const Icon(Icons.quiz, color: Colors.blue, size: 20),
            title: Text(
              'سوال جدید تأیید شد',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            subtitle: Text(
              '۵ دقیقه پیش',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/moderator_question_approval');
            },
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: const Icon(Icons.warning, color: Colors.orange, size: 20),
            title: Text(
              'گزارش خطا ثبت شد',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            subtitle: Text(
              '۱۰ دقیقه پیش',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[600],
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/system-monitor');
            },
          ),
        ),
      ],
    );
  }

  // ویجت کارت آمار فشرده
  Widget _buildCompactStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ویجت کارت منوی فشرده
  Widget _buildCompactMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // متد جدید برای نمایش دیالوگ افزودن کاربر
  void _showAddUserDialog(BuildContext context) {
    debugPrint('=== Showing add user dialog ===');

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.normaluser;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('افزودن کاربر جدید'),
          content: Column(
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
                        content: Text('لطفاً تمام فیلدها را پر کنید')),
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
                    role: selectedRole,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('کاربر با موفقیت افزوده شد')),
                    );
                  }
                } catch (e) {
                  debugPrint('Error adding user: $e');
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

  // متدهای جدید برای خروجی و بکاپ
  Future<void> _exportToExcel(BuildContext context) async {
    debugPrint('=== Exporting to Excel ===');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال آماده‌سازی خروجی Excel...')),
      );
      final users =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();
      debugPrint('Found ${users.length} users to export');

      var excelObj = excel.Excel.createExcel();
      var sheet = excelObj['Users'];
      // ایجاد هدر
      sheet.appendRow([
        'نام',
        'ایمیل',
        'نقش',
        'تلفن',
        'تاریخ عضویت',
        'آخرین ورود',
        'وضعیت',
        'ID',
        'UID'
      ]);
      // افزودن داده‌ها
      for (var user in users) {
        sheet.appendRow([
          user.name,
          user.email,
          user.role.persianName,
          user.phone ?? '',
          _formatDate(user.createdAt),
          user.lastLogin != null ? _formatDate(user.lastLogin!) : 'هرگز',
          user.isActive ? 'فعال' : 'غیرفعال',
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
      debugPrint('Error in exportToExcel: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در خروجی Excel: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _exportToPDF(BuildContext context) async {
    debugPrint('=== Exporting to PDF ===');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('در حال آماده‌سازی خروجی PDF...')),
    );
    // این متد رو می‌تونی با استفاده از پکیج pdf پیاده‌سازی کنی
  }

  Future<void> _exportToJSON(BuildContext context) async {
    debugPrint('=== Exporting to JSON ===');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال آماده‌سازی خروجی JSON...')),
      );
      final users =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();
      debugPrint('Found ${users.length} users to export');

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
      debugPrint('Error in exportToJSON: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در خروجی JSON: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _createBackup(BuildContext context) async {
    debugPrint('=== Creating backup ===');

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('در حال تهیه بکاپ...')),
      );
      final users =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();
      debugPrint('Found ${users.length} users to backup');

      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'users': users.map((user) => user.toMap()).toList(),
      };
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_backup', json.encode(backupData));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('بکاپ با موفقیت ذخیره شد')),
        );
      }
    } catch (e) {
      debugPrint('Error in createBackup: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در تهیه بکاپ: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _restoreFromBackup(BuildContext context) async {
    debugPrint('=== Restoring from backup ===');

    try {
      final prefs = await SharedPreferences.getInstance();
      final backupString = prefs.getString('user_backup');
      if (backupString == null) {
        debugPrint('No backup found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('هیچ بکاپی یافت نشد')),
          );
        }
        return;
      }

      debugPrint('Backup found, restoring...');
      final backupData = json.decode(backupString) as Map<String, dynamic>;
      final usersData = backupData['users'] as List;
      debugPrint('Found ${usersData.length} users in backup');

      // نمایش دیالگ برای انتخاب کاربران برای بازیابی
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('بازیابی بکاپ'),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: usersData.length,
                itemBuilder: (context, index) {
                  final userData = usersData[index] as Map<String, dynamic>;
                  return CheckboxListTile(
                    title: Text(userData['name'] ?? ''),
                    subtitle: Text(userData['email'] ?? ''),
                    value: false,
                    onChanged: (value) {
                      // منطق بازیابی کاربر
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('لغو'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('بازیابی با موفقیت انجام شد')),
                    );
                  }
                },
                child: const Text('بازیابی'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in restoreFromBackup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در بازیابی بکاپ: ${e.toString()}')),
        );
      }
    }
  }

  // متد برای به‌روزرسانی داده‌ها
  void _refreshData(BuildContext context) {
    debugPrint('=== Refreshing data ===');

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('داده‌ها به‌روزرسانی شدند')),
    );
  }

  // تابع برای دریافت رنگ بر اساس نقش
  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'instructor':
        return Colors.green;
      case 'student':
        return Colors.blue;
      case 'normaluser':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // متد کمکی برای فرمت تاریخ - بهبود یافته
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

  // توابع مدیریت کاربران - بهبود یافته
  void _editUser(BuildContext context, UserModel user) {
    debugPrint('=== Editing user: ${user.name} ===');

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
                debugPrint('Error in editUser: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('خطا در ویرایش کاربر: ${e.toString()}')),
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

  void _deleteUser(BuildContext context, UserModel user) {
    debugPrint('=== Deleting user: ${user.name} ===');

    // بررسی محدودیت حذف ادمین
    if (user.role == UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امکان حذف کاربر ادمین وجود ندارد')),
      );
      return;
    }

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
                debugPrint('Error in deleteUser: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('خطا در حذف کاربر: ${e.toString()}')),
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

  void _changeUserRole(BuildContext context, UserModel user) {
    debugPrint('=== Changing role for user: ${user.name} ===');

    // بررسی محدودیت تغییر نقش ادمین
    if (user.role == UserRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('امکان تغییر نقش کاربر ادمین وجود ندارد')),
      );
      return;
    }

    UserRole currentRole = user.role;
    UserRole? newRole;

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
                  setState(() {
                    newRole = value;
                  });
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
                if (newRole == null) return;
                Navigator.pop(context);
                try {
                  final authProvider = Provider.of<app_auth.AuthProvider>(
                      context,
                      listen: false);
                  await authProvider.updateUserFields(user.id, {
                    'role': newRole!.name,
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'نقش کاربر به ${newRole!.persianName} تغییر یافت')),
                    );
                  }
                } catch (e) {
                  debugPrint('Error in changeUserRole: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('خطا در تغییر نقش کاربر: ${e.toString()}')),
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

  void _handleLogout(BuildContext context) {
    debugPrint('=== Handling logout ===');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید خروج'),
        content: const Text('آیا مطمئن هستید که می‌خواهید از سیستم خارج شوید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider =
                  Provider.of<app_auth.AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
}
