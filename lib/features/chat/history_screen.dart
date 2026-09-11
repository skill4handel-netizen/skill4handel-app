import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../reviews/review_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final response = await dio.get('/chats/history', queryParameters: {'userId': Session.id});
      setState(() {
        items = ((response.data as List?) ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (e) {
      setState(() => items = []);
    }
  }

  bool alreadyReviewed(Map<String, dynamic> item) {
    final reviewedBy = item['reviewedBy'];
    if (reviewedBy is! List) return false;
    return reviewedBy.any((value) => value.toString() == Session.id.toString());
  }

  Future<void> writeReview(Map<String, dynamic> item) async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          otherId: int.tryParse(item['otherId'].toString()) ?? 0,
          otherName: item['otherName']?.toString() ?? 'User',
          skill: item['skillRequested']?.toString() ?? '',
        ),
      ),
    );
    if (saved == true && item['chatId'] != null) {
      await dio.post('/chats/${item['chatId']}/reviewed', data: {'userId': Session.id});
      await loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Swap history')),
      body: RefreshIndicator(
        onRefresh: loadHistory,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (items.isEmpty)
              const Text('No history yet.', style: TextStyle(color: AppColors.muted))
            else
              ...items.map((item) {
                final pay = item['payWithTokens'] == true;
                final status = item['status']?.toString() ?? '';
                final canReview = status == 'completed' && !alreadyReviewed(item);
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['requesterName'] ?? 'User'} requested ${item['skillRequested'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text('From ${item['requesterName'] ?? ''} to ${item['otherName'] ?? ''}'),
                      Text('Last offer by: ${item['proposedByName'] ?? ''}'),
                      Text(
                        pay
                            ? 'Paid ${item['extraTokens'] ?? 0} S4H instead of a skill'
                            : 'Offered skill: ${item['skillOffered'] ?? '-'}',
                      ),
                      Text('${item['duration'] ?? ''} min • ${item['mode'] ?? ''} • ${item['level'] ?? ''}'),
                      if ((item['rawStatus'] ?? '') == 'COUNTERED' ||
                          (item['status'] == 'pending' && item['rawStatus'] == 'COUNTERED'))
                        const Text('This was a counter offer'),
                      Text('Status: $status'),
                      if (canReview) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => writeReview(item),
                            style: AppTheme.solid(AppColors.green),
                            child: const Text('Write review', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}