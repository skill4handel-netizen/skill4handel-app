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

  void applyChat(dynamic data) {
    chatId = int.tryParse(data['id'].toString()) ?? chatId;
    pendingSwap = data['pendingSwap'] is Map
        ? Map<String, dynamic>.from(data['pendingSwap'] as Map)
        : null;
    lastCompleted = data['lastCompleted'] is Map
        ? Map<String, dynamic>.from(data['lastCompleted'] as Map)
        : null;
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
    } catch (e) {
      messages = [];
    }
    if (mounted) setState(() => loading = false);
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
      MaterialPageRoute(
        builder: (context) => SupportScreen(
          initialType: 'report',
          initialOtherName: widget.name,
        ),
      ),
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
      await dio.post('/auth/block', data: {
        'userId': Session.id,
        'otherId': widget.otherId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The member has been blocked and will no longer appear in matches or chat.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The member could not be blocked.')),
      );
    }
  }

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || chatId == null) return;
    controller.clear();
    try {
      final response = await dio.post('/chats/$chatId/messages', data: {
        'fromId': Session.id,
        'text': text,
      });
      setState(() => applyChat(response.data));
    } catch (e) {
      setState(() {
        messages.add({'type': 'text', 'fromId': Session.id, 'text': text});
      });
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
          photoUrl: widget.photoUrl,
          isCounter: isCounter,
        ),
      ),
    );
    if (done == true) await openChat();
  }

  Future<void> respond(String action) async {
    if (chatId == null) return;
    setState(() => working = true);
    try {
      final chat = await dio.post('/chats/$chatId/swap/respond', data: {
        'userId': Session.id,
        'action': action,
      });
      applyChat(chat.data);
      await openChat();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> cancelOffer() async {
    if (chatId == null) return;
    setState(() => working = true);
    try {
      final chat = await dio.post('/chats/$chatId/swap/cancel', data: {
        'userId': Session.id,
      });
      applyChat(chat.data);
      await openChat();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> markDone() async {
    if (chatId == null) return;
    setState(() => working = true);
    try {
      final chat = await dio.post('/chats/$chatId/swap/done', data: {
        'userId': Session.id,
      });
      applyChat(chat.data);
      await openChat();
      if (completed && !iAlreadyReviewed) {
        await writeReview();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> writeReview() async {
    if (!completed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A review may be submitted only after both parties confirm completion.')),
      );
      return;
    }
    if (widget.otherId == 0) return;
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
  bool get completed {
    if (pendingSwap?['status']?.toString() == 'completed') return true;
    return lastCompleted != null;
  }

  bool get iProposed => pendingSwap?['proposedBy']?.toString() == Session.id.toString();

  bool get iAlreadyDone {
    final doneBy = pendingSwap?['doneBy'] ?? lastCompleted?['doneBy'];
    if (doneBy is! List) return false;
    return doneBy.any((item) => item.toString() == Session.id.toString());
  }

  bool get iAlreadyReviewed {
    final reviewedBy = pendingSwap?['reviewedBy'] ?? lastCompleted?['reviewedBy'];
    if (reviewedBy is! List) return false;
    return reviewedBy.any((item) => item.toString() == Session.id.toString());
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = 'Submit offer';
    VoidCallback? onPressed = working ? null : startOffer;
    if (completed && !iAlreadyReviewed) {
      buttonText = 'Submit review';
      onPressed = working ? null : writeReview;
    } else if (completed && iAlreadyReviewed) {
      buttonText = 'Review submitted';
      onPressed = null;
    } else if (accepted) {
      buttonText = iAlreadyDone ? 'Awaiting the other party' : 'Confirm completion';
      onPressed = iAlreadyDone || working ? null : markDone;
    } else if (pending) {
      buttonText = iProposed ? 'Awaiting a response' : 'Respond above';
      onPressed = null;
    }

    final photo = widget.photoUrl?.trim() ?? '';
    return Scaffold(
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
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
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
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: openProfile,
                          child: const Text('View profile'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: openProfile,
                          child: const Text('View reviews'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingSwap != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF4FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${pendingSwap?['proposedByName'] ?? Session.name} requested ${pendingSwap?['skillRequested'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text('Offered: ${pendingSwap?['skillOffered'] ?? '-'}'),
                        if ((pendingSwap?['extraTokens'] ?? 0).toString() != '0')
                          Text('Tokens: ${pendingSwap?['extraTokens']}'),
                        if ((pendingSwap?['scheduledAt'] ?? pendingSwap?['when'] ?? '').toString().isNotEmpty)
                          Text('Scheduled: ${pendingSwap?['scheduledAt'] ?? pendingSwap?['when']}'),
                        Text('${pendingSwap?['duration'] ?? ''} min • ${pendingSwap?['mode'] ?? ''} • ${pendingSwap?['level'] ?? ''}'),
                        Text('Status: ${pendingSwap?['status']}'),
                        if (pending && iProposed)
                          TextButton(onPressed: working ? null : cancelOffer, child: const Text('Cancel offer')),
                        if (pending && !iProposed)
                          Row(
                            children: [
                              TextButton(onPressed: working ? null : () => respond('accepted'), child: const Text('Accept')),
                              TextButton(onPressed: working ? null : () => startOffer(isCounter: true), child: const Text('Counter-offer')),
                              TextButton(onPressed: working ? null : () => respond('rejected'), child: const Text('Decline')),
                            ],
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: messages.isEmpty
                      ? const Center(child: Text('No messages yet.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message['fromId'].toString() == Session.id.toString();
                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? AppColors.blue : AppColors.soft,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  message['text']?.toString() ?? '',
                                  style: TextStyle(color: isMe ? Colors.white : AppColors.text),
                                ),
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
                      child: Text(buttonText, style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: 'Write a message',
                              filled: true,
                              fillColor: const Color(0xFFEAF4FF),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
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
                ),
              ],
            ),
    );
  }
}