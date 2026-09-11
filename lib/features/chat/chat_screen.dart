import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../reviews/review_screen.dart';
import 'complete_swap_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.name,
    required this.otherId,
    this.chatId,
  });

  final String name;
  final int otherId;
  final int? chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  int? chatId;
  int? requesterId;
  Map<String, dynamic>? pendingSwap;
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
    requesterId = int.tryParse(data['requesterId']?.toString() ?? '');
    pendingSwap = data['pendingSwap'] is Map
        ? Map<String, dynamic>.from(data['pendingSwap'] as Map)
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
        final response = await dio.get('/chats/$chatId');
        applyChat(response.data);
      }
    } catch (e) {
      messages = [];
    }
    if (mounted) setState(() => loading = false);
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

  Future<void> startOffer() async {
    if (chatId == null) return;
    final done = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompleteSwapScreen(
          otherName: widget.name,
          chatId: chatId!,
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
      if (pendingSwap?['status']?.toString() == 'completed' && !iAlreadyReviewed) {
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
    if (widget.otherId == 0) return;
    final saved = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewScreen(
          otherId: widget.otherId,
          otherName: widget.name,
          skill: pendingSwap?['skillRequested']?.toString() ?? '',
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
  bool get completed => pendingSwap?['status']?.toString() == 'completed';
  bool get rejected => pendingSwap?['status']?.toString() == 'rejected';
  bool get iProposed => pendingSwap?['proposedBy']?.toString() == Session.id.toString();

  bool get iAlreadyDone {
    final doneBy = pendingSwap?['doneBy'];
    if (doneBy is! List) return false;
    return doneBy.any((item) => item.toString() == Session.id.toString());
  }

  bool get iAlreadyReviewed {
    final reviewedBy = pendingSwap?['reviewedBy'];
    if (reviewedBy is! List) return false;
    return reviewedBy.any((item) => item.toString() == Session.id.toString());
  }

  Widget report() {
    if (pendingSwap == null) return const SizedBox.shrink();
    final offer = pendingSwap!;
    final pay = offer['payWithTokens'] == true;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deal: ${offer['status']}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Needs: ${offer['skillRequested'] ?? ''}'),
          Text(pay ? 'Pays: ${offer['extraTokens'] ?? 0} S4H' : 'Offers: ${offer['skillOffered'] ?? ''}'),
          Text('${offer['duration'] ?? ''} min • ${offer['mode'] ?? ''}'),
          if (pending && !iProposed) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: working ? null : () => respond('accepted'),
                    style: AppTheme.solid(AppColors.green),
                    child: const Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: working ? null : startOffer,
                    child: const Text('Counter'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: working ? null : () => respond('rejected'),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
          if (pending && iProposed) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: working ? null : cancelOffer,
                child: const Text('Cancel offer'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = 'Send offer';
    VoidCallback? onPressed = working ? null : startOffer;

    if (completed && !iAlreadyReviewed) {
      buttonText = 'Write review';
      onPressed = working ? null : writeReview;
    } else if (accepted) {
      buttonText = iAlreadyDone ? 'Waiting for the other person' : 'Mark as done';
      onPressed = iAlreadyDone || working ? null : markDone;
    } else if (pending) {
      buttonText = iProposed ? 'Waiting for response' : 'Respond in the report above';
      onPressed = null;
    } else {
      buttonText = 'Send offer';
      onPressed = working ? null : startOffer;
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                report(),
                Expanded(
                  child: ListView.builder(
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
                      style: AppTheme.solid(AppColors.green),
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
                              fillColor: AppColors.soft,
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