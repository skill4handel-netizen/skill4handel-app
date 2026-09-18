import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/user_photo.dart';
import 'chat_screen.dart';
import 'history_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final dio = Dio(
    BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'),
  );
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> loadChats() async {
    try {
      final response = await dio.get(
        '/chats',
        queryParameters: {'userId': Session.id},
      );
      if (!mounted) return;
      setState(() {
        chats = ((response.data as List?) ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (_) {
      if (mounted) setState(() => chats = []);
    }
  }

  int get unreadCount => chats.where((item) => item['unread'] == true).length;

  Future<void> openChat(Map<String, dynamic> chat) async {
    setState(() => chat['unread'] = false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          name: chat['name']?.toString() ?? 'Member',
          otherId: int.tryParse('${chat['otherId'] ?? 0}') ?? 0,
          chatId: int.tryParse('${chat['id'] ?? 0}'),
          photoUrl: chat['photoUrl']?.toString(),
        ),
      ),
    );
    await loadChats();
  }

  Future<void> deleteChat(Map<String, dynamic> chat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this chat?'),
        content: const Text(
          'The conversation and its messages will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.delete(
        '/chats/${chat['id']}',
        queryParameters: {'userId': Session.id},
      );
      await loadChats();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The chat could not be deleted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('chat')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              ).then((_) => loadChats());
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadChats,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mark_chat_unread, color: AppColors.green),
                    const SizedBox(width: 8),
                    Text(
                      '$unreadCount ${S.t('messages')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            if (chats.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.card(color: AppColors.soft),
                child: Column(
                  children: [
                    const Icon(
                      Icons.forum_outlined,
                      size: 48,
                      color: AppColors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      S.t('noChats'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              )
            else
              ...chats.map((chat) {
                final name = chat['name']?.toString() ?? 'Member';
                final unread = chat['unread'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: AppTheme.card(
                    color: unread ? AppColors.mint : Colors.white,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: UserPhoto(
                      url: chat['photoUrl']?.toString(),
                      radius: 26,
                      letter: name.isNotEmpty ? name[0] : '?',
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      chat['last']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (unread)
                          const Icon(
                            Icons.circle,
                            size: 10,
                            color: AppColors.green,
                          ),
                        IconButton(
                          onPressed: () => deleteChat(chat),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.coral,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => openChat(chat),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
