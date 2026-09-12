import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/user_photo.dart';
import '../profile/user_profile_screen.dart';
import 'chat_screen.dart';
import 'history_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  List<Map<String, dynamic>> chats = [];

  @override
  void initState() {
    super.initState();
    loadChats();
  }

  Future<void> loadChats() async {
    try {
      final response = await dio.get('/chats', queryParameters: {'userId': Session.id});
      setState(() {
        chats = ((response.data as List?) ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (e) {
      setState(() => chats = []);
    }
  }

  String subtitleOf(Map<String, dynamic> chat) {
    final swap = chat['pendingSwap'];
    if (swap is Map) {
      final status = swap['status']?.toString() ?? '';
      if (status == 'pending') return 'New swap offer';
      if (status == 'accepted') return 'Swap accepted';
      if (status == 'completed') return 'Swap completed';
      if (status == 'rejected') return 'Offer rejected';
      if (status == 'cancelled') return 'Offer cancelled';
    }
    return chat['last']?.toString() ?? '';
  }

  List<Map<String, dynamic>> get offers => chats.where((chat) {
        final swap = chat['pendingSwap'];
        return swap is Map && swap['status'] == 'pending';
      }).toList();

  List<Map<String, dynamic>> get others => chats.where((chat) {
        final swap = chat['pendingSwap'];
        return !(swap is Map && swap['status'] == 'pending');
      }).toList();

  void openProfile(Map<String, dynamic> chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          name: chat['name']?.toString() ?? 'User',
          email: '',
          city: '',
          offers: '',
          needs: '',
          otherId: int.tryParse(chat['otherId'].toString()) ?? 0,
          photoUrl: chat['photoUrl']?.toString(),
        ),
      ),
    );
  }

  Widget row(Map<String, dynamic> chat) {
    final name = chat['name']?.toString() ?? 'User';
    final photo = chat['photoUrl']?.toString() ?? '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: GestureDetector(
        onTap: () => openProfile(chat),
        child: UserPhoto(url: photo, letter: name.isNotEmpty ? name[0] : '?'),
      ),
      title: GestureDetector(
        onTap: () => openProfile(chat),
        child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      subtitle: Text(subtitleOf(chat)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              name: name,
              otherId: int.tryParse(chat['otherId'].toString()) ?? 0,
              chatId: int.tryParse(chat['id'].toString()),
              photoUrl: photo,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadChats,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Chats', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                },
                child: const Text('History'),
              ),
            ],
          ),
          if (offers.isNotEmpty) ...[
            const Text('Your offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...offers.map(row),
            const SizedBox(height: 16),
          ],
          const Text('Chats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (others.isEmpty && offers.isEmpty)
            const Text('No chats yet.', style: TextStyle(color: AppColors.muted))
          else
            ...others.map(row),
        ],
      ),
    );
  }
}