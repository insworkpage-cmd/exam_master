import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // اضافه کردن برای Clipboard
import 'package:provider/provider.dart';
import '../../models/user_role.dart';
import '../../widgets/role_based_access.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/class_provider.dart';
import '../../models/instructor_class_model.dart' as instructor_class_model;
import 'class_list_page.dart';
import 'create_class_page.dart';
import 'class_detail_page.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});

  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  bool _hasInitialized = false;

  @override
  Widget build(BuildContext context) {
    return RoleBasedAccess(
      requiredRole: UserRole.instructor,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('داشبورد استاد'),
          backgroundColor: Colors.blue[700],
          elevation: 4,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'خروج از حساب کاربری',
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
        ),
        body: Consumer<ClassProvider>(
          builder: (context, classProvider, child) {
            // بارگذاری کلاس‌ها فقط یک بار
            if (!_hasInitialized) {
              _initializeData(classProvider, context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                await _refreshData(classProvider, context);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بخش خوشامدگویی - وسط چین
                      _buildWelcomeSection(context),
                      const SizedBox(height: 24),

                      // بخش آمار
                      _buildStatsSection(context, classProvider),
                      const SizedBox(height: 24),

                      // بخش دسترسی سریع
                      _buildQuickActions(context),
                      const SizedBox(height: 24),

                      // بخش کلاس‌های اخیر
                      _buildRecentClasses(context, classProvider),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateClassPage()),
            );
          },
          backgroundColor: Colors.blue[700],
          elevation: 6,
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Future<void> _initializeData(
      ClassProvider classProvider, BuildContext context) async {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      try {
        await classProvider
            .fetchInstructorClasses(authProvider.currentUser!.uid);
        setState(() {
          _hasInitialized = true;
        });
      } catch (e) {
        debugPrint('Error initializing data: $e');
        setState(() {
          _hasInitialized = true;
        });
      }
    }
  }

  Future<void> _refreshData(
      ClassProvider classProvider, BuildContext context) async {
    final authProvider =
        Provider.of<app_auth.AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      try {
        await classProvider.fetchInstructorClasses(
            authProvider.currentUser!.uid,
            forceRefresh: true);
      } catch (e) {
        debugPrint('Error refreshing data: $e');
      }
    }
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final authProvider = Provider.of<app_auth.AuthProvider>(context);
    final userName = authProvider.currentUser?.name ?? 'استاد گرامی';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // آیکون وسط چین
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.school,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            // متن‌ها وسط چین
            Column(
              children: [
                Text(
                  'خوش آمدید،',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'از داشبورد خود برای مدیریت کلاس‌ها و دانشجویان استفاده کنید',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, ClassProvider classProvider) {
    final totalClasses = classProvider.classes.length;
    final totalStudents = classProvider.classes
        .fold(0, (sum, classItem) => sum + classItem.students.length);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'تعداد کلاس‌ها',
            totalClasses.toString(),
            Icons.class_,
            Colors.blue,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'کل دانشجوها',
            totalStudents.toString(),
            Icons.people,
            Colors.green,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[800] : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'دسترسی سریع',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
              fontFamily: 'Vazirmatn',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  'مدیریت کلاس‌ها',
                  Icons.class_,
                  Colors.blue,
                  isDark,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const InstructorClassListPage()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  context,
                  'مدیریت سوالات',
                  Icons.quiz,
                  Colors.green,
                  isDark,
                  () => Navigator.pushNamed(
                      context, '/instructor_question_management'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onPressed,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[800] : Colors.white,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentClasses(
      BuildContext context, ClassProvider classProvider) {
    final recentClasses = classProvider.classes.take(3).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'کلاس‌های اخیر',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InstructorClassListPage()),
                ),
                child: const Text(
                  'مشاهده همه',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (classProvider.isLoading && !classProvider.hasLoaded)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (classProvider.errorMessage != null &&
              classProvider.classes.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'خطا در دریافت کلاس‌های اخیر',
                      style: TextStyle(
                        color: Colors.red,
                        fontFamily: 'Vazirmatn',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      classProvider.errorMessage!,
                      style: TextStyle(
                        color: Colors.red[300],
                        fontFamily: 'Vazirmatn',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _refreshData(classProvider, context);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'تلاش مجدد',
                        style: TextStyle(fontFamily: 'Vazirmatn'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (recentClasses.isEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: isDark ? Colors.grey[800] : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.class_outlined,
                        size: 64,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'هیچ کلاسی یافت نشد',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'برای ایجاد کلاس جدید روی دکمه + ضربه بزنید',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Column(
              children: recentClasses.map((classItem) {
                return _buildClassCard(context, classItem, isDark);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    instructor_class_model.InstructorClass classItem,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey[800] : Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailPage(instructorClass: classItem),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.class_,
                      size: 36,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classItem.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildInfoChip(
                              Icons.people,
                              '${classItem.students.length} دانشجو',
                              Colors.blue,
                              isDark,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              Icons.calendar_today,
                              '${classItem.createdAt.day}/${classItem.createdAt.month}',
                              Colors.green,
                              isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_back_ios, // تغییر جهت آیکون برای راست‌چین
                    size: 20,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // بخش کد دعوت دانشجو
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'کد دعوت دانشجو',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[600],
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            classItem.code,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.copy,
                            color: isDark ? Colors.blue[300] : Colors.blue,
                            size: 20,
                          ),
                          onPressed: () => _copyInviteCode(context, classItem),
                          tooltip: 'کپی کردن کد',
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            color: isDark ? Colors.green[300] : Colors.green,
                            size: 20,
                          ),
                          onPressed: () => _shareInviteCode(context, classItem),
                          tooltip: 'اشتراک‌گذاری کد',
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white : color,
              fontWeight: FontWeight.w500,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  void _copyInviteCode(
      BuildContext context, instructor_class_model.InstructorClass classItem) {
    Clipboard.setData(ClipboardData(text: classItem.code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'کد دعوت کپی شد: ${classItem.code}',
          style: const TextStyle(fontFamily: 'Vazirmatn'),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareInviteCode(
      BuildContext context, instructor_class_model.InstructorClass classItem) {
    final inviteText = '''
کلاس: ${classItem.name}
کد دعوت: ${classItem.code}

برای پیوستن به کلاس، این کد را در اپلیکیشن وارد کنید.
    ''';

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'اشتراک‌گذاری کد دعوت',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'کد دعوت برای کلاس "${classItem.name}":',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
                ),
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
                    fontFamily: 'Vazirmatn',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'بستن',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: Colors.blue,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'متن دعوت کپی شد',
                      style: TextStyle(fontFamily: 'Vazirmatn'),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'کپی متن',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'خروج از حساب کاربری',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'آیا از خروج از حساب کاربری اطمینان دارید؟',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'لغو',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: Colors.blue,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final authProvider =
                    Provider.of<app_auth.AuthProvider>(context, listen: false);
                final classProvider =
                    Provider.of<ClassProvider>(context, listen: false);

                // ریست کردن وضعیت کلاس‌ها هنگام خروج
                classProvider.reset();

                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'خروج',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
