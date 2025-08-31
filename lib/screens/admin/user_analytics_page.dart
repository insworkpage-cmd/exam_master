import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shamsi_date/shamsi_date.dart';
import 'dart:typed_data';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../widgets/persian_calendar_widget.dart';

class UserAnalyticsPage extends StatefulWidget {
  const UserAnalyticsPage({super.key});

  @override
  State<UserAnalyticsPage> createState() => _UserAnalyticsPageState();
}

class _UserAnalyticsPageState extends State<UserAnalyticsPage> {
  bool _isLoading = true;
  String _errorMessage = '';

  // متغیرهای آمار
  int _totalUsers = 0;
  int _onlineUsersCount = 0;
  int _todayLoggedInUsersCount = 0;
  final Map<UserRole, int> _usersByRole = {};
  final Map<UserRole, int> _onlineUsersByRole = {};
  Map<String, int> _usersByMonth = {};
  List<UserModel> _users = [];

  // متغیرهای فیلتر
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<UserRole> _selectedRoles = {};

  // متغیرهای صفحه‌بندی جدول کاربران
  int _currentPage = 1;
  final int _pageSize = 10; // تغییر به final

  @override
  void initState() {
    super.initState();
    // استفاده از WidgetsBinding برای اطمینان از ساخت کامل ویجت قبل از بارگذاری داده‌ها
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalyticsData();
    });
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return; // بررسی اینکه ویجت هنوز در درخت ویجت است

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // دریافت نسخه از Provider بدون استفاده از setState در حین build
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final users = await authProvider.getAllUsers();

      if (!mounted) return; // بررسی مجدد پس از عملیات ناهمگام

      // محاسبه آمار پایه
      _calculateBasicStats(users);

      // محاسبه آمار پیشرفته
      _calculateAdvancedStats(users);

      if (!mounted) return; // بررسی مجدد قبل از setState

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // بررسی مجدد قبل از setState

      setState(() {
        _errorMessage = 'خطا در بارگذاری داده‌ها: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateBasicStats(List<UserModel> users) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    _totalUsers = users.length;
    _onlineUsersCount = 0;
    _todayLoggedInUsersCount = 0;

    // مقداردهی اولیه نقش‌ها
    for (var role in UserRole.values) {
      _usersByRole[role] = 0;
      _onlineUsersByRole[role] = 0;
    }

    for (var user in users) {
      // شمارش کاربران بر اساس نقش
      _usersByRole[user.role] = (_usersByRole[user.role] ?? 0) + 1;

      // محاسبه کاربران آنلاین
      if (user.lastLogin != null) {
        if (user.lastLogin!.isAfter(twentyFourHoursAgo)) {
          _onlineUsersCount++;
          _onlineUsersByRole[user.role] =
              (_onlineUsersByRole[user.role] ?? 0) + 1;
        }

        // محاسبه کاربران ورود امروز
        final loginDate = DateTime(
            user.lastLogin!.year, user.lastLogin!.month, user.lastLogin!.day);
        if (loginDate == today) {
          _todayLoggedInUsersCount++;
        }
      }
    }
  }

  void _calculateAdvancedStats(List<UserModel> users) {
    _usersByMonth = {};

    // محاسبه کاربران بر اساس ماه
    for (var user in users) {
      final monthKey =
          '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}';
      _usersByMonth[monthKey] = (_usersByMonth[monthKey] ?? 0) + 1;
    }
  }

  List<UserModel> _getFilteredUsers() {
    List<UserModel> filteredUsers = List.from(_users);

    // اعمال فیلتر تاریخ
    if (_startDate != null) {
      filteredUsers = filteredUsers
          .where((user) => user.createdAt.isAfter(_startDate!))
          .toList();
    }

    if (_endDate != null) {
      filteredUsers = filteredUsers
          .where((user) => user.createdAt.isBefore(_endDate!))
          .toList();
    }

    // اعمال فیلتر نقش
    if (_selectedRoles.isNotEmpty) {
      filteredUsers = filteredUsers
          .where((user) => _selectedRoles.contains(user.role))
          .toList();
    }

    return filteredUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('آمار پیشرفته کاربران'),
          backgroundColor: Colors.blue,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadAnalyticsData,
              tooltip: 'بروزرسانی',
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'pdf':
                    _exportToPDF();
                    break;
                  case 'print':
                    _printReport();
                    break;
                }
              },
              itemBuilder: (context) => [
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
                  value: 'print',
                  child: Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('چاپ گزارش'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // بخش فیلترها
                        _buildFiltersSection(),
                        const SizedBox(height: 20),

                        // بخش آمار پایه
                        _buildBasicStatsSection(),
                        const SizedBox(height: 20),

                        // بخش نمودارها
                        _buildChartsSection(),
                        const SizedBox(height: 20),

                        // بخش جدول کاربران
                        _buildUsersTable(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // کاهش padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فیلترها',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold), // کاهش اندازه فونت
            ),
            const SizedBox(height: 12), // کاهش فاصله
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
                      if (picked != null && mounted) {
                        setState(() {
                          _startDate = picked.toDateTime();
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'از تاریخ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8), // کاهش padding
                      ),
                      child: Text(
                        _startDate != null
                            ? _formatJalaliDate(_startDate!)
                            : 'تاریخ شروع را انتخاب کنید',
                        style: TextStyle(
                          color: _startDate != null
                              ? Colors.black
                              : Colors.grey[600],
                          fontSize: 12, // کاهش اندازه فونت
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // کاهش فاصله
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
                      if (picked != null && mounted) {
                        setState(() {
                          _endDate = picked.toDateTime();
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تا تاریخ',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8), // کاهش padding
                      ),
                      child: Text(
                        _endDate != null
                            ? _formatJalaliDate(_endDate!)
                            : 'تاریخ پایان را انتخاب کنید',
                        style: TextStyle(
                          color: _endDate != null
                              ? Colors.black
                              : Colors.grey[600],
                          fontSize: 12, // کاهش اندازه فونت
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8), // کاهش فاصله
            // فیلتر چند انتخابی نقش
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'فیلتر نقش‌ها',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold), // کاهش اندازه فونت
                ),
                const SizedBox(height: 6), // کاهش فاصله
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: UserRole.values.map((role) {
                    final isSelected = _selectedRoles.contains(role);
                    return FilterChip(
                      label: Text(role.persianName,
                          style: const TextStyle(
                              fontSize: 10)), // کاهش اندازه فونت
                      selected: isSelected,
                      onSelected: (selected) {
                        if (mounted) {
                          setState(() {
                            if (selected) {
                              _selectedRoles.add(role);
                            } else {
                              _selectedRoles.remove(role);
                            }
                          });
                        }
                      },
                      selectedColor: _getRoleColor(role).withOpacity(0.2),
                      checkmarkColor: _getRoleColor(role),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2), // کاهش padding
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 8), // کاهش فاصله
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectedRoles.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6), // کاهش padding
                  ),
                  child: const Text('حذف فیلترها',
                      style: TextStyle(fontSize: 12)), // کاهش اندازه فونت
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicStatsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // کاهش padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'آمار پایه',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold), // کاهش اندازه فونت
            ),
            const SizedBox(height: 12), // کاهش فاصله
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 12, // کاهش فاصله
              mainAxisSpacing: 12, // کاهش فاصله
              childAspectRatio: 1.0,
              children: [
                _buildStatCard(
                    'کل کاربران', _totalUsers.toString(), Colors.blue),
                _buildStatCard(
                    'آنلاین', _onlineUsersCount.toString(), Colors.green),
                _buildStatCard('ورود امروز',
                    _todayLoggedInUsersCount.toString(), Colors.orange),
                _buildStatCard(
                  'نرخ فعالیت',
                  '${_totalUsers > 0 ? (_onlineUsersCount / _totalUsers * 100).toStringAsFixed(1) : '0'}%',
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(6), // کاهش padding
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10, // کاهش اندازه فونت
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2), // کاهش فاصله
          Text(
            value,
            style: TextStyle(
              fontSize: 16, // کاهش اندازه فونت
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      children: [
        // نمودار ترکیبی کاربران بر اساس نقش
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0), // کاهش padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'توزیع کاربران بر اساس نقش',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold), // کاهش اندازه فونت
                ),
                const SizedBox(height: 12), // کاهش فاصله
                SizedBox(
                  height: 180, // کاهش ارتفاع
                  child: _buildCombinedRoleChart(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12), // کاهش فاصله

        // ردیف دوم: نمودار رشد ماهانه و نمودار دایره‌ای
        Row(
          children: [
            // نمودار رشد ماهانه
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // کاهش padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'رشد ماهانه کاربران',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold), // کاهش اندازه فونت
                      ),
                      const SizedBox(height: 12), // کاهش فاصله
                      SizedBox(
                        height: 180, // کاهش ارتفاع
                        child: _buildMonthlyGrowthChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12), // کاهش فاصله
            // نمودار دایره‌ای
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // کاهش padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'توزیع کاربران (نمودار دایره‌ای)',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold), // کاهش اندازه فونت
                      ),
                      const SizedBox(height: 12), // کاهش فاصله
                      SizedBox(
                        height: 180, // کاهش ارتفاع
                        child: _buildPieChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCombinedRoleChart() {
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < UserRole.values.length; i++) {
      final role = UserRole.values[i];
      barGroups.add(
        BarChartGroupData(
          x: i, // استفاده از int به جای double
          barRods: [
            // میله برای کل کاربران
            BarChartRodData(
              toY: (_usersByRole[role] ?? 0).toDouble(),
              color: _getRoleColor(role).withOpacity(0.7),
              width: 14, // کاهش عرض
              borderRadius: BorderRadius.zero,
            ),
            // میله برای کاربران آنلاین
            BarChartRodData(
              toY: (_onlineUsersByRole[role] ?? 0).toDouble(),
              color: _getRoleColor(role),
              width: 14, // کاهش عرض
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < UserRole.values.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      UserRole.values[index].persianName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 9, // کاهش اندازه فونت
                      ),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30, // کاهش ارتفاع
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
      ),
    );
  }

  Widget _buildMonthlyGrowthChart() {
    final sortedMonths = _usersByMonth.keys.toList()..sort();
    final List<FlSpot> spots = [];

    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final parts = month.split('-');
      final monthInt = int.parse(parts[1]);
      spots.add(FlSpot(
        monthInt.toDouble(),
        _usersByMonth[month]!.toDouble(),
      ));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24, // کاهش ارتفاع
              getTitlesWidget: (value, meta) {
                if (value.toInt() > 0 && value.toInt() <= 12) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 9, // کاهش اندازه فونت
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() > 0) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 9, // کاهش اندازه فونت
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 24, // کاهش ارتفاع
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        minX: 1,
        maxX: 12,
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2, // کاهش عرض
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3, // کاهش اندازه
                  color: Colors.blue,
                  strokeWidth: 1, // کاهش ضخامت
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final List<PieChartSectionData> sections = [];
    int totalUsers = _usersByRole.values.fold(0, (sum, count) => sum + count);

    // کد اصلاح شده
// کد اصلاح شده
    for (int i = 0; i < UserRole.values.length; i++) {
      final role = UserRole.values[i];
      final count = _usersByRole[role] ?? 0;
      final percentage = totalUsers > 0 ? (count / totalUsers) * 100 : 0;
      // حذف متغیر استفاده نشده
      // final onlineCount = _onlineUsersByRole[role] ?? 0;

      sections.add(
        PieChartSectionData(
          color: _getRoleColor(role),
          value: count.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: null,
          badgePositionPercentageOffset: 0,
        ),
      );
    }

    return SizedBox(
      height: 180, // کاهش ارتفاع
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 25, // کاهش اندازه
          sectionsSpace: 2,
          startDegreeOffset: -90,
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
    final filteredUsers = _getFilteredUsers();
    final totalPages = (filteredUsers.length / _pageSize).ceil();
    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = startIndex + _pageSize;
    final paginatedUsers = filteredUsers.sublist(
      startIndex,
      endIndex > filteredUsers.length ? filteredUsers.length : endIndex,
    );

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0), // کاهش padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'لیست کاربران',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold), // کاهش اندازه فونت
                ),
                Text(
                  'تعداد: ${filteredUsers.length}',
                  style: const TextStyle(fontSize: 12), // کاهش اندازه فونت
                ),
              ],
            ),
            const SizedBox(height: 12), // کاهش فاصله
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 8, // کاهش فاصله بین ستون‌ها
                headingRowHeight: 32, // کاهش ارتفاع هدر
                dataRowMinHeight:
                    40, // استفاده از dataRowMinHeight به جای dataRowHeight
                dataRowMaxHeight:
                    40, // استفاده از dataRowMaxHeight به جای dataRowHeight
                columns: const [
                  DataColumn(
                      label: Text('نام', style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label: Text('ایمیل', style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label: Text('نقش', style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label:
                          Text('تاریخ عضویت', style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label:
                          Text('آخرین ورود', style: TextStyle(fontSize: 12))),
                  DataColumn(
                      label: Text('وضعیت', style: TextStyle(fontSize: 12))),
                ],
                rows: paginatedUsers.map((user) {
                  return DataRow(
                    cells: [
                      DataCell(Text(user.name,
                          style: const TextStyle(fontSize: 11))),
                      DataCell(Text(user.email,
                          style: const TextStyle(fontSize: 11))),
                      DataCell(Text(user.role.persianName,
                          style: const TextStyle(fontSize: 11))),
                      DataCell(Text(_formatJalaliDate(user.createdAt),
                          style: const TextStyle(fontSize: 11))),
                      DataCell(Text(
                          user.lastLogin != null
                              ? _formatJalaliDate(user.lastLogin!)
                              : 'هرگز',
                          style: const TextStyle(fontSize: 11))),
                      DataCell(_buildStatusIndicator(user)),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12), // کاهش فاصله
            // بخش صفحه‌بندی
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18), // کاهش اندازه
                  onPressed: _currentPage > 1
                      ? () {
                          if (mounted) {
                            setState(() {
                              _currentPage--;
                            });
                          }
                        }
                      : null,
                ),
                Text(
                  'صفحه $_currentPage از $totalPages',
                  style: const TextStyle(fontSize: 12), // کاهش اندازه فونت
                ),
                IconButton(
                  icon:
                      const Icon(Icons.arrow_forward, size: 18), // کاهش اندازه
                  onPressed: _currentPage < totalPages
                      ? () {
                          if (mounted) {
                            setState(() {
                              _currentPage++;
                            });
                          }
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(UserModel user) {
    final isOnline = user.lastLogin != null &&
        user.lastLogin!
            .isAfter(DateTime.now().subtract(const Duration(hours: 1)));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, // کاهش اندازه
          height: 6, // کاهش اندازه
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3), // کاهش فاصله
        Text(
          isOnline ? 'آنلاین' : 'آفلاین',
          style: TextStyle(
            fontSize: 10, // کاهش اندازه فونت
            color: isOnline ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _exportToPDF() async {
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
                child: pw.Text('گزارش آمار کاربران',
                    style: pw.TextStyle(font: boldFont, fontSize: 24)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('تاریخ گزارش: ${_formatJalaliDate(DateTime.now())}',
                  style: pw.TextStyle(font: regularFont, fontSize: 12)),
              pw.SizedBox(height: 20),

              // بخش آمار پایه
              pw.Text('آمار پایه',
                  style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['نشانگر', 'مقدار'],
                  ['کل کاربران', _totalUsers.toString()],
                  ['کاربران آنلاین', _onlineUsersCount.toString()],
                  ['ورود امروز', _todayLoggedInUsersCount.toString()],
                  [
                    'نرخ فعالیت',
                    '${_totalUsers > 0 ? (_onlineUsersCount / _totalUsers * 100).toStringAsFixed(1) : '0'}%'
                  ],
                ],
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 12),
                cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerRight,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
              pw.SizedBox(height: 20),

              // بخش توزیع بر اساس نقش
              pw.Text('توزیع کاربران بر اساس نقش',
                  style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['نقش', 'تعداد کل', 'آنلاین'],
                  ...UserRole.values.map((role) => [
                        role.persianName,
                        (_usersByRole[role] ?? 0).toString(),
                        (_onlineUsersByRole[role] ?? 0).toString(),
                      ]),
                ],
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 12),
                cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerRight,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
              pw.SizedBox(height: 20),

              // بخش لیست کاربران
              pw.Text('لیست کاربران',
                  style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['نام', 'ایمیل', 'نقش', 'تاریخ عضویت', 'آخرین ورود'],
                  ..._getFilteredUsers().map((user) => [
                        user.name,
                        user.email,
                        user.role.persianName,
                        _formatJalaliDate(user.createdAt),
                        user.lastLogin != null
                            ? _formatJalaliDate(user.lastLogin!)
                            : 'هرگز',
                      ]),
                ],
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
                cellStyle: pw.TextStyle(font: regularFont, fontSize: 8),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerRight,
                cellPadding: const pw.EdgeInsets.all(3),
              ),
            ],
          ),
        ),
      ),
    );

    // ذخیره فایل
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'user_analytics_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> _printReport() async {
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
                child: pw.Text('گزارش آمار کاربران',
                    style: pw.TextStyle(font: boldFont, fontSize: 24)),
              ),
              pw.SizedBox(height: 20),
              pw.Text('تاریخ گزارش: ${_formatJalaliDate(DateTime.now())}',
                  style: pw.TextStyle(font: regularFont, fontSize: 12)),
              pw.SizedBox(height: 20),

              // بخش آمار پایه
              pw.Text('آمار پایه',
                  style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['نشانگر', 'مقدار'],
                  ['کل کاربران', _totalUsers.toString()],
                  ['کاربران آنلاین', _onlineUsersCount.toString()],
                  ['ورود امروز', _todayLoggedInUsersCount.toString()],
                  [
                    'نرخ فعالیت',
                    '${_totalUsers > 0 ? (_onlineUsersCount / _totalUsers * 100).toStringAsFixed(1) : '0'}%'
                  ],
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

    // چاپ مستقیم با استفاده از متد جدید
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'user_analytics_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  String _formatJalaliDate(DateTime date) {
    try {
      final jalali = Jalali.fromDateTime(date);
      return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    }
  }

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
}
