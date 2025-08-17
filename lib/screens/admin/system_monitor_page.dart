import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/role_based_access.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_role.dart';
import '../../widgets/loading_widget.dart';

class SystemMonitorPage extends StatefulWidget {
  const SystemMonitorPage({super.key});

  @override
  State<SystemMonitorPage> createState() => _SystemMonitorPageState();
}

class _SystemMonitorPageState extends State<SystemMonitorPage> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  // داده‌های سیستم
  Map<String, dynamic> _systemData = {};
  List<Map<String, dynamic>> _recentLogs = [];

  @override
  void initState() {
    super.initState();
    _loadSystemData();
  }

  Future<void> _loadSystemData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // شبیه‌سازی دریافت داده‌ها از سرور
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _systemData = {
          'serverStatus': true,
          'databaseStatus': true,
          'memoryUsage': 85,
          'cpuUsage': 45,
          'diskUsage': 23,
          'lastUpdated': DateTime.now(),
        };

        _recentLogs = [
          {
            'time': DateTime.now().subtract(const Duration(minutes: 5)),
            'message': 'کاربر جدید ثبت‌نام کرد',
            'type': 'info'
          },
          {
            'time': DateTime.now().subtract(const Duration(minutes: 8)),
            'message': 'پشتیبان‌گیری خودکار انجام شد',
            'type': 'success'
          },
          {
            'time': DateTime.now().subtract(const Duration(minutes: 12)),
            'message': 'خطا در اتصال به پایگاه داده',
            'type': 'error'
          },
          {
            'time': DateTime.now().subtract(const Duration(minutes: 18)),
            'message': 'سیستم به‌روزرسانی شد',
            'type': 'info'
          },
          {
            'time': DateTime.now().subtract(const Duration(minutes: 25)),
            'message': 'کاربر وارد سیستم شد',
            'type': 'success'
          },
        ];
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshSystemData() async {
    setState(() {
      _hasError = false;
    });

    try {
      await _loadSystemData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('داده‌های سیستم با موفقیت به‌روز شدند'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در به‌روزرسانی داده‌ها: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.admin,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مانیتور سیستم'),
          backgroundColor: Colors.redAccent,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshSystemData,
            ),
            // منوی کاربر
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.isLoggedIn && !authProvider.isGuest) {
                  return PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'signout':
                          await authProvider.signOut();
                          if (context.mounted) {
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          }
                          break;
                        case 'profile':
                          Navigator.of(context).pushNamed('/profile');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Text('پروفایل'),
                      ),
                      const PopupMenuItem(
                        value: 'signout',
                        child: Text('خروج'),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: ModernLoading());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'خطا در بارگذاری داده‌ها',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'خطای نامشخص',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshSystemData,
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshSystemData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // نمایش اطلاعات کاربر
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoggedIn && !authProvider.isGuest) {
                return _buildUserInfo(authProvider.currentUser!);
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 24),

          _buildSystemStatus(),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(),
          const SizedBox(height: 24),
          _buildRecentLogs(),
        ],
      ),
    );
  }

  Widget _buildUserInfo(dynamic user) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اطلاعات کاربر',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'وضعیت سیستم',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'سرور',
                    _systemData['serverStatus'] ? 'آنلاین' : 'آفلاین',
                    _systemData['serverStatus'] ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusItem(
                    'پایگاه داده',
                    _systemData['databaseStatus'] ? 'آنلاین' : 'آفلاین',
                    _systemData['databaseStatus'] ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatusItem(
                    'حافظه',
                    '${_systemData['memoryUsage']}% استفاده',
                    _getUsageColor(_systemData['memoryUsage']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusItem(
              'آخرین به‌روزرسانی',
              _formatDateTime(_systemData['lastUpdated']),
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
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

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'عملکرد سیستم',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricItem('CPU', '${_systemData['cpuUsage']}%',
                _systemData['cpuUsage'] / 100),
            const SizedBox(height: 12),
            _buildMetricItem('حافظه', '${_systemData['memoryUsage']}%',
                _systemData['memoryUsage'] / 100),
            const SizedBox(height: 12),
            _buildMetricItem('دیسک', '${_systemData['diskUsage']}%',
                _systemData['diskUsage'] / 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _getUsageColor(percentage * 100),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
          valueColor:
              AlwaysStoppedAnimation<Color>(_getUsageColor(percentage * 100)),
        ),
      ],
    );
  }

  Widget _buildRecentLogs() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'لاگ‌های اخیر',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    _showAllLogs();
                  },
                  child: const Text('مشاهده همه'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentLogs.isEmpty)
              const Center(
                child: Text(
                  'هیچ لاگی یافت نشد',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentLogs.length,
                itemBuilder: (context, index) {
                  final log = _recentLogs[index];
                  return ListTile(
                    leading: Icon(
                      _getLogIcon(log['type']),
                      color: _getLogColor(log['type']),
                    ),
                    title: Text(log['message']),
                    subtitle: Text(_formatDateTime(log['time'])),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAllLogs() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تمام لاگ‌ها'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: _recentLogs.length,
              itemBuilder: (context, index) {
                final log = _recentLogs[index];
                return ListTile(
                  leading: Icon(
                    _getLogIcon(log['type']),
                    color: _getLogColor(log['type']),
                  ),
                  title: Text(log['message']),
                  subtitle: Text(_formatDateTime(log['time'])),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('بستن'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUsageColor(double usage) {
    if (usage < 50) return Colors.green;
    if (usage < 80) return Colors.orange;
    return Colors.red;
  }

  IconData _getLogIcon(String? type) {
    switch (type) {
      case 'error':
        return Icons.error;
      case 'success':
        return Icons.check_circle;
      case 'info':
      default:
        return Icons.info;
    }
  }

  Color _getLogColor(String? type) {
    switch (type) {
      case 'error':
        return Colors.red;
      case 'success':
        return Colors.green;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'نامشخص';

    DateTime dt;
    if (dateTime is DateTime) {
      dt = dateTime;
    } else {
      return dateTime.toString();
    }

    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} - '
        '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }
}
