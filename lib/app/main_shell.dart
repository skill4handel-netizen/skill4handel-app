import '../core/api/api_client.dart';
import 'package:flutter/material.dart';
import '../core/constants/push_service.dart';
import '../core/constants/session.dart';
import '../core/l10n/app_strings.dart';
import '../features/chat/chat_list_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/search/search_screen.dart';
import '../features/support/support_screen.dart';
import '../features/wallet/wallet_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.userName});

  final String? userName;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final dio = Api.client;
  int index = 0;
  int unreadChats = 0;
  bool openingChat = false;

  @override
  void initState() {
    super.initState();
    PushService.registerToken();
    PushService.onChatOpened = openPendingChat;
    loadUnread();
    WidgetsBinding.instance.addPostFrameCallback((_) => openPendingChat());
  }

  @override
  void dispose() {
    if (PushService.onChatOpened == openPendingChat) {
      PushService.onChatOpened = null;
    }
    super.dispose();
  }

  Future<void> loadUnread() async {
    try {
      final response = await dio.get(
        '/chats',
        queryParameters: {'userId': Session.id},
      );
      final chats = ((response.data as List?) ?? []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      );
      final count = chats.where((chat) => chat['unread'] == true).length;
      if (mounted) setState(() => unreadChats = count);
    } catch (_) {}
  }

  Future<void> openPendingChat() async {
    final chatId = PushService.pendingChatId;
    if (chatId <= 0 || openingChat || !mounted) return;
    openingChat = true;
    PushService.pendingChatId = 0;
    try {
      final response = await dio.get(
        '/chats/$chatId',
        queryParameters: {'userId': Session.id},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final userA = int.tryParse('${data['userA'] ?? 0}') ?? 0;
      final userB = int.tryParse('${data['userB'] ?? 0}') ?? 0;
      final otherId = userA == Session.id ? userB : userA;
      final name = userA == Session.id
          ? '${data['nameB'] ?? ''}'
          : '${data['nameA'] ?? ''}';
      if (!mounted || otherId <= 0) return;
      setState(() => index = 2);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            name: name.isEmpty ? S.t('chat') : name,
            otherId: otherId,
            chatId: chatId,
          ),
        ),
      );
      loadUnread();
    } catch (_) {
    } finally {
      openingChat = false;
    }
  }

  void goTo(int value) {
    setState(() => index = value);
    loadUnread();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(
        onSearchTap: () => goTo(1),
        onChatTap: () => goTo(2),
        onWalletTap: () => goTo(3),
        onProfileTap: () => goTo(4),
      ),
      const SearchScreen(),
      const ChatListScreen(),
      const WalletScreen(),
      ProfileScreen(userName: widget.userName, onSaved: () => goTo(0)),
      const SupportScreen(),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: pages[index],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        onTap: goTo,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: S.t('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: S.t('search'),
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: unreadChats > 0,
              label: Text('$unreadChats'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            label: S.t('chat'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: S.t('wallet'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: S.t('profile'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.support_agent),
            label: S.t('support'),
          ),
        ],
      ),
    );
  }
}
