import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shamsi_date/shamsi_date.dart';
import 'dart:developer' as developer;
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../../widgets/persian_calendar_widget.dart';
import 'user_analytics_page.dart';

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

  // متغیرهای صفحه‌بندی
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalUsers = 0;

  // متغیرهای انتخاب گروهی
  final Set<String> _selectedUserIds = {};
  bool _isSelectionMode = false;

  // متغیرهای فیلتر تاریخ
  DateTime? _startDate;
  DateTime? _endDate;

  // متغیر برای forcing rebuild
  int _refreshKey = 0;

  // متغیرهای آمار
  int _onlineUsersCount = 0;
  int _todayLoggedInUsersCount = 0;
  bool _isLoadingStats = false;
  String _statsErrorMessage = '';

  // متغیر برای کنترل اجرای یک‌باره افزودن فیلد lastLogin
  bool _hasAddedLastLoginField = false;

  @override
  void initState() {
    super.initState();
    _testDateConversion();
    _initializePage();
  }

  // متد تست برای بررسی تبدیل تاریخ
  void _testDateConversion() {
    final now = DateTime.now();
    final formattedDate = _formatDate(now);
    developer.log('تاریخ امروز به شمسی: $formattedDate');
    final testDate = DateTime(2023, 10, 1); // 1 مهر 1402
    final formattedTestDate = _formatDate(testDate);
    developer.log('تاریخ تست به شمسی: $formattedTestDate');
  }

  // متد برای مقداردهی اولیه صفحه
  Future<void> _initializePage() async {
    // افزودن فیلد lastLogin به همه کاربران (فقط یک بار)
    if (!_hasAddedLastLoginField) {
      try {
        await Provider.of<app_auth.AuthProvider>(context, listen: false)
            .addLastLoginFieldToAllUsers();
        setState(() {
          _hasAddedLastLoginField = true;
        });
        developer.log('فیلد lastLogin برای همه کاربران اضافه شد');
      } catch (e) {
        developer.log('خطا در افزودن فیلد lastLogin: $e');
      }
    }

    // بارگذاری آمار با کمی تاخیر برای اطمینان از بارگیری کامل صفحه
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _loadUserStats();
      }
    });
  }

  // متد برای forcing rebuild
  void _refresh() {
    setState(() {
      _refreshKey++;
    });
    _loadUserStats(); // بارگذاری مجدد آمار
  }

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
        appBar: _isSelectionMode
            ? _buildSelectionAppBar()
            : AppBar(
                title: const Text('مدیریت کاربران'),
                backgroundColor: Colors.blue,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refresh,
                    tooltip: 'بروزرسانی',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _logout(context),
                    tooltip: 'خروج',
                  ),
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
                key: ValueKey(_refreshKey), // افزودن کلید برای forcing rebuild
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
                  // ذخیره تعداد کل کاربران
                  _totalUsers = users.length;
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
                  // اعمال فیلتر تاریخ
                  if (_startDate != null) {
                    users = users
                        .where((user) => user.createdAt.isAfter(_startDate!))
                        .toList();
                  }
                  if (_endDate != null) {
                    users = users
                        .where((user) => user.createdAt.isBefore(_endDate!))
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
                  // اعمال صفحه‌بندی
                  final paginatedUsers = users
                      .skip((_currentPage - 1) * _pageSize)
                      .take(_pageSize)
                      .toList();
                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedUsers.length,
                          itemBuilder: (context, index) {
                            final user = paginatedUsers[index];
                            return _buildUserCard(context, user);
                          },
                        ),
                      ),
                      _buildPagination(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // متد خروج از سیستم
  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروج'),
        content: const Text('آیا از خروج اطمینان دارید؟'),
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
                await authProvider.signOut();
                if (context.mounted) {
                  // هدایت به صفحه ورود
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطا در خروج: $e')),
                  );
                }
              }
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  // نوار اعلان حالت انتخاب
  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      title: Text('${_selectedUserIds.length} کاربر انتخاب شده'),
      backgroundColor: Colors.blue,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _isSelectionMode = false;
            _selectedUserIds.clear();
          });
        },
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'delete':
                _deleteSelectedUsers(context);
                break;
              case 'change_role':
                _changeRoleSelectedUsers(context);
                break;
              case 'export':
                _exportSelectedUsers(context);
                break;
            }
          },
          itemBuilder: (context) => [
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
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.file_download),
                  SizedBox(width: 8),
                  Text('خروجی'),
                ],
              ),
            ),
          ],
        ),
      ],
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
                        _refresh();
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              _refresh();
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
                child: InkWell(
                  onTap: () async {
                    final Jalali? picked = await showPersianCalendar(
                      context: context,
                      initialDate: _startDate != null
                          ? Jalali.fromDateTime(_startDate!)
                          : Jalali.now(),
                      firstDate: Jalali(1380, 1, 1),
                      lastDate: Jalali.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.toDateTime();
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'از تاریخ',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _startDate != null
                          ? _formatJalaliDate(_startDate!)
                          : 'تاریخ شروع را انتخاب کنید',
                      style: TextStyle(
                        color: _startDate != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final Jalali? picked = await showPersianCalendar(
                      context: context,
                      initialDate: _endDate != null
                          ? Jalali.fromDateTime(_endDate!)
                          : Jalali.now(),
                      firstDate: Jalali(1380, 1, 1),
                      lastDate: Jalali.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _endDate = picked.toDateTime();
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تا تاریخ',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _endDate != null
                          ? _formatJalaliDate(_endDate!)
                          : 'تاریخ پایان را انتخاب کنید',
                      style: TextStyle(
                        color:
                            _endDate != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
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
      child: Column(
        children: [
          // ردیف عنوان و آمار
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'لیست همه کاربران',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  _isLoadingStats
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _statsErrorMessage.isNotEmpty
                          ? const Icon(Icons.error, color: Colors.red, size: 16)
                          : Container(),
                  const SizedBox(width: 8),
                  _buildStatChip('کل کاربران', _totalUsers, Colors.blue),
                  const SizedBox(width: 8),
                  _buildStatChip('آنلاین', _onlineUsersCount, Colors.green),
                  const SizedBox(width: 8),
                  _buildStatChip(
                      'ورود امروز', _todayLoggedInUsersCount, Colors.orange),
                ],
              ),
            ],
          ),
          if (_statsErrorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _statsErrorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          // ردیف دکمه‌ها
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label:
                    const Text('افزودن کاربر', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showBatchActionsDialog(context),
                icon: const Icon(Icons.select_all, size: 18),
                label:
                    const Text('عملیات گروهی', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showExportOptionsDialog(context),
                icon: const Icon(Icons.file_download, size: 18),
                label:
                    const Text('خروجی گرفتن', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserAnalyticsPage(),
                    ),
                  ).then((_) {
                    _refresh(); // رفرش کردن صفحه پس از بازگشت
                  });
                },
                icon: const Icon(Icons.analytics, size: 18),
                label:
                    const Text('آمار پیشرفته', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ویجت نمایش آمار به صورت چپ
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: color),
          ),
          Text(
            '$count',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // متد بارگذاری آمار کاربران
  Future<void> _loadUserStats() async {
    if (_isLoadingStats) return;

    setState(() {
      _isLoadingStats = true;
      _statsErrorMessage = '';
    });

    try {
      developer.log('شروع بارگذاری آمار کاربران...');
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final users = await authProvider.getAllUsers();

      developer.log('تعداد کل کاربران دریافت شده: ${users.length}');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      int onlineCount = 0;
      int todayLoggedInCount = 0;

      for (var user in users) {
        developer
            .log('بررسی کاربر: ${user.name}, آخرین ورود: ${user.lastLogin}');

        // محاسبه کاربران آنلاین (فعال در 24 ساعت گذشته)
        if (user.lastLogin != null) {
          if (user.lastLogin!.isAfter(twentyFourHoursAgo)) {
            onlineCount++;
            developer.log('کاربر ${user.name} آنلاین است');
          }

          // محاسبه کاربرانی که امروز وارد شده‌اند
          final loginDate = DateTime(
              user.lastLogin!.year, user.lastLogin!.month, user.lastLogin!.day);
          if (loginDate == today) {
            todayLoggedInCount++;
            developer.log('کاربر ${user.name} امروز وارد شده است');
          }
        } else {
          developer.log('کاربر ${user.name} هیچ‌وقت وارد سیستم نشده است');
        }
      }

      developer.log(
          'آمار نهایی: کل=${users.length}, آنلاین=$onlineCount, امروز=$todayLoggedInCount');

      setState(() {
        _onlineUsersCount = onlineCount;
        _todayLoggedInUsersCount = todayLoggedInCount;
        _isLoadingStats = false;
      });
    } catch (e) {
      developer.log('خطا در بارگذاری آمار کاربران: $e');
      setState(() {
        _statsErrorMessage = 'خطا در بارگذاری آمار: $e';
        _isLoadingStats = false;
      });
    }
  }

  // دیالوگ گزینه‌های خروجی
  void _showExportOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروجی گرفتن'),
        content: const Text(
          'لطفاً فرمت خروجی را انتخاب کنید',
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
              _exportToExcel(context);
            },
            child: const Text('Excel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF(context);
            },
            child: const Text('PDF'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToCSV(context);
            },
            child: const Text('CSV'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportToJSON(context);
            },
            child: const Text('JSON'),
          ),
        ],
      ),
    );
  }

  // ویجت صفحه‌بندی
  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'نمایش ${((_currentPage - 1) * _pageSize) + 1}-${(_currentPage * _pageSize).clamp(0, _totalUsers)} از $_totalUsers کاربر',
            style: const TextStyle(fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton<int>(
                  value: _pageSize,
                  underline: Container(),
                  items: [5, 10, 20, 50, 100].map((size) {
                    return DropdownMenuItem<int>(
                      value: size,
                      child: Text('$size در صفحه'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _pageSize = value;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _currentPage * _pageSize < _totalUsers
                    ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // کارت کاربر
  Widget _buildUserCard(BuildContext context, UserModel user) {
    final isSelected = _selectedUserIds.contains(user.id);
    // لاگ تاریخ برای دیباگ
    developer.log('تاریخ عضویت کاربر: ${user.createdAt}');
    developer.log('تاریخ عضویت به شمسی: ${_formatJalaliDate(user.createdAt)}');
    return Card(
      key: Key(
          'user_card_${user.id}$_refreshKey'), // افزودن کلید برای forcing rebuild
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedUserIds.remove(user.id);
              } else {
                _selectedUserIds.add(user.id);
              }
              // اگر هیچ کاربری انتخاب نشده باشد، از حالت انتخاب خارج شو
              if (_selectedUserIds.isEmpty) {
                _isSelectionMode = false;
              }
            });
          }
        },
        onLongPress: () {
          setState(() {
            _isSelectionMode = true;
            _selectedUserIds.add(user.id);
          });
        },
        child: Stack(
          children: [
            ExpansionTile(
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildUserStatusIndicator(user),
                ],
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
                            'عضویت: ${_formatJalaliDate(user.createdAt)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      if (user.lastLogin != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.login,
                                size: 16, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(
                              'آخرین ورود: ${_formatJalaliDate(user.lastLogin!)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.grey),
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
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ویجت نمایش وضعیت کاربر
  Widget _buildUserStatusIndicator(UserModel user) {
    final isOnline = user.lastLogin != null &&
        user.lastLogin!
            .isAfter(DateTime.now().subtract(const Duration(hours: 1)));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isOnline ? 'آنلاین' : 'آفلاین',
          style: TextStyle(
            fontSize: 12,
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
      ],
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
                    _refresh(); // forcing rebuild
                  }
                } on Exception catch (e) {
                  if (context.mounted) {
                    String errorMessage = 'خطا در افزودن کاربر';
                    if (e.toString().contains('email-already-in-use')) {
                      errorMessage = 'این ایمیل قبلاً ثبت شده است';
                    } else if (e.toString().contains('invalid-email')) {
                      errorMessage = 'ایمیل وارد شده معتبر نیست';
                    } else if (e.toString().contains('weak-password')) {
                      errorMessage = 'رمز عبور ضعیف است';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
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
                  _refresh(); // forcing rebuild
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  String errorMessage = 'خطا در ویرایش کاربر';
                  if (e.toString().contains('email-already-in-use')) {
                    errorMessage = 'این ایمیل قبلاً ثبت شده است';
                  } else if (e.toString().contains('invalid-email')) {
                    errorMessage = 'ایمیل وارد شده معتبر نیست';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
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
                  _refresh(); // forcing rebuild
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  String errorMessage = 'خطا در حذف کاربر';
                  if (e.toString().contains('requires-recent-login')) {
                    errorMessage = 'برای حذف کاربر، لطفاً مجدداً وارد شوید';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
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
                    _refresh(); // forcing rebuild
                  }
                } on Exception catch (e) {
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
                  _formatJalaliDate(user.createdAt)),
              if (user.lastLogin != null)
                _buildDetailRow(Icons.login, 'آخرین ورود',
                    _formatJalaliDate(user.lastLogin!)),
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('در حال آماده‌سازی خروجی Excel...')),
    );
    try {
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
          _formatJalaliDate(user.createdAt),
          user.lastLogin != null ? _formatJalaliDate(user.lastLogin!) : 'هرگز',
          user.id,
          user.uid
        ]);
      }
      // ذخیره فایل
      final bytes = excelObj.save();
      final blob = html.Blob([bytes!],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute(
            'download', 'users_${DateTime.now().millisecondsSinceEpoch}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('خروجی Excel با موفقیت دانلود شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('خطا در خروجی Excel: $e')),
        );
      }
    }
  }

  // خروجی PDF
  Future<void> _exportToPDF(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('در حال آماده‌سازی خروجی PDF...')),
    );
    try {
      final users =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();
      final pdf = pw.Document();
      // بارگذاری فونت‌های دستی
      final ByteData regularFontData =
          await rootBundle.load('lib/assets/fonts/Vazirmatn-Regular.ttf');
      final ByteData boldFontData =
          await rootBundle.load('lib/assets/fonts/Vazirmatn-Bold.ttf');
      // ایجاد فونت با استفاده از ByteData
      final pw.Font regularFont = pw.Font.ttf(regularFontData);
      final pw.Font boldFont = pw.Font.ttf(boldFontData);
      pdf.addPage(
        pw.Page(
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
          ),
          build: (pw.Context context) => pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('گزارش کاربران',
                      style: pw.TextStyle(font: boldFont, fontSize: 24)),
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  context: context,
                  data: <List<String>>[
                    <String>[
                      'نام',
                      'ایمیل',
                      'تلفن',
                      'نقش',
                      'تاریخ عضویت',
                      'آخرین ورود'
                    ],
                    ...users.map((user) => [
                          user.name,
                          user.email,
                          user.phone ?? '',
                          user.role.persianName,
                          _formatJalaliDate(user.createdAt),
                          user.lastLogin != null
                              ? _formatJalaliDate(user.lastLogin!)
                              : 'هرگز',
                        ]),
                  ],
                  headerStyle: pw.TextStyle(font: boldFont, fontSize: 12),
                  cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerRight,
                  cellPadding: const pw.EdgeInsets.all(5),
                ),
              ],
            ),
          ),
        ),
      );
      // ذخیره فایل
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute(
            'download', 'users_${DateTime.now().millisecondsSinceEpoch}.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('خروجی PDF با موفقیت دانلود شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('خطا در خروجی PDF: $e')),
        );
      }
    }
  }

  // خروجی CSV
  Future<void> _exportToCSV(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('در حال آماده‌سازی خروجی CSV...')),
    );
    try {
      final users =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();
      // ایجاد محتوای CSV
      String csvContent = "نام,ایمیل,تلفن,نقش,تاریخ عضویت,آخرین ورود,ID,UID\n";
      for (var user in users) {
        csvContent +=
            "${user.name},${user.email},${user.phone ?? ''},${user.role.persianName},${_formatJalaliDate(user.createdAt)},${user.lastLogin != null ? _formatJalaliDate(user.lastLogin!) : 'هرگز'},${user.id},${user.uid}\n";
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
        messenger.showSnackBar(
          const SnackBar(content: Text('خروجی CSV با موفقیت دانلود شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('خطا در خروجی CSV: $e')),
        );
      }
    }
  }

  // خروجی JSON
  Future<void> _exportToJSON(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('در حال آماده‌سازی خروجی JSON...')),
    );
    try {
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
        messenger.showSnackBar(
          const SnackBar(content: Text('خروجی JSON با موفقیت دانلود شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('خطا در خروجی JSON: $e')),
        );
      }
    }
  }

  // بارگذاری گروهی کاربران
  Future<void> _uploadUsers(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('در حال انتخاب فایل...')),
    );
    // دریافت Provider قبل از هر عملیات ناهمگام
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    try {
      // انتخاب فایل
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
      );
      if (result == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('هیچ فایلی انتخاب نشد')),
        );
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('در حال پردازش فایل...')),
      );
      int successCount = 0;
      int failCount = 0;
      List<String> errorMessages = [];
      // خواندن فایل
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('خطا در خواندن فایل')),
        );
        return;
      }
      // تشخیص نوع فایل
      if (file.path?.endsWith('.csv') == true) {
        // پردازش فایل CSV
        final content = utf8.decode(bytes);
        final lines = content.split('\n');
        // پرش از هدر
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final fields = line.split(',');
          if (fields.length < 3) {
            failCount++;
            errorMessages.add('خط ${i + 1}: تعداد فیلدها ناکافی است');
            continue;
          }
          try {
            final name = fields[0].trim();
            final email = fields[1].trim();
            final phone = fields[2].trim();
            final roleName =
                fields.length > 3 ? fields[3].trim() : 'normaluser';
            // پیدا کردن نقش
            UserRole? role;
            try {
              role = UserRole.values.firstWhere(
                (r) => r.name.toLowerCase() == roleName.toLowerCase(),
              );
            } catch (e) {
              role = UserRole.normaluser;
            }
            // ایجاد کاربر
            await authProvider.register(
              email,
              'tempPassword123', // رمز عبور موقت
              name,
              phone: phone.isNotEmpty ? phone : null,
              role: role,
            );
            successCount++;
          } catch (e) {
            failCount++;
            errorMessages.add('خط ${i + 1}: $e');
          }
        }
      } else {
        // پردازش فایل Excel
        final excelObj = excel.Excel.decodeBytes(bytes);
        final table = excelObj.tables[excelObj.tables.keys.first];
        if (table == null) {
          messenger.showSnackBar(
            const SnackBar(content: Text('فایل Excel خالی است')),
          );
          return;
        }
        // پرش از هدر
        for (int i = 1; i < table.rows.length; i++) {
          final row = table.rows[i];
          if (row.length < 3) {
            failCount++;
            errorMessages.add('خط ${i + 1}: تعداد فیلدها ناکافی است');
            continue;
          }
          try {
            final name = row[0]?.value?.toString() ?? '';
            final email = row[1]?.value?.toString() ?? '';
            final phone = row[2]?.value?.toString() ?? '';
            final roleName = row.length > 3
                ? row[3]?.value?.toString() ?? 'normaluser'
                : 'normaluser';
            // پیدا کردن نقش
            UserRole? role;
            try {
              role = UserRole.values.firstWhere(
                (r) => r.name.toLowerCase() == roleName.toLowerCase(),
              );
            } catch (e) {
              role = UserRole.normaluser;
            }
            // ایجاد کاربر
            await authProvider.register(
              email,
              'tempPassword123', // رمز عبور موقت
              name,
              phone: phone.isNotEmpty ? phone : null,
              role: role,
            );
            successCount++;
          } catch (e) {
            failCount++;
            errorMessages.add('خط ${i + 1}: $e');
          }
        }
      }
      // نمایش نتایج
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('نتیجه بارگذاری گروهی'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('موفق: $successCount کاربر'),
                Text('ناموفق: $failCount کاربر'),
                if (errorMessages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'خطاها:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    width: 300,
                    child: ListView.builder(
                      itemCount: errorMessages.length,
                      itemBuilder: (context, index) {
                        return Text(
                          errorMessages[index],
                          style: const TextStyle(color: Colors.red),
                        );
                      },
                    ),
                  ),
                ],
              ],
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
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('خطا در بارگذاری فایل: $e')),
        );
      }
    }
  }

  // عملیات گروهی حذف کاربران
  void _deleteSelectedUsers(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف کاربران'),
        content:
            Text('آیا از حذف ${_selectedUserIds.length} کاربر اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              // دریافت Provider قبل از عملیات ناهمگام
              final authProvider =
                  Provider.of<app_auth.AuthProvider>(context, listen: false);
              try {
                // حذف کاربران
                for (final userId in _selectedUserIds) {
                  await authProvider.deleteUser(userId);
                }
                // خروج از حالت انتخاب
                setState(() {
                  _isSelectionMode = false;
                  _selectedUserIds.clear();
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '${_selectedUserIds.length} کاربر با موفقیت حذف شدند')),
                  );
                  _refresh(); // forcing rebuild
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  String errorMessage = 'خطا در حذف کاربران';
                  if (e.toString().contains('requires-recent-login')) {
                    errorMessage = 'برای حذف کاربران، لطفاً مجدداً وارد شوید';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
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

  // عملیات گروهی تغییر نقش کاربران
  void _changeRoleSelectedUsers(BuildContext context) {
    UserRole selectedRole = UserRole.normaluser;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('تغییر نقش کاربران'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تغییر نقش ${_selectedUserIds.length} کاربر'),
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
                // دریافت Provider قبل از عملیات ناهمگام
                final authProvider =
                    Provider.of<app_auth.AuthProvider>(context, listen: false);
                try {
                  // تغییر نقش کاربران
                  for (final userId in _selectedUserIds) {
                    await authProvider.updateUserFields(userId, {
                      'role': selectedRole.name,
                    });
                  }
                  // خروج از حالت انتخاب
                  this.setState(() {
                    _isSelectionMode = false;
                    _selectedUserIds.clear();
                  });
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'نقش ${_selectedUserIds.length} کاربر به ${selectedRole.persianName} تغییر یافت')),
                    );
                    _refresh(); // forcing rebuild
                  }
                } on Exception catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطا در تغییر نقش کاربران: $e')),
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

  // عملیات گروهی خروجی کاربران
  void _exportSelectedUsers(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('خروجی کاربران انتخاب شده'),
        content: const Text('فرمت خروجی را انتخاب کنید'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportSelectedToExcel(context);
            },
            child: const Text('Excel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportSelectedToCSV(context);
            },
            child: const Text('CSV'),
          ),
        ],
      ),
    );
  }

  // خروجی Excel کاربران انتخاب شده
  Future<void> _exportSelectedToExcel(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('در حال آماده‌سازی خروجی Excel...')),
    );
    try {
      final allUsers =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();
      final selectedUsers =
          allUsers.where((user) => _selectedUserIds.contains(user.id)).toList();
      var excelObj = excel.Excel.createExcel();
      var sheet = excelObj['Selected Users'];
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
      for (var user in selectedUsers) {
        sheet.appendRow([
          user.name,
          user.email,
          user.phone ?? '',
          user.role.persianName,
          _formatJalaliDate(user.createdAt),
          user.lastLogin != null ? _formatJalaliDate(user.lastLogin!) : 'هرگز',
          user.id,
          user.uid
        ]);
      }
      // ذخیره فایل
      final bytes = excelObj.save();
      final blob = html.Blob([bytes!],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download',
            'selected_users_${DateTime.now().millisecondsSinceEpoch}.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('خروجی Excel با موفقیت دانلود شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('خطا در خروجی Excel: $e')),
        );
      }
    }
  }

  // خروجی CSV کاربران انتخاب شده
  Future<void> _exportSelectedToCSV(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('در حال آماده‌سازی خروجی CSV...')),
    );
    try {
      final allUsers =
          await Provider.of<app_auth.AuthProvider>(context, listen: false)
              .getAllUsers();
      final selectedUsers =
          allUsers.where((user) => _selectedUserIds.contains(user.id)).toList();
      // ایجاد محتوای CSV
      String csvContent = "نام,ایمیل,تلفن,نقش,تاریخ عضویت,آخرین ورود,ID,UID\n";
      for (var user in selectedUsers) {
        csvContent +=
            "${user.name},${user.email},${user.phone ?? ''},${user.role.persianName},${_formatJalaliDate(user.createdAt)},${user.lastLogin != null ? _formatJalaliDate(user.lastLogin!) : 'هرگز'},${user.id},${user.uid}\n";
      }
      // ذخیره فایل
      final blob = html.Blob([csvContent], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download',
            'selected_users_${DateTime.now().millisecondsSinceEpoch}.csv')
        ..click();
      html.Url.revokeObjectUrl(url);
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('خروجی CSV با موفقیت دانلود شد')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('خطا در خروجی CSV: $e')),
        );
      }
    }
  }

  // متد کمکی برای تبدیل تاریخ به شمسی
  String _formatJalaliDate(DateTime date) {
    try {
      final jalali = Jalali.fromDateTime(date);
      return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
    } catch (e) {
      developer.log('خطا در تبدیل تاریخ به شمسی: $e');
      // در صورت خطا، تاریخ میلادی را برگردان
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }
  }

  // فرمت‌بندی تاریخ با تقویم شمسی
  String _formatDate(DateTime date) {
    try {
      final now = DateTime.now();
      final difference = now.difference(date);
      // لاگ برای دیباگ
      developer.log('تاریخ ورودی: $date');
      developer.log('تفاوت زمان: $difference');
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
        return _formatJalaliDate(date);
      }
    } catch (e) {
      developer.log('خطا در فرمت‌بندی تاریخ: $e');
      // در صورت خطا، تاریخ میلادی را برگردان
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
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
