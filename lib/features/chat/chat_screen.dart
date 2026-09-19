import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/user_photo.dart';
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
  final dio = Dio(
    BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'),
  );
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
      if (data is Map && data['message'] != null)
        return data['message'].toString();
    }
    return 'The request could not be completed.';
  }

  void applyChat(dynamic data) {
    chatId = int.tryParse(data['id'].toString()) ?? chatId;
    pendingSwap = data['pendingSwap'] is Map
        ? Map<String, dynamic>.from(data['pendingSwap'] as Map)
        : null;
    messages = ((data['messages'] as List?) ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> openChat() async {
    try {
      if (chatId == null) {
        final response = await dio.post(
          '/chats/open',
          data: {
            'myId': Session.id,
            'myName': Session.name,
            'otherId': widget.otherId,
            'otherName': widget.name,
          },
        );
        applyChat(response.data);
      } else {
        final response = await dio.get(
          '/chats/$chatId',
          queryParameters: {'userId': Session.id},
        );
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
        builder: (context) =>
            SupportScreen(initialType: 'report', initialOtherName: widget.name),
      ),
    );
  }

  Future<void> blockUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.t('blockTitle')),
        content: Text(S.t('blockBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.t('block')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.post(
        '/auth/block',
        data: {'userId': Session.id, 'otherId': widget.otherId},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('blockedOk'))));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(apiError(e))));
    }
  }

  String prettyText(String raw) {
    const mapped = {
      'An offer has been sent. If there is no response within 24 hours, it will be cancelled.':
          'Offer sent. Waiting for a reply within 24 hours.',
      'A counter-offer has been sent.': 'Counter-offer sent.',
      'The offer has been accepted. The session is confirmed.':
          'Offer accepted. The session is confirmed.',
      'The offer has been declined.': 'Offer declined.',
      'The offer was cancelled. Both members may start a new request.':
          'Offer cancelled. A new request may be started.',
      'Completion has been confirmed by one member. Waiting for the other confirmation.':
          'One member confirmed completion. Waiting for the other confirmation.',
      'Both members confirmed completion. Reviews can now be written.':
          'Exchange completed. Reviews can now be written.',
      'New swap offer': 'New offer',
      'Counter offer': 'Counter-offer',
    };
    if (raw.startsWith('The offer has been accepted. Return skill:')) {
      return raw.replaceFirst(
        'The offer has been accepted. Return skill:',
        'Offer accepted. Return skill:',
      );
    }
    return mapped[raw] ?? S.maybe(raw);
  }

  String when(dynamic raw) {
    final parsed = DateTime.tryParse('$raw');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')} $hh:$mm';
  }

  Future<void> openOffer() async {
    if (!Session.profileComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Complete your profile before sending an offer. Missing: ${Session.profileMissing}. Save the profile page after adding them.',
          ),
        ),
      );
      return;
    }
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
      final response = await dio.post(
        '/chats/$chatId/messages',
        data: {'fromId': Session.id, 'text': text},
      );
      setState(() => applyChat(response.data));
    } catch (_) {
      setState(
        () =>
            messages.add({'type': 'text', 'fromId': Session.id, 'text': text}),
      );
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
              UserPhoto(
                url: photo,
                radius: 18,
                letter: widget.name.isNotEmpty ? widget.name[0] : '?',
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(widget.name, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: blockUser,
            icon: const Icon(Icons.block, size: 26),
          ),
          IconButton(
            onPressed: reportUser,
            icon: const Icon(Icons.flag_outlined, size: 26),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            icon: const Icon(Icons.history, size: 26),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
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
                          child: Text(S.t('profileBtn')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: openOffer,
                          style: AppTheme.solid(AppColors.green),
                          child: Text(
                            pendingSwap == null
                                ? S.t('newOffer')
                                : S.t('viewOffer'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: messages.isEmpty
                      ? Center(child: Text(S.t('noMessages')))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final fromId =
                                int.tryParse('${message['fromId'] ?? 0}') ?? 0;
                            final rawText = message['text']?.toString() ?? '';
                            final isSystem =
                                fromId == 0 ||
                                (message['type']?.toString() ?? '') ==
                                    'system' ||
                                S.isSystem(rawText);
                            final isMe = fromId == Session.id;
                            if (isSystem) {
                              return Center(
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F7FB),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: AppColors.blue,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        prettyText(rawText),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF1F2937),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (when(message['createdAt']).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            when(message['createdAt']),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? AppColors.blue
                                      : const Color(0xFFFFF4D6),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prettyText(rawText),
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    if (when(message['createdAt']).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          when(message['createdAt']),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe
                                                ? Colors.white70
                                                : AppColors.muted,
                                          ),
                                        ),
                                      ),
                                  ],
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
                            hintText: S.t('writeMessage'),
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
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.blue,
                        ),
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
