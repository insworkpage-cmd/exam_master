import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../services/ticket_service.dart';
import 'ticket_detail_page.dart';
import 'create_ticket_page.dart';

class TicketListPage extends StatefulWidget {
  const TicketListPage({super.key});

  @override
  State<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends State<TicketListPage> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedStatus = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<Map<String, dynamic>> _getFilteredTickets() {
    var filtered = _tickets.where((ticket) {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;

      return ticket['subject']?.toLowerCase().contains(query) == true ||
          ticket['description']?.toLowerCase().contains(query) == true ||
          ticket['category']?.toLowerCase().contains(query) == true;
    }).toList();

    // اعمال فیلتر وضعیت
    if (_selectedStatus != 'all') {
      filtered = filtered
          .where((ticket) => ticket['status'] == _selectedStatus)
          .toList();
    }
    return filtered;
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final authProvider =
          Provider.of<app_auth.AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        throw Exception('کاربر وارد نشده است');
      }
      final tickets =
          await TicketService.getUserTickets(authProvider.currentUser!.uid);

      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshTickets() async {
    await _loadTickets();
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'in_progress':
        return 'در حال بررسی';
      case 'resolved':
        return 'حل شده';
      case 'closed_by_user':
        return 'بسته شده توسط کاربر';
      case 'reopened':
        return 'بازگشتی';
      default:
        return 'ناشناخته';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTickets = _getFilteredTickets();
    return Scaffold(
      appBar: AppBar(
        title: const Text('تیکت‌های پشتیبانی'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTickets,
            tooltip: 'تازه‌سازی',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('همه تیکت‌ها'),
              ),
              const PopupMenuItem(
                value: 'open',
                child: Text('باز'),
              ),
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('در حال بررسی'),
              ),
              const PopupMenuItem(
                value: 'resolved',
                child: Text('حل شده'),
              ),
              const PopupMenuItem(
                value: 'closed_by_user',
                child: Text('بسته شده'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // بخش جستجو
          _buildSearchBar(),

          // بخش فیلتر وضعیت - اصلاح شده
          _buildStatusFilter(filteredTickets),

          // بخش لیست تیکت‌ها
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : filteredTickets.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _refreshTickets,
                            child: ListView.builder(
                              itemCount: filteredTickets.length,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              itemBuilder: (context, index) {
                                final ticket = filteredTickets[index];
                                return TicketCard(
                                  ticket: ticket,
                                  onTap: () => _navigateToTicketDetail(ticket),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTicket,
        backgroundColor: Colors.blue,
        tooltip: 'ایجاد تیکت جدید', // ← tooltip به قبل از child منتقل شد
        child: const Icon(Icons.add), // ← child به انتهای لیست منتقل شد
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'جستجوی تیکت‌ها...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  // اصلاح شده: اضافه کردن پارامتر filteredTickets
  Widget _buildStatusFilter(List<Map<String, dynamic>> filteredTickets) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('فیلتر: '),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _selectedStatus == 'all'
                  ? 'همه'
                  : _getStatusText(_selectedStatus),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          Text('${filteredTickets.length} تیکت'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'خطا در بارگیری تیکت‌ها',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTickets,
            child: const Text('تلاش مجدد'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.support_agent_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'تیکتی با این مشخصات یافت نشد'
                : 'شما هنوز تیکتی ثبت نکرده‌اید',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'از کلیدواژه دیگری استفاده کنید'
                : 'برای ایجاد تیکت جدید روی + ضربه بزنید',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _navigateToTicketDetail(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailPage(ticketId: ticket['id']),
      ),
    ).then((_) => _loadTickets()); // به‌روزرسانی لیست بعد از بازگشت
  }

  void _createNewTicket() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTicketPage(),
      ),
    ).then((_) => _loadTickets()); // به‌روزرسانی لیست بعد از بازگشت
  }
}

class TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onTap;
  const TicketCard({
    super.key,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = ticket['status'] ?? 'unknown';
    final priority = ticket['priority'] ?? 'normal';
    final subject = ticket['subject'] ?? 'بدون موضوع';
    final category = ticket['category'] ?? 'other';
    final createdAt = ticket['createdAt'] != null
        ? DateTime.parse(ticket['createdAt'])
        : DateTime.now();
    final hasUnreadResponse = ticket['responses'] != null &&
        (ticket['responses'] as List).isNotEmpty &&
        (ticket['responses'] as List).last['responderRole'] == 'moderator';
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // آیکون اولویت
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getPriorityIcon(priority),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getPriorityColor(priority),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // وضعیت تیکت
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(status),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (hasUnreadResponse) ...[
                        const SizedBox(width: 4),
                        // اصلاح شده: انتقال child به انتهای پارامترها
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _getCategoryText(category),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (ticket['assignedToName'] != null) ...[
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'اختصاص یافته به: ${ticket['assignedToName']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'باز';
      case 'in_progress':
        return 'در حال بررسی';
      case 'resolved':
        return 'حل شده';
      case 'closed_by_user':
        return 'بسته شده توسط کاربر';
      case 'reopened':
        return 'بازگشتی';
      default:
        return 'ناشناخته';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed_by_user':
        return Colors.grey;
      case 'reopened':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityIcon(String priority) {
    switch (priority) {
      case 'low':
        return '↓';
      case 'normal':
        return '→';
      case 'high':
        return '↑';
      case 'urgent':
        return '⚡';
      default:
        return '→';
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'normal':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryText(String category) {
    switch (category) {
      case 'technical':
        return 'فنی';
      case 'account':
        return 'حساب کاربری';
      case 'content':
        return 'محتوا';
      case 'capacity':
        return 'ظرفیت';
      case 'spam':
        return 'اسپم';
      case 'other':
        return 'سایر';
      default:
        return category;
    }
  }
}
