import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/auth_provider.dart';
import '../../services/analytics_service.dart';
import '../../widgets/report_card.dart';
import '../../widgets/loading_widget.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = false;
  String _selectedTab = 'overview';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await AnalyticsService.getDashboardAnalytics();
      setState(() {
        _dashboardData = data;
      });
    } catch (e) {
      _showError('خطا در بارگذاری داده‌های تحلیلی: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadDashboardData();
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
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
            title: const Text('داشبورد تحلیلی'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshData,
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: _exportAnalytics,
              ),
            ],
          ),
          body: Column(
            children: [
              _buildTabBar(),
              const Divider(height: 1),
              Expanded(
                child: _isLoading
                    ? const LoadingWidget()
                    : _buildDashboardContent(),
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
            _selectedTab = ['overview', 'users', 'quizzes', 'questions'][index];
          });
        },
        tabs: const [
          Tab(text: 'مرور کلی'),
          Tab(text: 'کاربران'),
          Tab(text: 'آزمون‌ها'),
          Tab(text: 'سوالات'),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_dashboardData == null) {
      return const Center(child: Text('داده‌ای برای نمایش وجود ندارد'));
    }
    switch (_selectedTab) {
      case 'overview':
        return _buildOverviewTab();
      case 'users':
        return _buildUsersTab();
      case 'quizzes':
        return _buildQuizzesTab();
      case 'questions':
        return _buildQuestionsTab();
      default:
        return const Center(child: Text('تبی انتخاب نشده'));
    }
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKeyMetrics(),
            const SizedBox(height: 24),
            _buildUserGrowthChart(),
            const SizedBox(height: 24),
            _buildActivityHeatmap(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserStats(),
            const SizedBox(height: 24),
            _buildUserActivityChart(),
            const SizedBox(height: 24),
            _buildUserDemographics(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuizStats(),
            const SizedBox(height: 24),
            _buildQuizPerformanceChart(),
            const SizedBox(height: 24),
            _buildSubjectPerformance(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildQuestionStats(),
            const SizedBox(height: 24),
            _buildQuestionApprovalChart(),
            const SizedBox(height: 24),
            _buildQuestionCategories(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics() {
    final userGrowth = _dashboardData!['userGrowth'] as Map<String, dynamic>;
    final quizPerformance =
        _dashboardData!['quizPerformance'] as Map<String, dynamic>;
    final questionStats =
        _dashboardData!['questionStats'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'شاخصه‌های کلیدی',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            ReportCard(
              title: 'کل کاربران',
              value: userGrowth['totalUsers'].toString(),
              icon: Icons.people,
              color: Colors.blue,
              subtitle: 'رشد: ${userGrowth['growthRate']}%',
            ),
            ReportCard(
              title: 'آزمون‌ها',
              value: quizPerformance['totalQuizzes'].toString(),
              icon: Icons.quiz,
              color: Colors.green,
              subtitle: 'میانگین: ${quizPerformance['averageScore']}',
            ),
            ReportCard(
              title: 'سوالات',
              value: questionStats['totalQuestions'].toString(),
              icon: Icons.help,
              color: Colors.orange,
              subtitle: 'تأیید شده: ${questionStats['approvedQuestions']}',
            ),
            ReportCard(
              title: 'فعالیت‌ها',
              value: _dashboardData!['activityTrends']['totalActivities']
                  .toString(),
              icon: Icons.local_activity,
              color: Colors.purple,
              subtitle: '7 روز گذشته',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserGrowthChart() {
    final userGrowth = _dashboardData!['userGrowth'] as Map<String, dynamic>;
    final dailyGrowth = userGrowth['dailyGrowth'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'رشد کاربران',
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
                          final dates =
                              dailyGrowth.keys.toList().reversed.toList();
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
                          if (value.toInt() % 5 == 0) {
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
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (dailyGrowth.length - 1).toDouble(),
                  minY: 0,
                  maxY: dailyGrowth.values
                          .fold(0, (max, value) => value > max ? value : max)
                          .toDouble() +
                      5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyGrowth.entries.map((entry) {
                        final index =
                            dailyGrowth.keys.toList().indexOf(entry.key);
                        return FlSpot(
                          index.toDouble(),
                          entry.value.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
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

  Widget _buildActivityHeatmap() {
    final activityTrends =
        _dashboardData!['activityTrends'] as Map<String, dynamic>;
    final hourlyActivity = activityTrends['hourlyActivity'] as Map<int, int>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نقشه فعالیت ساعتی',
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
                          if (value.toInt() % 6 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${value.toInt()}',
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
                  barGroups: hourlyActivity.entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key, // اصلاح: استفاده از int به جای double
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.orange,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
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

  Widget _buildUserStats() {
    final userGrowth = _dashboardData!['userGrowth'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آمار کاربران',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            ReportCard(
              title: 'کل کاربران',
              value: userGrowth['totalUsers'].toString(),
              icon: Icons.people,
              color: Colors.blue,
            ),
            ReportCard(
              title: 'کاربران جدید',
              value: userGrowth['newUsers'].toString(),
              icon: Icons.person_add,
              color: Colors.green,
            ),
            ReportCard(
              title: 'نرخ رشد',
              value: '${userGrowth['growthRate']}%',
              icon: Icons.trending_up,
              color: userGrowth['growthRate'].toString().contains('-')
                  ? Colors.red
                  : Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserActivityChart() {
    final activityTrends =
        _dashboardData!['activityTrends'] as Map<String, dynamic>;
    final dailyActivity =
        activityTrends['dailyActivity'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فعالیت روزانه کاربران',
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
                          final dates =
                              dailyActivity.keys.toList().reversed.toList();
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
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: dailyActivity.entries.map((entry) {
                    final index =
                        dailyActivity.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index, // اصلاح: استفاده از int به جای double
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: Colors.blue,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
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

  Widget _buildUserDemographics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'دموگرافیک کاربران (فرضی)',
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
                      value: 45,
                      title: 'مرد',
                      color: Colors.blue,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: 55,
                      title: 'زن',
                      color: Colors.pink,
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

  Widget _buildQuizStats() {
    final quizPerformance =
        _dashboardData!['quizPerformance'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آمار آزمون‌ها',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            ReportCard(
              title: 'کل آزمون‌ها',
              value: quizPerformance['totalQuizzes'].toString(),
              icon: Icons.quiz,
              color: Colors.green,
            ),
            ReportCard(
              title: 'میانگین نمره',
              value: quizPerformance['averageScore'],
              icon: Icons.grade,
              color: Colors.orange,
            ),
            ReportCard(
              title: 'شرکت‌کنندگان',
              value: quizPerformance['totalParticipants'].toString(),
              icon: Icons.groups,
              color: Colors.purple,
            ),
            ReportCard(
              title: 'نرخ تکمیل',
              value: '${quizPerformance['completionRate']}%',
              icon: Icons.task_alt,
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizPerformanceChart() {
    final quizPerformance =
        _dashboardData!['quizPerformance'] as Map<String, dynamic>;
    final scoreDistribution =
        quizPerformance['scoreDistribution'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزیع نمرات',
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
                          final ranges = scoreDistribution.keys.toList();
                          if (value.toInt() >= 0 &&
                              value.toInt() < ranges.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                ranges[value.toInt()],
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
                  barGroups: scoreDistribution.entries.map((entry) {
                    final index =
                        scoreDistribution.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index, // اصلاح: استفاده از int به جای double
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: _getScoreColor(entry.key),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
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

  Widget _buildSubjectPerformance() {
    final quizPerformance =
        _dashboardData!['quizPerformance'] as Map<String, dynamic>;
    final subjectPerformance =
        quizPerformance['subjectPerformance'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'عملکرد بر اساس درس',
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
                          final subjects = subjectPerformance.keys.toList();
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
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: subjectPerformance.entries.map((entry) {
                    final index =
                        subjectPerformance.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index, // اصلاح: استفاده از int به جای double
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: _getSubjectColor(entry.key),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
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

  Widget _buildQuestionStats() {
    final questionStats =
        _dashboardData!['questionStats'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آمار سوالات',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            ReportCard(
              title: 'کل سوالات',
              value: questionStats['totalQuestions'].toString(),
              icon: Icons.help,
              color: Colors.orange,
            ),
            ReportCard(
              title: 'در انتظار',
              value: questionStats['pendingQuestions'].toString(),
              icon: Icons.hourglass_empty,
              color: Colors.orange,
            ),
            ReportCard(
              title: 'تأیید شده',
              value: questionStats['approvedQuestions'].toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            ReportCard(
              title: 'نرخ تأیید',
              value: '${questionStats['approvalRate']}%',
              icon: Icons.percent,
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionApprovalChart() {
    final questionStats =
        _dashboardData!['questionStats'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'وضعیت سوالات',
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
                      value:
                          (questionStats['pendingQuestions'] ?? 0).toDouble(),
                      title: 'در انتظار',
                      color: Colors.orange,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value:
                          (questionStats['approvedQuestions'] ?? 0).toDouble(),
                      title: 'تأیید شده',
                      color: Colors.green,
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value:
                          (questionStats['rejectedQuestions'] ?? 0).toDouble(),
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

  Widget _buildQuestionCategories() {
    final questionStats =
        _dashboardData!['questionStats'] as Map<String, dynamic>;
    final categoryStats =
        questionStats['categoryStats'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'دسته‌بندی سوالات',
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
                          final categories = categoryStats.keys.toList();
                          if (value.toInt() >= 0 &&
                              value.toInt() < categories.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                categories[value.toInt()],
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
                  barGroups: categoryStats.entries.map((entry) {
                    final index =
                        categoryStats.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index, // اصلاح: استفاده از int به جای double
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          color: _getCategoryColor(entry.key),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
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

  Color _getScoreColor(String range) {
    switch (range) {
      case '0-20':
        return Colors.red;
      case '21-40':
        return Colors.orange;
      case '41-60':
        return Colors.yellow;
      case '61-80':
        return Colors.lightGreen;
      case '81-100':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getSubjectColor(String subject) {
    switch (subject) {
      case 'ریاضی':
        return Colors.blue;
      case 'فیزیک':
        return Colors.green;
      case 'شیمی':
        return Colors.orange;
      case 'زیست':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'ریاضی':
        return Colors.blue;
      case 'فیزیک':
        return Colors.green;
      case 'شیمی':
        return Colors.orange;
      case 'زیست':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _exportAnalytics() async {
    // این قابلیت در آینده پیاده‌سازی می‌شود
    _showSuccess('خروجی گرفتن از تحلیل‌ها به زودی اضافه می‌شود');
  }
}
