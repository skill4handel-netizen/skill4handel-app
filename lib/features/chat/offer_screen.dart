import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/skill_labels.dart';
import '../../core/theme/app_theme.dart';
import '../reviews/review_screen.dart';
import 'complete_swap_screen.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({
    super.key,
    required this.name,
    required this.otherId,
    required this.chatId,
    this.photoUrl,
  });

  final String name;
  final int otherId;
  final int chatId;
  final String? photoUrl;

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  final dio = Dio(
    BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'),
  );
  Map<String, dynamic>? pendingSwap;
  Map<String, dynamic>? lastCompleted;
  bool loading = true;
  bool working = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  String apiError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return S.t('requestFailed');
  }

  Future<void> load() async {
    try {
      final response = await dio.get(
        '/chats/${widget.chatId}',
        queryParameters: {'userId': Session.id},
      );
      pendingSwap = response.data['pendingSwap'] is Map
          ? Map<String, dynamic>.from(response.data['pendingSwap'] as Map)
          : null;
      lastCompleted = response.data['lastCompleted'] is Map
          ? Map<String, dynamic>.from(response.data['lastCompleted'] as Map)
          : null;
    } catch (_) {}
    if (mounted) setState(() => loading = false);
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

  DateTime? get scheduledAt => DateTime.tryParse(
    '${pendingSwap?['scheduledAt'] ?? pendingSwap?['when'] ?? ''}',
  );
  bool get timeReached =>
      scheduledAt != null && !scheduledAt!.isAfter(DateTime.now());
  bool get pending => pendingSwap?['status']?.toString() == 'pending';
  bool get accepted => pendingSwap?['status']?.toString() == 'accepted';
  bool get completed =>
      pendingSwap?['status']?.toString() == 'completed' ||
      lastCompleted != null;
  bool get iProposed =>
      pendingSwap?['proposedBy']?.toString() == Session.id.toString();
  bool get isCounter => pendingSwap?['rawStatus']?.toString() == 'COUNTERED';
  bool get canCounter => pending && !iProposed && !isCounter;
  bool get iAlreadyDone {
    final doneBy = pendingSwap?['doneBy'] ?? lastCompleted?['doneBy'];
    return doneBy is List &&
        doneBy.any((item) => item.toString() == Session.id.toString());
  }

  String exchangeType(Map? offer) {
    if (offer == null) return '';
    final volunteer =
        offer['volunteer'] == true ||
        '${offer['level']}'.toLowerCase().contains('volunteer');
    final tokens = int.tryParse('${offer['extraTokens'] ?? 0}') ?? 0;
    final offered = '${offer['skillOffered'] ?? ''}'.trim();
    if (volunteer) return 'Volunteer';
    if (tokens > 0 && offered.isNotEmpty) return 'Skill + tokens';
    if (tokens > 0) return 'Tokens only';
    if ('${offer['level']}'.contains('Skill +')) return 'Skill + tokens';
    if ('${offer['level']}'.contains('Tokens')) return 'Tokens only';
    return 'Skill for skill';
  }

  List<Map<String, String>> changes() {
    final current = pendingSwap;
    final previous = current?['previous'];
    if (current == null || previous is! Map) return [];
    final items = <Map<String, String>>[];
    void add(String label, dynamic a, dynamic b) {
      final left = (a ?? '—').toString();
      final right = (b ?? '—').toString();
      if (left != right) {
        items.add({
          'label': label,
          'from': left.isEmpty ? '—' : left,
          'to': right.isEmpty ? '—' : right,
        });
      }
    }

    add(
      'Type',
      exchangeType(Map<String, dynamic>.from(previous)),
      exchangeType(current),
    );
    add(S.t('returnSkill'), previous['skillOffered'], current['skillOffered']);
    add(S.t('tokensLabel'), previous['extraTokens'], current['extraTokens']);
    add(S.t('duration'), previous['duration'], current['duration']);
    add(S.t('mode'), previous['mode'], current['mode']);
    add(
      S.t('schedule'),
      formatWhen(previous['scheduledAt'] ?? previous['when']),
      formatWhen(current['scheduledAt'] ?? current['when']),
    );
    return items;
  }

  Future<void> act(String path, Map data) async {
    setState(() => working = true);
    try {
      await dio.post('/chats/${widget.chatId}$path', data: data);
      await load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> startAccept() async {
    final volunteer =
        pendingSwap?['volunteer'] == true ||
        '${pendingSwap?['level']}'.toLowerCase().contains('volunteer');
    final tokens = int.tryParse('${pendingSwap?['extraTokens'] ?? 0}') ?? 0;
    final offered = '${pendingSwap?['skillOffered'] ?? ''}'.trim();
    String payMode = 'skill';
    if (volunteer) {
      payMode = 'volunteer';
    } else if (tokens > 0 && offered.isNotEmpty) {
      payMode = 'both';
    } else if (tokens > 0) {
      payMode = 'tokens';
    }
    final done = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompleteSwapScreen(
          otherName: widget.name,
          chatId: widget.chatId,
          otherId: widget.otherId,
          photoUrl: widget.photoUrl,
          isAccept: true,
          initialSkillRequested:
              pendingSwap?['skillRequested']?.toString() ?? '',
          initialDuration: '${pendingSwap?['duration'] ?? '60'}',
          initialMode: '${pendingSwap?['mode'] ?? 'Online'}',
          initialLocation: '${pendingSwap?['location'] ?? ''}',
          initialWhen: scheduledAt,
          initialPayMode: payMode,
          initialTokens: '$tokens',
        ),
      ),
    );
    if (done == true) await load();
  }

  Future<void> startCounter() async {
    final done = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompleteSwapScreen(
          otherName: widget.name,
          chatId: widget.chatId,
          otherId: widget.otherId,
          photoUrl: widget.photoUrl,
          isCounter: true,
          initialSkillRequested:
              pendingSwap?['skillRequested']?.toString() ?? '',
          initialDuration: '${pendingSwap?['duration'] ?? '60'}',
          initialMode: '${pendingSwap?['mode'] ?? 'Online'}',
          initialLocation: '${pendingSwap?['location'] ?? ''}',
          initialWhen: scheduledAt,
        ),
      ),
    );
    if (done == true) await load();
  }

  Future<void> writeReview() async {
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          otherId: widget.otherId,
          otherName: widget.name,
          skill:
              (lastCompleted?['skillRequested'] ??
                      pendingSwap?['skillRequested'] ??
                      '')
                  .toString(),
        ),
      ),
    );
    if (saved == true) {
      await act('/reviewed', {'userId': Session.id});
    }
  }

  Widget row(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = pendingSwap ?? lastCompleted;
    final type = exchangeType(offer);
    return Scaffold(
      appBar: AppBar(title: Text(S.t('offer'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (pendingSwap == null && !completed)
                  Text(S.t('noOpenOffer'))
                else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8EF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isCounter
                        ? S.t('counterOffer')
                        : (accepted ? S.t('agreedSession') : S.t('offer')),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  row(
                    S.t('requested'),
                    skillLabel((offer?['skillRequested'] ?? '').toString()),
                  ),
                  row(
                    S.t('inReturn'),
                    skillLabel((offer?['skillOffered'] ?? '').toString()),
                  ),
                  row(S.t('tokensLabel'), '${offer?['extraTokens'] ?? 0}'),
                  row(
                    S.t('when'),
                    formatWhen(offer?['scheduledAt'] ?? offer?['when']),
                  ),
                  row(S.t('duration'), '${offer?['duration'] ?? ''} min'),
                  row('How', '${offer?['mode'] ?? ''}'),
                  if (changes().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      S.t('whatChanged'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    for (final item in changes())
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF4FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${item['label']}:  ${item['from']}  →  ${item['to']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  if (pending && iProposed)
                    OutlinedButton(
                      onPressed: working
                          ? null
                          : () => act('/swap/cancel', {'userId': Session.id}),
                      child: Text(S.t('cancelOffer')),
                    ),
                  if (pending && !iProposed) ...[
                    ElevatedButton.icon(
                      onPressed: working ? null : startAccept,
                      style: AppTheme.solid(AppColors.green),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        S.t('accept'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    if (canCounter) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: working ? null : startCounter,
                        style: AppTheme.solid(const Color(0xFFE3A008)),
                        icon: const Icon(Icons.sync_alt, color: Colors.white),
                        label: Text(
                          S.t('counter'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: working
                          ? null
                          : () => act('/swap/respond', {
                              'userId': Session.id,
                              'action': 'rejected',
                            }),
                      style: AppTheme.solid(const Color(0xFFD92D20)),
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: Text(
                        S.t('decline'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  if (accepted && !timeReached)
                    Text(
                      S.fill('completionAfter', {
                        'when': formatWhen(scheduledAt),
                      }),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  if (accepted && timeReached && !iAlreadyDone)
                    ElevatedButton(
                      onPressed: working
                          ? null
                          : () => act('/swap/done', {'userId': Session.id}),
                      style: AppTheme.solid(AppColors.green),
                      child: Text(
                        S.t('confirmDone'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  if (completed)
                    ElevatedButton(
                      onPressed: writeReview,
                      style: AppTheme.solid(AppColors.green),
                      child: Text(
                        S.t('writeReview'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
