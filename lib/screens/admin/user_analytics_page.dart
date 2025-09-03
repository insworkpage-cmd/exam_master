import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as charts;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shamsi_date/shamsi_date.dart';
import 'dart:typed_data';
import 'dart:async';
import 'dart:io'; // برای استفاده از SocketException
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
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnalyticsData();
    });
  }

  Future<void> _loadAnalyticsData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final users = await authProvider.getAllUsers().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('زمان اتصال به سرور تمام شد');
        },
      );

      if (!mounted) return;

      _calculateBasicStats(users);
      _calculateAdvancedStats(users);

      if (!mounted) return;

      setState(() {
        _users = users;
        _isLoading = false;
      });
    } on TimeoutException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'خطا در اتصال به سرور: ${e.message}';
        _isLoading = false;
      });
    } on SocketException catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'خطا در اتصال به اینترنت. لطفاً اتصال خود را بررسی کنید.';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'خطا در بارگذاری داده‌ها: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateBasicStats(List<UserModel> users) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // امروز ساعت 00:00
    final oneHourAgo = now.subtract(const Duration(hours: 1)); // یک ساعت پیش

    _totalUsers = users.length;
    _onlineUsersCount = 0;
    _todayLoggedInUsersCount = 0;

    for (var role in UserRole.values) {
      _usersByRole[role] = 0;
      _onlineUsersByRole[role] = 0;
    }

    for (var user in users) {
      _usersByRole[user.role] = (_usersByRole[user.role] ?? 0) + 1;

      if (user.lastLogin != null) {
        // محاسبه کاربران آنلاین (فعال در یک ساعت اخیر)
        if (user.lastLogin!.isAfter(oneHourAgo)) {
          _onlineUsersCount++;
          _onlineUsersByRole[user.role] =
              (_onlineUsersByRole[user.role] ?? 0) + 1;
        }

        // محاسبه کاربران ورود امروز (از ساعت 00:00 بامداد)
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

    for (var user in users) {
      final monthKey =
          '${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}';
      _usersByMonth[monthKey] = (_usersByMonth[monthKey] ?? 0) + 1;
    }
  }

  List<UserModel> _getFilteredUsers() {
    List<UserModel> filteredUsers = List.from(_users);

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
              tooltip: 'بروزرسانی داده‌ها',
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAnalyticsData,
                          child: const Text('تلاش مجدد'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFiltersSection(),
                        const SizedBox(height: 20),
                        _buildBasicStatsSection(),
                        const SizedBox(height: 20),
                        _buildChartsSection(),
                        const SizedBox(height: 20),
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فیلترها',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      child: Text(
                        _startDate != null
                            ? _formatJalaliDate(_startDate!)
                            : 'تاریخ شروع را انتخاب کنید',
                        style: TextStyle(
                          color: _startDate != null
                              ? Colors.black
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      child: Text(
                        _endDate != null
                            ? _formatJalaliDate(_endDate!)
                            : 'تاریخ پایان را انتخاب کنید',
                        style: TextStyle(
                          color: _endDate != null
                              ? Colors.black
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'فیلتر نقش‌ها',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    FilterChip(
                      label: const Text('انتخاب همه',
                          style: TextStyle(fontSize: 10)),
                      selected: _selectedRoles.length == UserRole.values.length,
                      onSelected: (selected) {
                        if (mounted) {
                          setState(() {
                            if (selected) {
                              _selectedRoles.addAll(UserRole.values);
                            } else {
                              _selectedRoles.clear();
                            }
                          });
                        }
                      },
                      selectedColor: Colors.blue.withOpacity(0.2),
                      checkmarkColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                    ),
                    ...UserRole.values.map((role) {
                      final isSelected = _selectedRoles.contains(role);
                      return FilterChip(
                        label: Text(role.persianName,
                            style: const TextStyle(fontSize: 10)),
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
                            horizontal: 6, vertical: 2),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child:
                      const Text('حذف فیلترها', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicStatsSection() {
    // محاسبه اندازه مکعب فعلی
    final screenWidth = MediaQuery.of(context).size.width;
    const padding = 32.0; // padding صفحه (16 * 2)
    const spacing = 36.0; // فاصله بین کارت‌ها (12 * 3)
    final availableWidth = screenWidth - padding - spacing;
    final cubeSide = availableWidth / 4; // اندازه ضلع مکعب فعلی
    final rectangleWidth = cubeSide / 4; // عرض مستطیل جدید (یک‌چهارم ضلع مکعب)

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'آمار پایه',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Tooltip(
                    message: 'تعداد کل کاربران ثبت شده در سیستم',
                    child: SizedBox(
                      width: rectangleWidth,
                      child: _buildStatCard(
                          'کل کاربران', _totalUsers.toString(), Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message:
                        'تعداد کاربرانی که در حال حاضر آنلاین هستند', // اصلاح توضیح
                    child: SizedBox(
                      width: rectangleWidth,
                      child: _buildStatCard(
                          'آنلاین', _onlineUsersCount.toString(), Colors.green),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message:
                        'تعداد کاربرانی که امروز از ساعت 00:00 بامداد وارد سیستم شده‌اند', // اصلاح توضیح
                    child: SizedBox(
                      width: rectangleWidth,
                      child: _buildStatCard('ورود امروز',
                          _todayLoggedInUsersCount.toString(), Colors.orange),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Tooltip(
                    message: 'درصد کاربران فعال نسبت به کل کاربران',
                    child: SizedBox(
                      width: rectangleWidth,
                      child: _buildStatCard(
                        'نرخ فعالیت',
                        '${_totalUsers > 0 ? (_onlineUsersCount / _totalUsers * 100).toStringAsFixed(1) : '0'}%',
                        Colors.purple,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
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
              fontSize: 10,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
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
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'توزیع کاربران بر اساس نقش',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: _buildCombinedRoleChart(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'رشد ماهانه کاربران',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: _buildMonthlyGrowthChart(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'توزیع کاربران (نمودار دایره‌ای)',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
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
    List<ChartData> chartData = [];
    List<ChartData> onlineChartData = [];

    for (var role in UserRole.values) {
      chartData.add(ChartData(role.persianName,
          (_usersByRole[role] ?? 0).toDouble(), _getRoleColor(role)));
      onlineChartData.add(ChartData(role.persianName,
          (_onlineUsersByRole[role] ?? 0).toDouble(), _getRoleColor(role)));
    }

    return charts.SfCartesianChart(
      primaryXAxis: charts.CategoryAxis(
        labelStyle: const TextStyle(fontSize: 9),
        labelRotation: -45,
      ),
      primaryYAxis: charts.NumericAxis(
        labelStyle: const TextStyle(fontSize: 9),
      ),
      tooltipBehavior: charts.TooltipBehavior(
        enable: true,
        header: '',
        format: 'point.x : point.y کاربر',
        canShowMarker: true,
      ),
      series: <charts.CartesianSeries>[
        charts.ColumnSeries<ChartData, String>(
          dataSource: chartData,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          pointColorMapper: (ChartData data, _) => data.color,
          name: 'کل کاربران',
          dataLabelSettings: const charts.DataLabelSettings(isVisible: false),
          width: 0.4,
          spacing: 0.2,
        ),
        charts.ColumnSeries<ChartData, String>(
          dataSource: onlineChartData,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y,
          pointColorMapper: (ChartData data, _) => data.color,
          name: 'کاربران آنلاین',
          dataLabelSettings: const charts.DataLabelSettings(isVisible: false),
          width: 0.4,
          spacing: 0.2,
        ),
      ],
    );
  }

  Widget _buildMonthlyGrowthChart() {
    List<GrowthData> chartData = [];

    final sortedMonths = _usersByMonth.keys.toList()..sort();
    for (int i = 0; i < sortedMonths.length; i++) {
      final month = sortedMonths[i];
      final parts = month.split('-');
      final monthInt = int.parse(parts[1]);
      final yearInt = int.parse(parts[0]);

      chartData.add(GrowthData('$monthInt',
          (_usersByMonth[month] ?? 0).toDouble(), yearInt, monthInt));
    }

    return charts.SfCartesianChart(
      primaryXAxis: charts.CategoryAxis(
        labelStyle: const TextStyle(fontSize: 9),
        title: charts.AxisTitle(
            text: 'ماه', textStyle: const TextStyle(fontSize: 10)),
      ),
      primaryYAxis: charts.NumericAxis(
        labelStyle: const TextStyle(fontSize: 9),
        title: charts.AxisTitle(
            text: 'تعداد کاربران', textStyle: const TextStyle(fontSize: 10)),
      ),
      tooltipBehavior: charts.TooltipBehavior(
        enable: true,
        header: '',
        format: 'ماه point.x: point.y کاربر',
        canShowMarker: true,
      ),
      series: <charts.CartesianSeries>[
        charts.LineSeries<GrowthData, String>(
          dataSource: chartData,
          xValueMapper: (GrowthData data, _) => data.month,
          yValueMapper: (GrowthData data, _) => data.count,
          name: 'رشد کاربران',
          markerSettings: const charts.MarkerSettings(isVisible: true),
          dataLabelSettings: const charts.DataLabelSettings(isVisible: false),
          color: Colors.blue,
          width: 2,
          animationDuration: 0,
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    List<PieData> chartData = [];

    for (var role in UserRole.values) {
      chartData.add(PieData(
          role.persianName,
          (_usersByRole[role] ?? 0).toDouble(),
          _getRoleColor(role),
          (_onlineUsersByRole[role] ?? 0),
          _getTodayLoggedInCountForRole(role)));
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: charts.SfCircularChart(
            tooltipBehavior: charts.TooltipBehavior(
              enable: true,
              header: '',
              format: 'point.x: point.y کاربر',
              canShowMarker: true,
            ),
            legend: const charts.Legend(
              isVisible: false,
            ),
            series: <charts.CircularSeries>[
              charts.DoughnutSeries<PieData, String>(
                dataSource: chartData,
                xValueMapper: (PieData data, _) => data.role,
                yValueMapper: (PieData data, _) => data.count,
                pointColorMapper: (PieData data, _) => data.color,
                dataLabelSettings: const charts.DataLabelSettings(
                  isVisible: true,
                  labelPosition: charts.ChartDataLabelPosition.outside,
                  labelIntersectAction: charts.LabelIntersectAction.shift,
                  connectorLineSettings: charts.ConnectorLineSettings(
                    type: charts.ConnectorType.line,
                    length: '10%',
                  ),
                ),
                radius: '70%',
                innerRadius: '40%',
                explode: true,
                explodeIndex: 0,
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: UserRole.values.take(3).map((role) {
                          return _buildRoleDetail(role);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: UserRole.values.skip(3).map((role) {
                          return _buildRoleDetail(role);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDetail(UserRole role) {
    final count = _usersByRole[role] ?? 0;
    final totalUsers = _usersByRole.values.fold(0, (sum, count) => sum + count);
    final percentage = totalUsers > 0 ? (count / totalUsers) * 100 : 0;
    final onlineCount = _onlineUsersByRole[role] ?? 0;
    final onlinePercentage = count > 0 ? (onlineCount / count) * 100 : 0;
    final todayLoggedInCount = _getTodayLoggedInCountForRole(role);

    return Tooltip(
      message: '${role.persianName}\n'
          'کل: $count کاربر (${percentage.toStringAsFixed(1)}%)\n'
          'آنلاین: $onlineCount کاربر (${onlinePercentage.toStringAsFixed(1)}%)\n'
          'ورود امروز: $todayLoggedInCount کاربر',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _getRoleColor(role).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _getRoleColor(role).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    color: _getRoleColor(role),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      role.persianName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'کل: $count',
                      style: const TextStyle(fontSize: 8),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'آنلاین: $onlineCount',
                      style: const TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'امروز: $todayLoggedInCount',
                      style: const TextStyle(fontSize: 8),
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

  int _getTodayLoggedInCountForRole(UserRole role) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // امروز ساعت 00:00

    return _users.where((user) {
      return user.role == role &&
          user.lastLogin != null &&
          DateTime(user.lastLogin!.year, user.lastLogin!.month,
                  user.lastLogin!.day) ==
              today;
    }).length;
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
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'لیست کاربران',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'تعداد: ${filteredUsers.length}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 8,
                headingRowHeight: 32,
                dataRowMinHeight: 40,
                dataRowMaxHeight: 40,
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 18),
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
                  style: const TextStyle(fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 18),
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
    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1)); // یک ساعت پیش

    final isOnline =
        user.lastLogin != null && user.lastLogin!.isAfter(oneHourAgo);

    return Tooltip(
      message: isOnline
          ? 'کاربر آنلاین است\nآخرین فعالیت: ${_formatJalaliDate(user.lastLogin!)}'
          : 'کاربر آفلاین است\nآخرین فعالیت: ${user.lastLogin != null ? _formatJalaliDate(user.lastLogin!) : 'ثبت نشده'}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            isOnline ? 'آنلاین' : 'آفلاین',
            style: TextStyle(
              fontSize: 10,
              color: isOnline ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    final pdf = pw.Document();

    final ByteData regularFontData =
        await rootBundle.load('lib/assets/fonts/Vazirmatn-Regular.ttf');
    final ByteData boldFontData =
        await rootBundle.load('lib/assets/fonts/Vazirmatn-Bold.ttf');

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
              pw.Text('توزیع کاربران بر اساس نقش',
                  style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  ['نقش', 'تعداد کل', 'آنلاین', 'ورود امروز'],
                  ...UserRole.values.map((role) => [
                        role.persianName,
                        (_usersByRole[role] ?? 0).toString(),
                        (_onlineUsersByRole[role] ?? 0).toString(),
                        _getTodayLoggedInCountForRole(role).toString(),
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
              pw.Text('نمودار توزیع کاربران',
                  style: pw.TextStyle(font: boldFont, fontSize: 16)),
              pw.SizedBox(height: 10),
              _buildPieChartForPDF(pdf, regularFont, boldFont),
              pw.SizedBox(height: 20),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'user_analytics_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  pw.Widget _buildPieChartForPDF(
      pw.Document pdf, pw.Font regularFont, pw.Font boldFont) {
    final totalUsers = _usersByRole.values.fold(0, (sum, count) => sum + count);
    return pw.SizedBox(
      height: 200,
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Text(
                      'نمودار دایره‌ای در اینجا نمایش داده می‌شود',
                      style: pw.TextStyle(font: regularFont, fontSize: 12),
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  height: 100,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'نمودار دایره‌ای',
                      style: pw.TextStyle(font: boldFont, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: UserRole.values.map((role) {
                final count = _usersByRole[role] ?? 0;
                final percentage =
                    totalUsers > 0 ? (count / totalUsers) * 100 : 0;
                final onlineCount = _onlineUsersByRole[role] ?? 0;
                final onlinePercentage =
                    count > 0 ? (onlineCount / count) * 100 : 0;
                final todayLoggedInCount = _getTodayLoggedInCountForRole(role);
                return pw.Container(
                  margin: const pw.EdgeInsets.all(2),
                  padding: const pw.EdgeInsets.all(4),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 8,
                            height: 8,
                            color: _getPdfColor(role),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            role.persianName,
                            style: pw.TextStyle(font: boldFont, fontSize: 10),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'کل: $count نفر (${percentage.toStringAsFixed(1)}%)',
                        style: pw.TextStyle(font: regularFont, fontSize: 8),
                      ),
                      pw.Text(
                        'آنلاین: $onlineCount نفر (${onlinePercentage.toStringAsFixed(1)}%)',
                        style: pw.TextStyle(font: regularFont, fontSize: 8),
                      ),
                      pw.Text(
                        'ورود امروز: $todayLoggedInCount نفر',
                        style: pw.TextStyle(font: regularFont, fontSize: 8),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  PdfColor _getPdfColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return PdfColors.red;
      case UserRole.moderator:
        return PdfColors.orange;
      case UserRole.instructor:
        return PdfColors.green;
      case UserRole.student:
        return PdfColors.blue;
      case UserRole.normaluser:
        return PdfColors.grey;
      default:
        return PdfColors.grey;
    }
  }

  Future<void> _printReport() async {
    final pdf = pw.Document();

    final ByteData regularFontData =
        await rootBundle.load('lib/assets/fonts/Vazirmatn-Regular.ttf');
    final ByteData boldFontData =
        await rootBundle.load('lib/assets/fonts/Vazirmatn-Bold.ttf');

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

// کلاس‌های کمکی برای نمودارها
class ChartData {
  final String x;
  final double y;
  final Color color;

  ChartData(this.x, this.y, this.color);
}

class GrowthData {
  final String month;
  final double count;
  final int year;
  final int monthNumber;

  GrowthData(this.month, this.count, this.year, this.monthNumber);
}

class PieData {
  final String role;
  final double count;
  final Color color;
  final int onlineCount;
  final int todayLoggedInCount;

  PieData(this.role, this.count, this.color, this.onlineCount,
      this.todayLoggedInCount);
}
