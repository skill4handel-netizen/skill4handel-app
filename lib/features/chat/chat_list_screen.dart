import '../../core/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page.dart';
import '../../core/widgets/user_photo.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final dio = Api.client;
  List<Map<String, dynamic>> chats = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  String when(dynamic raw) {
    final parsed = DateTime.tryParse('$raw');
    if (parsed == null) return '';
    final local = parsed.toLocal();
    final now = DateTime.now();
    final sameDay =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    if (sameDay) return '$hh:$mm';
    return '${local.day.toString().padLeft(2, '0')}-${local.month.toString().padLeft(2, '0')} $hh:$mm';
  }

  Future<void> load() async {
    try {
      final response = await dio.get(
        '/chats',
        queryParameters: {'userId': Session.id},
      );
      final items = ((response.data as List?) ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      items.sort((a, b) {
        final aTime =
            DateTime.tryParse('${a['lastAt'] ?? ''}') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bTime =
            DateTime.tryParse('${b['lastAt'] ?? ''}') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      if (mounted) setState(() => chats = items);
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openChat(Map<String, dynamic> chat) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          name: chat['name']?.toString() ?? '',
          otherId: int.tryParse('${chat['otherId'] ?? 0}') ?? 0,
          chatId: int.tryParse('${chat['id']}') ?? 0,
          photoUrl: chat['photoUrl']?.toString(),
        ),
      ),
    );
    load();
  }

  Future<void> deleteChat(Map<String, dynamic> chat) async {
    final swap = chat['pendingSwap'];
    final status = swap is Map ? swap['status']?.toString() : '';
    final name = chat['name']?.toString() ?? 'this member';
    final blocked = status == 'accepted';
    final sessionLine = status == 'accepted'
        ? 'Open accepted session with $name. It stays until both members mark it done. This chat cannot be deleted yet.'
        : status == 'pending'
            ? 'There is an unanswered offer with $name. Deleting this chat cancels that offer.'
            : 'There is no open session with $name.';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.t('deleteChat')),
        content: Text('$sessionLine\n\nDeleting this chat removes the messages, the offer record in this chat, and the chat itself. The other member is notified. Wallet history and reviews already saved are not deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(S.t('cancel'))),
          if (!blocked)
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(S.t('delete'))),
        ],
      ),
    );
    if (ok != true || blocked) return;
    try {
      await dio.delete('/chats/${chat['id']}', queryParameters: {'userId': Session.id});
      load();
    } catch (error) {
      if (!mounted) return;
      final message = error is DioException ? '${error.response?.data?['message'] ?? S.t('saveError')}' : S.t('saveError');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.t('chats'),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (loading) const LinearProgressIndicator(),
            if (!loading && chats.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 80),
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
                final name = chat['name']?.toString() ?? S.t('member');
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
                      '${when(chat['lastAt'])}  ${S.maybe(chat['last']?.toString() ?? '')}'
                          .trim(),
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
