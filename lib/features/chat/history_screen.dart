import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/skill_labels.dart';
import '../../core/theme/app_theme.dart';
import '../reviews/review_screen.dart';
import 'chat_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final dio = Api.client;
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> walletItems = [];
  String filter = 'all';
  int tab = 0;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  String formatWhen(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = parsed.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}, ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  bool isExpired(Map swap) {
    final status = swap['status']?.toString() ?? '';
    if (status == 'expired') return true;
    final created = DateTime.tryParse('${swap['createdAt'] ?? ''}');
    final scheduled = DateTime.tryParse(
      '${swap['scheduledAt'] ?? swap['when'] ?? ''}',
    );
    if (status != 'pending') return false;
    final noReply =
        created != null && DateTime.now().difference(created).inHours >= 24;
    final timePassed = scheduled != null && !scheduled.isAfter(DateTime.now());
    return noReply || timePassed;
  }

  String statusText(Map item) {
    final group = item['group']?.toString() ?? '';
    if (item['status']?.toString() == 'expired') return S.t('expiredSession');
    if (group == 'pending') return S.t('pendingOffer');
    if (group == 'open') return S.t('openSession');
    return item['status']?.toString() ?? S.t('closed');
  }

  Future<void> loadAll() async {
    final merged = <Map<String, dynamic>>[];
    try {
      final chats = await dio.get(
        '/chats',
        queryParameters: {'userId': Session.id},
      );
      for (final raw in ((chats.data as List?) ?? [])) {
        final item = Map<String, dynamic>.from(raw as Map);
        final swap = item['pendingSwap'] is Map
            ? Map<String, dynamic>.from(item['pendingSwap'] as Map)
            : null;
        final status = swap?['status']?.toString() ?? '';
        if (swap != null && isExpired(swap)) {
          merged.add({
            ...item,
            ...swap,
            'otherName': item['name'],
            'group': 'closed',
            'status': 'expired',
          });
        } else if (status == 'pending' || status == 'accepted') {
          merged.add({
            ...item,
            ...?swap,
            'otherName': item['name'],
            'group': status == 'accepted' ? 'open' : 'pending',
          });
        }
      }
    } catch (_) {}
    try {
      final history = await dio.get(
        '/chats/history',
        queryParameters: {'userId': Session.id},
      );
      for (final raw in ((history.data as List?) ?? [])) {
        final item = Map<String, dynamic>.from(raw as Map);
        final expired =
            item['status']?.toString() == 'cancelled' && isExpired(item);
        merged.add({
          ...item,
          'group': 'closed',
          if (expired) 'status': 'expired',
        });
      }
    } catch (_) {}
    try {
      final me = await dio.get(
        '/auth/me',
        queryParameters: {'userId': Session.id},
      );
      final user = me.data is Map ? (me.data['user'] ?? me.data) : null;
      if (user is Map) Session.apply(Map<String, dynamic>.from(user));
      walletItems = List<Map<String, dynamic>>.from(Session.history);
    } catch (_) {
      walletItems = List<Map<String, dynamic>>.from(Session.history);
    }
    if (mounted) setState(() => allItems = merged);
  }

  List<Map<String, dynamic>> get visible {
    if (filter == 'all') return allItems;
    return allItems.where((item) => item['group'] == filter).toList();
  }

  bool alreadyReviewed(Map item) {
    final reviewedBy = item['reviewedBy'];
    return reviewedBy is List &&
        reviewedBy.any((value) => value.toString() == Session.id.toString());
  }

  Future<void> writeReview(Map item) async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          otherId: int.tryParse('${item['otherId'] ?? 0}') ?? 0,
          otherName: item['otherName']?.toString() ?? S.t('member'),
          skill: item['skillRequested']?.toString() ?? '',
        ),
      ),
    );
    if (saved == true && item['chatId'] != null) {
      await dio.post(
        '/chats/${item['chatId']}/reviewed',
        data: {'userId': Session.id},
      );
      await loadAll();
    }
  }

  void openChat(Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          name: (item['name'] ?? item['otherName'] ?? S.t('member')).toString(),
          otherId: int.tryParse('${item['otherId'] ?? 0}') ?? 0,
          chatId: int.tryParse('${item['id'] ?? item['chatId'] ?? 0}'),
          photoUrl: item['photoUrl']?.toString(),
        ),
      ),
    ).then((_) => loadAll());
  }

  Future<void> deleteItem(Map item) async {
    final chatId = item['chatId'] ?? item['id'];
    if (chatId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.t('deleteRecord')),
        content: Text(S.t('deleteRecordBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.t('delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.delete(
        '/chats/$chatId',
        queryParameters: {'userId': Session.id},
      );
      await loadAll();
    } catch (_) {}
  }

  Future<void> deleteWallet(Map item) async {
    final id = item['id'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.t('deleteMovement')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.t('delete')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (id != null) {
        await dio.delete(
          '/auth/transaction',
          queryParameters: {'userId': Session.id, 'id': id},
        );
      }
    } catch (_) {}
    final next = Session.history.where((row) {
      if (id != null && row['id'] != null) {
        return row['id'].toString() != id.toString();
      }
      return !(row['title']?.toString() == item['title']?.toString() &&
          row['amount']?.toString() == item['amount']?.toString());
    }).toList();
    Session.history = next;
    await Session.save();
    if (!mounted) return;
    setState(() => walletItems = next);
  }

  Widget chip(String value, String label, IconData icon, Color color) {
    final selected = filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16, color: selected ? Colors.white : color),
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        selected: selected,
        selectedColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        onSelected: (_) => setState(() => filter = value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(S.t('history')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: loadAll,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => tab = 0),
                    style: AppTheme.solid(
                      tab == 0 ? AppColors.blue : Colors.grey,
                    ),
                    icon: const Icon(Icons.swap_horiz, color: Colors.white),
                    label: Text(
                      S.t('offersTab'),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => tab = 1),
                    style: AppTheme.solid(
                      tab == 1 ? AppColors.blue : Colors.grey,
                    ),
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      S.t('wallet'),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (tab == 0) ...[
              Wrap(
                children: [
                  chip('all', S.t('all'), Icons.apps, AppColors.blue),
                  chip(
                    'pending',
                    S.t('pending'),
                    Icons.hourglass_top,
                    const Color(0xFFE3A008),
                  ),
                  chip(
                    'open',
                    S.t('open'),
                    Icons.check_circle,
                    AppColors.green,
                  ),
                  chip(
                    'closed',
                    S.t('closed'),
                    Icons.cancel,
                    const Color(0xFFD92D20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                Text(
                  S.t('noFilterItems'),
                  style: TextStyle(color: AppColors.muted),
                )
              else
                ...visible.map((item) {
                  final group = item['group']?.toString() ?? '';
                  final canReview =
                      group == 'closed' &&
                      item['status']?.toString() == 'completed' &&
                      !alreadyReviewed(item);
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE4E7EC)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['otherName']?.toString() ??
                              item['name']?.toString() ??
                              'Member',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          statusText(item),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if ((item['skillRequested'] ?? '')
                            .toString()
                            .isNotEmpty)
                          Text(
                            '${S.t('requested')}: ${skillLabel(item['skillRequested']?.toString() ?? '')}',
                          ),
                        if ((item['skillOffered'] ?? '').toString().isNotEmpty)
                          Text(
                            '${S.t('inReturn')}: ${skillLabel(item['skillOffered']?.toString() ?? '')}',
                          ),
                        if ((item['scheduledAt'] ?? item['when'] ?? '')
                            .toString()
                            .isNotEmpty)
                          Text(formatWhen(item['scheduledAt'] ?? item['when'])),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (group != 'closed')
                              TextButton(
                                onPressed: () => openChat(item),
                                child: Text(S.t('openChat')),
                              ),
                            TextButton(
                              onPressed: () => deleteItem(item),
                              child: Text(S.t('delete')),
                            ),
                          ],
                        ),
                        if (canReview)
                          ElevatedButton.icon(
                            onPressed: () => writeReview(item),
                            style: AppTheme.solid(AppColors.green),
                            icon: const Icon(Icons.star, color: Colors.white),
                            label: Text(
                              S.t('writeReview'),
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
            ],
            if (tab == 1) ...[
              Text(
                '${S.t('tokens')}  ${Session.balance} S4H',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              if (walletItems.isEmpty)
                Text(
                  S.t('noTransactions'),
                  style: TextStyle(color: AppColors.muted),
                )
              else
                ...walletItems.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.toll),
                    title: Text(item['title']?.toString() ?? S.t('history')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item['amount']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        IconButton(
                          onPressed: () => deleteWallet(item),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
