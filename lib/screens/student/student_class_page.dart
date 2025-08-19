import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../models/user_model.dart';

class StudentClassPage extends StatefulWidget {
  final String classIdFromInvite;
  const StudentClassPage({
    Key? key,
    required this.classIdFromInvite,
  }) : super(key: key);

  @override
  State<StudentClassPage> createState() => _StudentClassPageState();
}

class _StudentClassPageState extends State<StudentClassPage> {
  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // اطلاعات کلاس از Firestore
  Map<String, dynamic>? _classData;
  UserModel? _teacherData;
  bool _isEnrolled = false;
  bool _isApproved = false;

  // اطلاعات UI
  int likes = 0;
  bool isFavorite = false;
  List<String> comments = [];
  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClassData();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Future<void> _loadClassData() async {
    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      final firestore = FirebaseFirestore.instance;

      // دریافت اطلاعات کلاس
      final classDoc = await firestore
          .collection('classes')
          .doc(widget.classIdFromInvite)
          .get();

      if (!classDoc.exists) {
        throw Exception('کلاس یافت نشد');
      }

      _classData = classDoc.data()!;

      // دریافت اطلاعات استاد
      if (_classData!['instructorId'] != null) {
        final teacherDoc = await firestore
            .collection('users')
            .doc(_classData!['instructorId'])
            .get();
        if (teacherDoc.exists) {
          _teacherData = UserModel.fromMap(teacherDoc.data()!);
        }
      }

      // بررسی وضعیت ثبت‌نام دانشجو
      if (authProvider.currentUser != null) {
        final students = List<String>.from(_classData!['students'] ?? []);
        _isEnrolled = students.contains(authProvider.currentUser!.uid);

        final approvedStudents =
            List<String>.from(_classData!['approvedStudents'] ?? []);
        _isApproved = approvedStudents.contains(authProvider.currentUser!.uid);
      }

      // دریافت لایک‌ها و کامنت‌ها
      likes = _classData!['likes'] ?? 0;
      comments = List<String>.from(_classData!['comments'] ?? []);

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) return;

      final firestore = FirebaseFirestore.instance;
      final classRef =
          firestore.collection('classes').doc(widget.classIdFromInvite);

      final newFavoriteStatus = !isFavorite;

      // به‌روزرسانی وضعیت محلی
      if (mounted) {
        setState(() {
          isFavorite = newFavoriteStatus;
        });
      }

      // به‌روزرسانی در Firestore
      await classRef.update({
        'favorites': newFavoriteStatus
            ? FieldValue.arrayUnion([authProvider.currentUser!.uid])
            : FieldValue.arrayRemove([authProvider.currentUser!.uid]),
      });

      // نمایش پیام فقط اگر ویجت هنوز mounted باشه
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newFavoriteStatus
                ? "به علاقه‌مندی‌ها اضافه شد"
                : "از علاقه‌مندی‌ها حذف شد"),
          ),
        );
      }
    } catch (e) {
      // برگرداندن وضعیت در صورت خطا
      if (mounted) {
        setState(() {
          isFavorite = !isFavorite;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _incrementLikes() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final classRef =
          firestore.collection('classes').doc(widget.classIdFromInvite);

      // به‌روزرسانی وضعیت محلی
      if (mounted) {
        setState(() {
          likes++;
        });
      }

      // به‌روزرسانی در Firestore
      await classRef.update({
        'likes': FieldValue.increment(1),
      });

      // نمایش پیام فقط اگر ویجت هنوز mounted باشه
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("کلاس لایک شد")),
        );
      }
    } catch (e) {
      // برگرداندن وضعیت در صورت خطا
      if (mounted) {
        setState(() {
          likes--;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _addComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) return;

      final firestore = FirebaseFirestore.instance;
      final classRef =
          firestore.collection('classes').doc(widget.classIdFromInvite);

      final commentWithUser = "${authProvider.currentUser!.name}: $text";

      // به‌روزرسانی وضعیت محلی
      if (mounted) {
        setState(() {
          comments.add(commentWithUser);
          commentController.clear();
        });
      }

      // به‌روزرسانی در Firestore
      await classRef.update({
        'comments': FieldValue.arrayUnion([commentWithUser]),
      });

      // نمایش پیام فقط اگر ویجت هنوز mounted باشه
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("نظر شما ثبت شد")),
        );
      }
    } catch (e) {
      // نمایش خطا فقط اگر ویجت هنوز mounted باشه
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("خطا: ${e.toString()}")),
        );
      }
    }
  }

  int get remainingSeats =>
      (_classData?['capacity'] ?? 30) - (_classData?['enrolledCount'] ?? 0);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'خطا: $_errorMessage',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadClassData,
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClassHeader(),
                const SizedBox(height: 10),
                _buildDatesAndCapacity(),
                const SizedBox(height: 20),
                _buildJoinStatusCard(),
                const SizedBox(height: 20),
                _buildLikesRow(),
                const SizedBox(height: 20),
                _buildSessionsList(),
                const SizedBox(height: 20),
                _buildProgressChartPlaceholder(),
                const SizedBox(height: 20),
                _buildCommentsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text("جزئیات کلاس"),
      actions: [
        IconButton(
          icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
          tooltip:
              isFavorite ? "حذف از علاقه‌مندی‌ها" : "افزودن به علاقه‌مندی‌ها",
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: "اشتراک‌گذاری کلاس",
          onPressed: _onSharePressed,
        ),
      ],
    );
  }

  void _onSharePressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("امکان اشتراک‌گذاری فعال شد")),
    );
  }

  Widget _buildClassHeader() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _classData?['title'] ?? 'نام کلاس',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "مدرس: ${_teacherData?.name ?? _classData?['instructorName'] ?? 'نامشخص'}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 24),
            Text(_classData?['description'] ?? 'توضیحاتی وجود ندارد'),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesAndCapacity() {
    final startDate = _classData?['startDate']?.toDate() ?? DateTime.now();
    final endDate = _classData?['endDate']?.toDate() ?? DateTime.now();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _infoColumn("تاریخ شروع:", _formatDate(startDate)),
            _infoColumn("تاریخ پایان:", _formatDate(endDate)),
            _infoColumn("ظرفیت کلاس:", "${_classData?['capacity'] ?? 30} نفر"),
            _infoColumn(
                "ثبت‌نام شده:", "${_classData?['enrolledCount'] ?? 0} نفر"),
            _infoColumn("جای خالی:", "$remainingSeats نفر"),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      "${date.year}/${_padZero(date.month)}/${_padZero(date.day)}";
  String _padZero(int number) => number.toString().padLeft(2, '0');

  Widget _buildJoinStatusCard() {
    return Card(
      color: _isApproved
          ? Colors.green[100]
          : (_isEnrolled ? Colors.orange[100] : Colors.blue[100]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isApproved
                  ? Icons.check_circle
                  : (_isEnrolled ? Icons.hourglass_top : Icons.person_add),
              color: _isApproved
                  ? Colors.green
                  : (_isEnrolled ? Colors.orange : Colors.blue),
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isApproved
                    ? "شما به این کلاس دسترسی دارید."
                    : _isEnrolled
                        ? "درخواست ورود شما در حال بررسی است."
                        : "شما به این کلاس دعوت شده‌اید.",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (!_isEnrolled)
              ElevatedButton.icon(
                onPressed: _sendJoinRequest,
                icon: const Icon(Icons.send),
                label: const Text("ثبت‌نام در کلاس"),
              ),
          ],
        ),
      ),
    );
  }

  void _sendJoinRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("درخواست شما ثبت شد")),
    );
  }

  Widget _buildLikesRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.thumb_up_alt_outlined),
          tooltip: "لایک کلاس",
          onPressed: _incrementLikes,
        ),
        Text("$likes لایک"),
      ],
    );
  }

  Widget _buildSessionsList() {
    // این بخش باید از Firestore خوانده شود
    final sessions =
        List<Map<String, dynamic>>.from(_classData?['sessions'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "لیست جلسات",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text("هیچ جلسه‌ای تعریف نشده است")),
            ),
          )
        else
          ...sessions.map((session) => _buildSessionCard(session)),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final status = session['status'] ?? 'locked';
    final color = status == 'active'
        ? Colors.blue[50]
        : status == 'locked'
            ? Colors.grey[300]
            : Colors.grey[200];
    final icon = status == 'done'
        ? Icons.check_circle
        : status == 'active'
            ? Icons.play_circle_fill
            : Icons.lock;
    final iconColor = status == 'done'
        ? Colors.green
        : status == 'active'
            ? Colors.blue
            : Colors.grey;
    final trailingText = status == 'active'
        ? "در حال برگزاری"
        : status == 'done'
            ? "برگزار شد"
            : "قفل شده";
    final trailingColor = status == 'active' ? Colors.blue : Colors.grey;

    return Card(
      color: color,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(session['title'] ?? 'جلسه'),
        subtitle: Text(session['description'] ?? 'توضیحاتی وجود ندارد'),
        trailing: Text(trailingText, style: TextStyle(color: trailingColor)),
      ),
    );
  }

  Widget _buildProgressChartPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "پیشرفت شما",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
              child: Text("نمودار پیشرفت در اینجا نمایش داده می‌شود")),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "نظرات کاربران",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (comments.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text("هیچ نظری ثبت نشده است")),
            ),
          )
        else
          ...comments.map((comment) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text("- $comment"),
              )),
        const SizedBox(height: 12),
        TextField(
          controller: commentController,
          decoration: InputDecoration(
            labelText: "افزودن نظر جدید",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _addComment,
              tooltip: "ارسال نظر",
            ),
          ),
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _addComment(),
        ),
      ],
    );
  }
}
