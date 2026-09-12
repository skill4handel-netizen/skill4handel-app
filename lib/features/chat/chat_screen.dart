import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../profile/user_profile_screen.dart';
import '../reviews/review_screen.dart';
import '../support/support_screen.dart';
import 'complete_swap_screen.dart';
import 'history_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.name,
    required this.otherId,
    this.chatId,
    this.photoUrl,
  });

  final String name;
  final int otherId;
  final int? chatId;
  final String? photoUrl;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  int? chatId;
  Map<String, dynamic>? pendingSwap;
  Map<String, dynamic>? lastCompleted;
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  bool working = false;

  @override
  void initState() {
    super.initState();
    chatId = widget.chatId;
    openChat();
  }

  String apiError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
    }
    return 'The request could not be completed.';
  }

  void applyChat(dynamic data) {
    chatId = int.tryParse(data['id'].toString()) ?? chatId;
    pendingSwap = data['pendingSwap'] is Map ? Map<String, dynamic>.from(data['pendingSwap'] as Map) : null;
    lastCompleted = data['lastCompleted'] is Map ? Map<String, dynamic>.from(data['lastCompleted'] as Map) : null;
    final loaded = (data['messages'] as List?) ?? [];
    messages = loaded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .where((item) => (item['type']?.toString() ?? 'text') == 'text')
        .toList();
  }

  Future<void> openChat() async {
    try {
      if (chatId == null) {
        final response = await dio.post('/chats/open', data: {
          'myId': Session.id,
          'myName': Session.name,
          'otherId': widget.otherId,
          'otherName': widget.name,
        });
        applyChat(response.data);
      } else {
        final response = await dio.get('/chats/$chatId', queryParameters: {'userId': Session.id});
        applyChat(response.data);
      }
    } catch (_) {
      messages = [];
    }
    if (mounted) setState(() => loading = false);
  }

  String formatWhen(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final local = parsed.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}, ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  DateTime? get scheduledAt => DateTime.tryParse('${pendingSwap?['scheduledAt'] ?? pendingSwap?['when'] ?? ''}');
  bool get timeReached {
    final time = scheduledAt;
    return time != null && !time.isAfter(DateTime.now());
  }

  List<Map<String, String>> counterChanges() {
    final current = pendingSwap;
    final previous = current?['previous'];
    if (current == null || previous is! Map) return [];
    final changes = <Map<String, String>>[];
    void add(String label, dynamic before, dynamic after) {
      final left = (before ?? '—').toString().trim();
      final right = (after ?? '—').toString().trim();
      if (left != right) changes.add({'label': label, 'from': left.isEmpty ? '—' : left, 'to': right.isEmpty ? '—' : right});
    }

    add('Return skill', previous['skillOffered'], current['skillOffered']);
    add('Tokens', previous['extraTokens'], current['extraTokens']);
    add('Duration', previous['duration'], current['duration']);
    add('Mode', previous['mode'], current['mode']);
    add('Type', previous['level'], current['level']);
    add('Schedule', formatWhen(previous['scheduledAt'] ?? previous['when']), formatWhen(current['scheduledAt'] ?? current['when']));
    return changes;
  }

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          name: widget.name,
          email: '',
          city: '',
          offers: '',
          needs: '',
          otherId: widget.otherId,
          photoUrl: widget.photoUrl,
        ),
      ),
    );
  }

  Future<void> reportUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SupportScreen(initialType: 'report', initialOtherName: widget.name)),
    );
  }

  Future<void> blockUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this member?'),
        content: const Text('This member will no longer appear in Search, Matches or Chat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Block')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.post('/auth/block', data: {'userId': Session.id, 'otherId': widget.otherId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This member has been blocked.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || chatId == null) return;
    controller.clear();
    try {
      final response = await dio.post('/chats/$chatId/messages', data: {'fromId': Session.id, 'text': text});
      setState(() => applyChat(response.data));
    } catch (_) {
      setState(() => messages.add({'type': 'text', 'fromId': Session.id, 'text': text}));
    }
  }

  Future<void> startOffer({bool isCounter = false}) async {
    if (chatId == null) return;
    final done = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompleteSwapScreen(
          otherName: widget.name,
          chatId: chatId!,
          otherId: widget.otherId,
          photoUrl: widget.photoUrl,
          isCounter: isCounter,
          initialSkillRequested: pendingSwap?['skillRequested']?.toString() ?? '',
        ),
      ),
    );
    if (done == true) await openChat();
  }

  Future<void> respond(String action) async {
    if (chatId == null) return;
    setState(() => working = true);
    try {
      final chat = await dio.post('/chats/$chatId/swap/respond', data: {'userId': Session.id, 'action': action});
      applyChat(chat.data);
      await openChat();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> cancelOffer() async {
    if (chatId == null) return;
    setState(() => working = true);
    try {
      final chat = await dio.post('/chats/$chatId/swap/cancel', data: {'userId': Session.id});
      applyChat(chat.data);
      await openChat();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> markDone() async {
    if (chatId == null) return;
    if (!timeReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completion can be confirmed after ${formatWhen(scheduledAt)}.')),
      );
      return;
    }
    setState(() => working = true);
    try {
      final chat = await dio.post('/chats/$chatId/swap/done', data: {'userId': Session.id});
      applyChat(chat.data);
      await openChat();
      if (completed && !iAlreadyReviewed) await writeReview();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> writeReview() async {
    if (!completed) return;
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          otherId: widget.otherId,
          otherName: widget.name,
          skill: (lastCompleted?['skillRequested'] ?? pendingSwap?['skillRequested'] ?? '').toString(),
        ),
      ),
    );
    if (saved == true && chatId != null) {
      await dio.post('/chats/$chatId/reviewed', data: {'userId': Session.id});
      await openChat();
    }
  }

  bool get pending => pendingSwap?['status']?.toString() == 'pending';
  bool get accepted => pendingSwap?['status']?.toString() == 'accepted';
  bool get completed => pendingSwap?['status']?.toString() == 'completed' || lastCompleted != null;
  bool get iProposed => pendingSwap?['proposedBy']?.toString() == Session.id.toString();
  bool get iAlreadyDone {
    final doneBy = pendingSwap?['doneBy'] ?? lastCompleted?['doneBy'];
    return doneBy is List && doneBy.any((item) => item.toString() == Session.id.toString());
  }

  bool get iAlreadyReviewed {
    final reviewedBy = pendingSwap?['reviewedBy'] ?? lastCompleted?['reviewedBy'];
    return reviewedBy is List && reviewedBy.any((item) => item.toString() == Session.id.toString());
  }

  bool get isCounterOffer => pendingSwap?['rawStatus']?.toString() == 'COUNTERED' || counterChanges().isNotEmpty;

  String statusLabel() {
    if (accepted && !timeReached) return 'Agreed session';
    if (accepted && iAlreadyDone) return 'Waiting for the other member';
    if (accepted) return 'Agreed session';
    if (isCounterOffer && iProposed) return 'Counter-offer sent';
    if (isCounterOffer) return 'Counter-offer received';
    if (pending && iProposed) return 'Offer sent';
    if (pending) return 'New offer';
    return (pendingSwap?['status'] ?? '').toString();
  }

  Widget actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: working ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    String buttonText = 'Create offer';
    VoidCallback? onPressed = working ? null : () => startOffer();
    if (completed && !iAlreadyReviewed) {
      buttonText = 'Write review';
      onPressed = working ? null : writeReview;
    } else if (completed && iAlreadyReviewed) {
      buttonText = 'Review submitted';
      onPressed = null;
    } else if (accepted && !timeReached) {
      buttonText = 'Available after ${formatWhen(scheduledAt)}';
      onPressed = null;
    } else if (accepted) {
      buttonText = iAlreadyDone ? 'Waiting for the other member' : 'Confirm completion';
      onPressed = iAlreadyDone || working ? null : markDone;
    } else if (pending) {
      buttonText = iProposed ? 'Waiting for a reply' : 'Reply on the offer above';
      onPressed = null;
    }

    final photo = widget.photoUrl?.trim() ?? '';
    final requested = pendingSwap?['skillRequested']?.toString() ?? '';
    final offered = pendingSwap?['skillOffered']?.toString() ?? '';
    final changes = counterChanges();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        title: GestureDetector(
          onTap: openProfile,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.amber,
                backgroundImage: photo.isNotEmpty && !photo.startsWith('data:') ? NetworkImage(photo) : null,
                child: photo.isEmpty ? Text(widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?') : null,
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(widget.name, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        actions: [
          IconButton(onPressed: blockUser, icon: const Icon(Icons.block)),
          IconButton(onPressed: reportUser, icon: const Icon(Icons.flag_outlined)),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: openProfile, child: const Text('Profile')),
                  ),
                ),
                if (pendingSwap != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(statusLabel(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(requested, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 16)),
                        if (offered.isNotEmpty)
                          Text('In return: $offered', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                        if ((pendingSwap?['extraTokens'] ?? 0).toString() != '0')
                          Text('Tokens: ${pendingSwap?['extraTokens']}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                        if (formatWhen(pendingSwap?['scheduledAt'] ?? pendingSwap?['when']).isNotEmpty)
                          Text(formatWhen(pendingSwap?['scheduledAt'] ?? pendingSwap?['when']), style: const TextStyle(color: Colors.black87)),
                        if (changes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('What changed', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          for (final change in changes)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(change['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text('${change['from']}  →  ${change['to']}'),
                                ],
                              ),
                            ),
                        ],
                        if (pending && iProposed)
                          TextButton(onPressed: working ? null : cancelOffer, child: const Text('Cancel offer')),
                        if (pending && !iProposed)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                actionButton(label: 'Accept', icon: Icons.check_circle, color: AppColors.green, onTap: () => respond('accepted')),
                                const SizedBox(width: 6),
                                actionButton(label: 'Counter', icon: Icons.sync_alt, color: const Color(0xFFE3A008), onTap: () => startOffer(isCounter: true)),
                                const SizedBox(width: 6),
                                actionButton(label: 'Decline', icon: Icons.cancel, color: const Color(0xFFD92D20), onTap: () => respond('rejected')),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: messages.isEmpty
                      ? const Center(child: Text('No messages yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final fromId = int.tryParse('${message['fromId'] ?? 0}') ?? 0;
                            final isSystem = fromId == 0;
                            final isMe = fromId == Session.id;
                            if (isSystem) {
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFFEEF2F6), borderRadius: BorderRadius.circular(12)),
                                child: Text(message['text']?.toString() ?? '', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                              );
                            }
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.blue : const Color(0xFFFFF4D6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(message['text']?.toString() ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: onPressed,
                      style: AppTheme.solid(onPressed == null ? Colors.grey : AppColors.green),
                      child: Text(buttonText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + keyboard),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            hintText: 'Write a message',
                            filled: true,
                            fillColor: const Color(0xFFEAF4FF),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: send,
                        style: IconButton.styleFrom(backgroundColor: AppColors.blue),
                        icon: const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}