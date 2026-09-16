import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../profile/user_profile_screen.dart';
import '../support/support_screen.dart';
import 'complete_swap_screen.dart';
import 'history_screen.dart';
import 'offer_screen.dart';

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
  List<Map<String, dynamic>> messages = [];
  bool loading = true;

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
    messages = ((data['messages'] as List?) ?? [])
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
        builder: (context) => SupportScreen(initialType: 'report', initialOtherName: widget.name),
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
      await dio.post('/auth/block', data: {'userId': Session.id, 'otherId': widget.otherId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This member has been blocked.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  Future<void> openOffer() async {
    if (chatId == null) return;
    if (pendingSwap == null) {
      final created = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CompleteSwapScreen(
            otherName: widget.name,
            chatId: chatId!,
            otherId: widget.otherId,
            photoUrl: widget.photoUrl,
          ),
        ),
      );
      if (created == true) await openChat();
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferScreen(
          name: widget.name,
          otherId: widget.otherId,
          chatId: chatId!,
          photoUrl: widget.photoUrl,
        ),
      ),
    );
    await openChat();
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

  @override
  Widget build(BuildContext context) {
    final photo = widget.photoUrl?.trim() ?? '';
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
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
          IconButton(onPressed: blockUser, icon: const Icon(Icons.block, size: 26)),
          IconButton(onPressed: reportUser, icon: const Icon(Icons.flag_outlined, size: 26)),
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
            },
            icon: const Icon(Icons.history, size: 26),
          ),
        ],
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: openProfile, child: const Text('Profile'))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: openOffer,
                          style: AppTheme.solid(AppColors.green),
                          child: Text(pendingSwap == null ? 'New offer' : 'View offer', style: const TextStyle(color: Colors.white)),
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
                                child: Text(
                                  message['text']?.toString() ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                ),
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
                                child: Text(
                                  message['text']?.toString() ?? '',
                                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomPad),
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