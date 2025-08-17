import 'package:flutter/material.dart';

class StudentClassPage extends StatefulWidget {
  final String className;
  final String teacherName;
  final String description;
  final bool isApproved;
  final DateTime? startDate;
  final DateTime? endDate;
  final int capacity;
  final int enrolledCount;
  final String classIdFromInvite;

  const StudentClassPage({
    Key? key,
    this.className = "کلاس ریاضی - ترم تابستان",
    this.teacherName = "استاد محمدی",
    this.description =
        "در این کلاس مباحث پایه و پیشرفته ریاضی آموزش داده می‌شود.",
    this.isApproved = false,
    this.startDate,
    this.endDate,
    this.capacity = 30,
    this.enrolledCount = 25,
    required this.classIdFromInvite, // ✅ این خط اضافه شده
  }) : super(key: key);

  @override
  State<StudentClassPage> createState() => _StudentClassPageState();
}

class _StudentClassPageState extends State<StudentClassPage> {
  late final DateTime startDate;
  late final DateTime endDate;

  int likes = 10;
  bool isFavorite = false;

  final List<String> comments = [
    "کلاس بسیار مفید بود!",
    "استاد توضیحات خوبی داشت.",
  ];

  final TextEditingController commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    startDate = widget.startDate ?? DateTime(2025, 7, 1);
    endDate = widget.endDate ?? DateTime(2025, 9, 30);
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  int get remainingSeats => widget.capacity - widget.enrolledCount;

  @override
  Widget build(BuildContext context) {
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

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite
            ? "به علاقه‌مندی‌ها اضافه شد"
            : "از علاقه‌مندی‌ها حذف شد"),
      ),
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
              widget.className,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "مدرس: ${widget.teacherName}",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 24),
            Text(widget.description),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesAndCapacity() {
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
            _infoColumn("ظرفیت کلاس:", "${widget.capacity} نفر"),
            _infoColumn("ثبت‌نام شده:", "${widget.enrolledCount} نفر"),
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
    final approved = widget.isApproved;
    return Card(
      color: approved ? Colors.green[100] : Colors.orange[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              approved ? Icons.check_circle : Icons.hourglass_top,
              color: approved ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                approved
                    ? "شما به این کلاس دسترسی دارید."
                    : "درخواست ورود شما هنوز تایید نشده است.",
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (!approved)
              ElevatedButton.icon(
                onPressed: _sendJoinRequest,
                icon: const Icon(Icons.send),
                label: const Text("ارسال درخواست"),
              ),
          ],
        ),
      ),
    );
  }

  void _sendJoinRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("درخواست ورود ارسال شد")),
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

  void _incrementLikes() {
    setState(() {
      likes++;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("کلاس لایک شد")),
    );
  }

  Widget _buildSessionsList() {
    final sessions = [
      {
        "title": "جلسه اول: معرفی مباحث",
        "status": "done",
        "description": "آشنایی با مباحث و سرفصل‌ها"
      },
      {
        "title": "جلسه دوم: معادلات",
        "status": "done",
        "description": "حل معادلات خطی و غیرخطی"
      },
      {
        "title": "جلسه سوم: مشتق",
        "status": "active",
        "description": "آموزش مفاهیم مشتق و کاربردها"
      },
      {
        "title": "جلسه چهارم: انتگرال",
        "status": "locked",
        "description": "جلسه بعدی هنوز فعال نشده است"
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "لیست جلسات",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...sessions.map(_buildSessionCard),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, String> session) {
    final status = session["status"]!;
    final color = status == "active"
        ? Colors.blue[50]
        : status == "locked"
            ? Colors.grey[300]
            : Colors.grey[200];

    final icon = status == "done"
        ? Icons.check_circle
        : status == "active"
            ? Icons.play_circle_fill
            : Icons.lock;

    final iconColor = status == "done"
        ? Colors.green
        : status == "active"
            ? Colors.blue
            : Colors.grey;

    final trailingText = status == "active"
        ? "در حال برگزاری"
        : status == "done"
            ? "برگزار شد"
            : "قفل شده";

    final trailingColor = status == "active" ? Colors.blue : Colors.grey;

    return Card(
      color: color,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(session["title"]!),
        subtitle: Text(session["description"]!),
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

  void _addComment() {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      comments.add(text);
      commentController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("نظر شما ثبت شد")),
    );
  }
}
