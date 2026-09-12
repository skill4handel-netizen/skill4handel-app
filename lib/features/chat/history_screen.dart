import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../reviews/review_screen.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  List<Map<String, dynamic>> openItems = [];
  List<Map<String, dynamic>> closedItems = [];
  List<Map<String, dynamic>> walletItems = [];
  int tab = 0;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  String formatWhen(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = parsed.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}, ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> loadAll() async {
    try {
      final chats = await dio.get('/chats', queryParameters: {'userId': Session.id});
      openItems = ((chats.data as List?) ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((item) {
            final status = item['pendingSwap'] is Map ? item['pendingSwap']['status']?.toString() : '';
            return status == 'pending' || status == 'accepted';
          })
          .toList();
    } catch (_) {
      openItems = [];
    }
    try {
      final history = await dio.get('/chats/history', queryParameters: {'userId': Session.id});
      closedItems = ((history.data as List?) ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      closedItems = [];
    }
    try {
      final me = await dio.get('/auth/me', queryParameters: {'userId': Session.id});
      final user = me.data is Map ? (me.data['user'] ?? me.data) : null;
      if (user is Map) Session.apply(Map<String, dynamic>.from(user));
      walletItems = List<Map<String, dynamic>>.from(Session.history);
    } catch (_) {
      walletItems = List<Map<String, dynamic>>.from(Session.history);
    }
    if (mounted) setState(() {});
  }

  bool alreadyReviewed(Map item) {
    final reviewedBy = item['reviewedBy'];
    return reviewedBy is List && reviewedBy.any((value) => value.toString() == Session.id.toString());
  }

  Future<void> writeReview(Map item) async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          otherId: int.tryParse('${item['otherId'] ?? 0}') ?? 0,
          otherName: item['otherName']?.toString() ?? 'Member',
          skill: item['skillRequested']?.toString() ?? '',
        ),
      ),
    );
    if (saved == true && item['chatId'] != null) {
      await dio.post('/chats/${item['chatId']}/reviewed', data: {'userId': Session.id});
      await loadAll();
    }
  }

  void openChat(Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          name: (item['name'] ?? item['otherName'] ?? 'Member').toString(),
          otherId: int.tryParse('${item['otherId'] ?? 0}') ?? 0,
          chatId: int.tryParse('${item['id'] ?? item['chatId'] ?? 0}'),
          photoUrl: item['photoUrl']?.toString(),
        ),
      ),
    ).then((_) => loadAll());
  }

  Widget sectionButton(int value, String label, int count) {
    final selected = tab == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => tab = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : AppColors.soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text('$count', style: TextStyle(color: selected ? Colors.white : AppColors.text, fontWeight: FontWeight.w800)),
              Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.muted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget card({
    required String title,
    required String subtitle,
    required List<String> lines,
    String? badge,
    Color? badgeColor,
    Widget? action,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppColors.blue).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(badge, style: TextStyle(color: badgeColor ?? AppColors.blue, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
              ],
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AppColors.muted)),
            ],
            const SizedBox(height: 8),
            for (final line in lines)
              if (line.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(line),
                ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: RefreshIndicator(
        onRefresh: loadAll,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                sectionButton(0, 'Open', openItems.length),
                const SizedBox(width: 8),
                sectionButton(1, 'History', closedItems.length),
                const SizedBox(width: 8),
                sectionButton(2, 'Wallet', walletItems.length),
              ],
            ),
            const SizedBox(height: 16),
            if (tab == 0) ...[
              if (openItems.isEmpty)
                const Text('No open requests or sessions.', style: TextStyle(color: AppColors.muted))
              else
                ...openItems.map((item) {
                  final swap = item['pendingSwap'] is Map ? Map<String, dynamic>.from(item['pendingSwap'] as Map) : {};
                  final status = swap['status']?.toString() ?? '';
                  return card(
                    title: item['name']?.toString() ?? 'Member',
                    subtitle: status == 'accepted' ? 'Agreed session' : 'Open request',
                    badge: status == 'accepted' ? 'Session' : 'Offer',
                    badgeColor: status == 'accepted' ? AppColors.green : const Color(0xFFB54708),
                    lines: [
                      if ((swap['skillRequested'] ?? '').toString().isNotEmpty) 'Requested: ${swap['skillRequested']}',
                      if ((swap['skillOffered'] ?? '').toString().isNotEmpty) 'In return: ${swap['skillOffered']}',
                      if ((swap['extraTokens'] ?? 0).toString() != '0') 'Tokens: ${swap['extraTokens']}',
                      if ((swap['scheduledAt'] ?? swap['when'] ?? '').toString().isNotEmpty)
                        'When: ${formatWhen(swap['scheduledAt'] ?? swap['when'])}',
                    ],
                    onTap: () => openChat(item),
                  );
                }),
            ],
            if (tab == 1) ...[
              if (closedItems.isEmpty)
                const Text('No completed or cancelled exchanges yet.', style: TextStyle(color: AppColors.muted))
              else
                ...closedItems.map((item) {
                  final status = item['status']?.toString() ?? '';
                  final canReview = status == 'completed' && !alreadyReviewed(item);
                  return card(
                    title: item['otherName']?.toString() ?? 'Member',
                    subtitle: item['skillRequested']?.toString() ?? '',
                    badge: status,
                    badgeColor: status == 'completed' ? AppColors.green : const Color(0xFFB42318),
                    lines: [
                      if ((item['skillOffered'] ?? '').toString().isNotEmpty) 'In return: ${item['skillOffered']}',
                      if ((item['extraTokens'] ?? 0).toString() != '0') 'Tokens: ${item['extraTokens']}',
                      if ((item['scheduledAt'] ?? item['when'] ?? '').toString().isNotEmpty)
                        'When: ${formatWhen(item['scheduledAt'] ?? item['when'])}',
                      '${item['duration'] ?? ''} min • ${item['mode'] ?? ''}',
                    ],
                    action: canReview
                        ? ElevatedButton(
                            onPressed: () => writeReview(item),
                            style: AppTheme.solid(AppColors.green),
                            child: const Text('Write review', style: TextStyle(color: Colors.white)),
                          )
                        : null,
                  );
                }),
            ],
            if (tab == 2) ...[
              Text('Balance  ${Session.balance} S4H', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              if (walletItems.isEmpty)
                const Text('No wallet movements yet.', style: TextStyle(color: AppColors.muted))
              else
                ...walletItems.map((item) {
                  return card(
                    title: item['title']?.toString() ?? 'Movement',
                    subtitle: item['amount']?.toString() ?? '',
                    badge: 'S4H',
                    lines: const [],
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}