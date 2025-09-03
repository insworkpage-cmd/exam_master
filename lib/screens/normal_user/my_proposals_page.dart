import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../services/proposal_service.dart';
import '../../core/question_model.dart';
import '../../widgets/question_status_badge.dart';
// import '../../utils/logger.dart'; // حذف شد - استفاده نشده

class MyProposalsPage extends StatefulWidget {
  const MyProposalsPage({super.key});

  @override
  State<MyProposalsPage> createState() => _MyProposalsPageState();
}

class _MyProposalsPageState extends State<MyProposalsPage> {
  List<Question> _proposals = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMyProposals();
  }

  Future<void> _loadMyProposals() async {
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
      _proposals = await ProposalService.getUserProposals(
        authProvider.currentUser!.uid,
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پیشنهادات من'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyProposals,
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
                        onPressed: _loadMyProposals,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                )
              : _proposals.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.quiz_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'شما هنوز هیچ سوالاتی پیشنهاد نداده‌اید',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMyProposals,
                      child: ListView.builder(
                        itemCount: _proposals.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (context, index) {
                          final proposal = _proposals[index];
                          return ProposalCard(proposal: proposal);
                        },
                      ),
                    ),
    );
  }
}

class ProposalCard extends StatelessWidget {
  final Question proposal;
  const ProposalCard({super.key, required this.proposal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    proposal.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                QuestionStatusBadge(status: proposal.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.category, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  proposal.category ?? 'عمومی',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.speed, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  proposal.difficulty == 1
                      ? 'آسان'
                      : proposal.difficulty == 2
                          ? 'متوسط'
                          : 'سخت',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${proposal.createdAt.day}/${proposal.createdAt.month}/${proposal.createdAt.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (proposal.reviewDate != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.done_all, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'بررسی شد',
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
    );
  }
}
