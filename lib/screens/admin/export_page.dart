import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/export_service.dart';
import '../../services/report_service.dart';
import '../../services/analytics_service.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  bool _isLoading = false;
  DateTimeRange? _selectedDateRange;
  final ExportFormat _selectedFormat =
      ExportFormat.excel; // اصلاح: تبدیل به final
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            title: const Text('مدیریت خروجی‌ها'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: _showExportHistory,
              ),
              IconButton(
                icon: const Icon(Icons.help),
                onPressed: _showHelp,
              ),
            ],
          ),
          body: Column(
            children: [
              _buildTabBar(),
              const Divider(height: 1),
              Expanded(
                child: _buildTabContent(),
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
          Tab(text: 'کاربران'),
          Tab(text: 'آزمون‌ها'),
          Tab(text: 'سوالات'),
          Tab(text: 'تحلیل‌ها'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      // اصلاح: استفاده از _isLoading
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedTabIndex) {
      case 0:
        return _buildUsersTab();
      case 1:
        return _buildQuizzesTab();
      case 2:
        return _buildQuestionsTab();
      case 3:
        return _buildAnalyticsTab();
      default:
        return const Center(child: Text('تبی انتخاب نشده'));
    }
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          _buildExportOptions(
            title: 'گزارش کاربران',
            description: 'خروجی گرفتن لیست تمام کاربران سیستم با اطلاعات کامل',
            icon: Icons.people,
            color: Colors.blue,
            onExport: _exportUsers,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش فعالیت کاربران',
            description: 'خروجی گرفتن فعالیت‌های اخیر کاربران',
            icon: Icons.directions_run,
            color: Colors.green,
            onExport: _exportUserActivities,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش عملکرد کاربران',
            description: 'خروجی گرفتن تحلیل عملکرد فردی کاربران',
            icon: Icons.analytics,
            color: Colors.orange,
            onExport: _exportUserPerformance,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش دموگرافیک کاربران',
            description: 'خروجی گرفتن اطلاعات دموگرافیک کاربران',
            icon: Icons.pie_chart,
            color: Colors.purple,
            onExport: _exportUserDemographics,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          _buildExportOptions(
            title: 'گزارش آزمون‌ها',
            description: 'خروجی گرفتن لیست تمام آزمون‌های سیستم',
            icon: Icons.quiz,
            color: Colors.green,
            onExport: _exportQuizzes,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش نتایج آزمون‌ها',
            description: 'خروجی گرفتن نتایج تمام آزمون‌های انجام شده',
            icon: Icons.assessment,
            color: Colors.blue,
            onExport: _exportQuizResults,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش آماری آزمون‌ها',
            description: 'خروجی گرفتن آمار و تحلیل آزمون‌ها',
            icon: Icons.bar_chart,
            color: Colors.orange,
            onExport: _exportQuizAnalytics,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش مقایسه‌ای آزمون‌ها',
            description: 'خروجی گرفتن مقایسه عملکرد در آزمون‌های مختلف',
            icon: Icons.compare,
            color: Colors.purple,
            onExport: _exportQuizComparison,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          _buildExportOptions(
            title: 'گزارش سوالات',
            description: 'خروجی گرفتن لیست تمام سوالات سیستم',
            icon: Icons.help,
            color: Colors.orange,
            onExport: _exportQuestions,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش سوالات بر اساس دسته‌بندی',
            description: 'خروجی گرفتن سوالات گروه‌بندی شده',
            icon: Icons.category,
            color: Colors.blue,
            onExport: _exportQuestionsByCategory,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش سوالات بر اساس وضعیت',
            description: 'خروجی گرفتن سوالات بر اساس وضعیت تأیید',
            icon: Icons.playlist_add_check,
            color: Colors.green,
            onExport: _exportQuestionsByStatus,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش سوالات دشوار',
            description: 'خروجی گرفتن سوالات بر اساس سطح دشواری',
            icon: Icons.trending_up,
            color: Colors.red,
            onExport: _exportQuestionsByDifficulty,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeSelector(),
          const SizedBox(height: 24),
          _buildExportOptions(
            title: 'گزارش تحلیلی کامل',
            description: 'خروجی گرفتن گزارش تحلیلی کامل سیستم',
            icon: Icons.dashboard,
            color: Colors.indigo,
            onExport: _exportFullAnalytics,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش رشد کاربران',
            description: 'خروجی گرفتن تحلیل رشد کاربران',
            icon: Icons.trending_up,
            color: Colors.green,
            onExport: _exportUserGrowthAnalytics,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش عملکرد آزمون‌ها',
            description: 'خروجی گرفتن تحلیل عملکرد آزمون‌ها',
            icon: Icons.insights,
            color: Colors.orange,
            onExport: _exportQuizPerformanceAnalytics,
          ),
          const SizedBox(height: 16),
          _buildExportOptions(
            title: 'گزارش فعالیت‌های سیستم',
            description: 'خروجی گرفتن تحلیل فعالیت‌های سیستم',
            icon: Icons.favorite,
            color: Colors.purple,
            onExport: _exportActivityAnalytics,
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'محدوده زمانی',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDateRange,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDateRange != null
                                  ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                                  : 'انتخاب محدوده زمانی',
                              style: TextStyle(
                                color: _selectedDateRange != null
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectDateRange,
                  child: const Text('انتخاب'),
                ),
                const SizedBox(width: 12),
                if (_selectedDateRange != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOptions({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onExport,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onExport,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _exportUsers() async {
    _showExportDialog(
      title: 'گزارش کاربران',
      defaultFileName: 'users_report',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          final report = await ReportService.getUsersReport();
          await ExportService.exportUserReport(
            users: report['users'],
            fileName: 'users_report',
            format: format,
          );
          _showSuccess('گزارش کاربران با موفقیت خروجی گرفته شد');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش کاربران: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportUserActivities() async {
    _showExportDialog(
      title: 'گزارش فعالیت کاربران',
      defaultFileName: 'user_activities',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          final activities = await ReportService.getActivityReport(days: 30);
          await ExportService.exportActivityReport(
            activities: activities['activities'],
            fileName: 'user_activities',
            format: format,
          );
          _showSuccess('گزارش فعالیت کاربران با موفقیت خروجی گرفته شد');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش فعالیت کاربران: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportUserPerformance() async {
    _showExportDialog(
      title: 'گزارش عملکرد کاربران',
      defaultFileName: 'user_performance',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش عملکرد کاربران به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش عملکرد کاربران: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportUserDemographics() async {
    _showExportDialog(
      title: 'گزارش دموگرافیک کاربران',
      defaultFileName: 'user_demographics',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش دموگرافیک کاربران به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش دموگرافیک کاربران: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportQuizzes() async {
    _showExportDialog(
      title: 'گزارش آزمون‌ها',
      defaultFileName: 'quizzes_report',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          final report = await ReportService.getQuizzesReport();
          await ExportService.exportQuizReport(
            quizzes: report['quizzes'],
            fileName: 'quizzes_report',
            format: format,
          );
          _showSuccess('گزارش آزمون‌ها با موفقیت خروجی گرفته شد');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش آزمون‌ها: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportQuizResults() async {
    _showExportDialog(
      title: 'گزارش نتایج آزمون‌ها',
      defaultFileName: 'quiz_results',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش نتایج آزمون‌ها به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش نتایج آزمون‌ها: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportQuizAnalytics() async {
    _showExportDialog(
      title: 'گزارش آماری آزمون‌ها',
      defaultFileName: 'quiz_analytics',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش آماری آزمون‌ها به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش آماری آزمون‌ها: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportQuizComparison() async {
    _showExportDialog(
      title: 'گزارش مقایسه‌ای آزمون‌ها',
      defaultFileName: 'quiz_comparison',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش مقایسه‌ای آزمون‌ها به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش مقایسه‌ای آزمون‌ها: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportQuestions() async {
    _showExportDialog(
      title: 'گزارش سوالات',
      defaultFileName: 'questions_report',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          final report = await ReportService.getQuestionsReport();
          await ExportService.exportQuestionReport(
            questions: report['questions'],
            fileName: 'questions_report',
            format: format,
          );
          _showSuccess('گزارش سوالات با موفقیت خروجی گرفته شد');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش سوالات: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportQuestionsByCategory() async {
    _showExportDialog(
      title: 'گزارش سوالات بر اساس دسته‌بندی',
      defaultFileName: 'questions_by_category',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش سوالات بر اساس دسته‌بندی به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش سوالات بر اساس دسته‌بندی: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportQuestionsByStatus() async {
    _showExportDialog(
      title: 'گزارش سوالات بر اساس وضعیت',
      defaultFileName: 'questions_by_status',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش سوالات بر اساس وضعیت به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش سوالات بر اساس وضعیت: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportQuestionsByDifficulty() async {
    _showExportDialog(
      title: 'گزارش سوالات بر اساس سطح دشواری',
      defaultFileName: 'questions_by_difficulty',
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش سوالات بر اساس سطح دشواری به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش سوالات بر اساس سطح دشواری: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportFullAnalytics() async {
    _showExportDialog(
      title: 'گزارش تحلیلی کامل',
      defaultFileName: 'full_analytics',
      availableFormats: const [ExportFormat.pdf],
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          final analytics = await AnalyticsService.getDashboardAnalytics();
          await ExportService.exportAnalyticsReport(
            analytics: analytics,
            fileName: 'full_analytics',
            format: format,
          );
          _showSuccess('گزارش تحلیلی کامل با موفقیت خروجی گرفته شد');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش تحلیلی کامل: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportUserGrowthAnalytics() async {
    _showExportDialog(
      title: 'گزارش رشد کاربران',
      defaultFileName: 'user_growth_analytics',
      availableFormats: const [ExportFormat.pdf],
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش رشد کاربران به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش رشد کاربران: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportQuizPerformanceAnalytics() async {
    _showExportDialog(
      title: 'گزارش عملکرد آزمون‌ها',
      defaultFileName: 'quiz_performance_analytics',
      availableFormats: const [ExportFormat.pdf],
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش عملکرد آزمون‌ها به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش عملکرد آزمون‌ها: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  Future<void> _exportActivityAnalytics() async {
    _showExportDialog(
      title: 'گزارش فعالیت‌های سیستم',
      defaultFileName: 'activity_analytics',
      availableFormats: const [ExportFormat.pdf],
      onExport: (format) async {
        setState(() => _isLoading = true);
        try {
          // این قابلیت نیاز به پیاده‌سازی دارد
          _showSuccess('گزارش فعالیت‌های سیستم به زودی آماده می‌شود');
        } catch (e) {
          _showError('خطا در خروجی گرفتن گزارش فعالیت‌های سیستم: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      },
    );
  }

  void _showExportDialog({
    required String title,
    required String defaultFileName,
    List<ExportFormat> availableFormats = const [
      ExportFormat.excel,
      ExportFormat.csv,
      ExportFormat.pdf,
    ],
    required Function(ExportFormat) onExport,
  }) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          ExportFormat selectedFormat =
              _selectedFormat; // اصلاح: استفاده از _selectedFormat
          return AlertDialog(
            title: Text('خروجی گرفتن $title'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'نام فایل',
                    hintText: 'نام فایل را وارد کنید',
                  ),
                  controller: TextEditingController(text: defaultFileName),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ExportFormat>(
                  value: selectedFormat,
                  decoration: const InputDecoration(
                    labelText: 'فرمت خروجی',
                  ),
                  items: availableFormats.map((format) {
                    return DropdownMenuItem(
                      value: format,
                      child: Text(_getFormatText(format)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFormat = value!;
                    });
                  },
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
                  onExport(selectedFormat);
                },
                child: const Text('خروجی'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تاریخچه خروجی‌ها'),
        content: const Text(
          'تاریخچه خروجی‌های شما در اینجا نمایش داده می‌شود.\n'
          'این قابلیت در حال توسعه است.',
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

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('راهنمای خروجی گرفتن'),
        content: const Text(
          '1. گزارش کاربران: خروجی لیست تمام کاربران با اطلاعات کامل\n'
          '2. گزارش آزمون‌ها: خروجی لیست آزمون‌ها و نتایج آن‌ها\n'
          '3. گزارش سوالات: خروجی لیست سوالات با جزئیات\n'
          '4. گزارش تحلیلی: خروجی تحلیل‌های آماری سیستم\n\n'
          'فرمت‌های پشتیبانی شده:\n'
          '- Excel (.xlsx): برای ویرایش در اکسل\n'
          '- CSV (.csv): برای وارد کردن در پایگاه داده\n'
          '- PDF (.pdf): برای مشاهده و چاپ',
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

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _getFormatText(ExportFormat format) {
    switch (format) {
      case ExportFormat.excel:
        return 'Excel (.xlsx)';
      case ExportFormat.csv:
        return 'CSV (.csv)';
      case ExportFormat.pdf:
        return 'PDF (.pdf)';
    }
  }
}
