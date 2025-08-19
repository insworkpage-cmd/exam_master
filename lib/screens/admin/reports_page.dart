import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/report_card.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  Map<String, dynamic>? _questionsReport;
  Map<String, dynamic>? _usersReport;
  Map<String, dynamic>? _quizzesReport;
  Map<String, dynamic>? _activityReport;
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllReports() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await Future.wait([
        ReportService.getQuestionsReport(),
        ReportService.getUsersReport(),
        ReportService.getQuizzesReport(),
        ReportService.getActivityReport(days: 7),
      ]);
      setState(() {
        _questionsReport = results[0];
        _usersReport = results[1];
        _quizzesReport = results[2];
        _activityReport = results[3];
      });
    } catch (e) {
      _showError('خطا در بارگذاری گزارش‌ها: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshReports() async {
    await _loadAllReports();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.currentUser == null) {
          return const Center(child: Text('لطفاً وارد شوید'));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('گزارش‌ها و تحلیل‌ها'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshReports,
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _exportReports,
              ),
            ],
          ),
          body: Column(
            children: [
              _buildTabBar(),
              const Divider(height: 1),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildReportContent(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.grey[100],
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.indigo,
        labelColor: Colors.indigo,
        unselectedLabelColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        tabs: const [
          Tab(text: 'سوالات'),
          Tab(text: 'کاربران'),
          Tab(text: 'آزمون‌ها'),
          Tab(text: 'فعالیت‌ها'),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildQuestionsReport();
      case 1:
        return _buildUsersReport();
      case 2:
        return _buildQuizzesReport();
      case 3:
        return _buildActivityReport();
      default:
        return const Center(child: Text('گزارشی یافت نشد'));
    }
  }

  Widget _buildQuestionsReport() {
    if (_questionsReport == null) {
      return const Center(child: Text('داده‌ای برای نمایش وجود ندارد'));
    }
    return RefreshIndicator(
      onRefresh: _refreshReports,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(
              title: 'مرور کلی سوالات',
              cards: [
                ReportCard(
                  title: 'کل سوالات',
                  value: _questionsReport!['total'].toString(),
                  icon: Icons.help_outline,
                  color: Colors.blue,
                ),
                ReportCard(
                  title: 'در انتظار تأیید',
                  value: _questionsReport!['pending'].toString(),
                  icon: Icons.hourglass_empty,
                  color: Colors.orange,
                ),
                ReportCard(
                  title: 'تأیید شده',
                  value: _questionsReport!['approved'].toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                ReportCard(
                  title: 'رد شده',
                  value: _questionsReport!['rejected'].toString(),
                  icon: Icons.cancel,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildInstructorStats(),
            const SizedBox(height: 24),
            _buildQuestionsChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersReport() {
    if (_usersReport == null) {
      return const Center(child: Text('داده‌ای برای نمایش وجود ندارد'));
    }
    return RefreshIndicator(
      onRefresh: _refreshReports,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(
              title: 'مرور کلی کاربران',
              cards: [
                ReportCard(
                  title: 'کل کاربران',
                  value: _usersReport!['total'].toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                ReportCard(
                  title: 'فعال',
                  value: _usersReport!['active'].toString(),
                  icon: Icons.person,
                  color: Colors.green,
                ),
                ReportCard(
                  title: 'غیرفعال',
                  value: _usersReport!['inactive'].toString(),
                  icon: Icons.person_off,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRoleDistribution(),
            const SizedBox(height: 24),
            _buildUserGrowthChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesReport() {
    if (_quizzesReport == null) {
      return const Center(child: Text('داده‌ای برای نمایش وجود ندارد'));
    }
    return RefreshIndicator(
      onRefresh: _refreshReports,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(
              title: 'مرور کلی آزمون‌ها',
              cards: [
                ReportCard(
                  title: 'کل آزمون‌ها',
                  value: _quizzesReport!['total'].toString(),
                  icon: Icons.quiz,
                  color: Colors.blue,
                ),
                ReportCard(
                  title: 'میانگین نمره',
                  value: _quizzesReport!['averageScore'],
                  icon: Icons.grade,
                  color: Colors.orange,
                ),
                ReportCard(
                  title: 'شرکت‌کنندگان',
                  value: _quizzesReport!['totalParticipants'].toString(),
                  icon: Icons.groups,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildQuizPerformanceChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityReport() {
    if (_activityReport == null) {
      return const Center(child: Text('داده‌ای برای نمایش وجود ندارد'));
    }
    return RefreshIndicator(
      onRefresh: _refreshReports,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(
              title: 'فعالیت‌های اخیر',
              cards: [
                ReportCard(
                  title: 'کل فعالیت‌ها',
                  value: _activityReport!['totalActivities'].toString(),
                  icon: Icons.insights,
                  color: Colors.blue,
                ),
                ReportCard(
                  title: 'دوره بررسی',
                  value: _activityReport!['period'],
                  icon: Icons.date_range,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildActivityChart(),
            const SizedBox(height: 24),
            _buildActivityTypes(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards({
    required String title,
    required List<ReportCard> cards,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cards.length > 3 ? 4 : cards.length,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: cards,
        ),
      ],
    );
  }

  Widget _buildInstructorStats() {
    final instructorStats =
        _questionsReport!['instructorStats'] as Map<String, dynamic>;
    if (instructorStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('هیچ مدرسی فعالیتی ندارد')),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'آمار بر اساس مدرس',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...instructorStats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      '${entry.value} سوال',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزیع وضعیت سوالات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: (_questionsReport!['pending'] ?? 0).toDouble(),
                      title: 'در انتظار',
                      color: Colors.orange,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: (_questionsReport!['approved'] ?? 0).toDouble(),
                      title: 'تأیید شده',
                      color: Colors.green,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: (_questionsReport!['rejected'] ?? 0).toDouble(),
                      title: 'رد شده',
                      color: Colors.red,
                      radius: 60,
                    ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleDistribution() {
    final roleStats = _usersReport!['roleStats'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزیع نقش‌های کاربران',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final roles = roleStats.keys.toList();
                          if (value.toInt() >= 0 &&
                              value.toInt() < roles.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                roles[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: roleStats.entries.map((entry) {
                    final index = roleStats.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.indigo,
                          width: 20,
                          borderRadius: const BorderRadius.all(
                              Radius.circular(4)), // ✅ اصلاح شد
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGrowthChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'رشد کاربران (فرضی)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 20),
                        FlSpot(1, 35),
                        FlSpot(2, 45),
                        FlSpot(3, 60),
                        FlSpot(4, 75),
                        FlSpot(5, 85),
                        FlSpot(6, 95),
                      ],
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true), // ✅ const اضافه شد
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizPerformanceChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'عملکرد آزمون‌ها (فرضی)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const subjects = ['ریاضی', 'فیزیک', 'شیمی', 'زیست'];
                          if (value.toInt() >= 0 &&
                              value.toInt() < subjects.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                subjects[value.toInt()],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: false)), // ✅ const اضافه شد
                    topTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: false)), // ✅ const اضافه شد
                    rightTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: false)), // ✅ const اضافه شد
                  ),
                  borderData: FlBorderData(
                      show: false), // ❌ const ندارد و نمی‌توان اضافه کرد
                  gridData: const FlGridData(
                      show: false), // ❌ const ندارد و نمی‌توان اضافه کرد
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 85.0,
                          color: Colors.blue,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 75.0,
                          color: Colors.green,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: 90.0,
                          color: Colors.orange,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: 70.0,
                          color: Colors.purple,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    final dailyActivities =
        _activityReport!['dailyActivities'] as Map<String, dynamic>;
    final dates = dailyActivities.keys.toList().reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فعالیت‌های روزانه',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < dates.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                dates[value.toInt()].split('-')[2],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 20 == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: false)), // ✅ const اضافه شد
                    rightTitles: const AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: false)), // ✅ const اضافه شد
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (dates.length - 1).toDouble(),
                  minY: 0,
                  maxY: dailyActivities.values
                          .fold(0, (max, value) => value > max ? value : max)
                          .toDouble() +
                      5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: dates.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          dailyActivities[entry.value]?.toDouble() ?? 0,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.indigo,
                      barWidth: 3,
                      dotData: const FlDotData(show: true), // ✅ const اضافه شد
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTypes() {
    final activityTypes =
        _activityReport!['activityTypes'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نوع فعالیت‌ها',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...activityTypes.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      '${entry.value} بار',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReports() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('خروجی گرفتن از گزارش‌ها به زودی اضافه می‌شود'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
