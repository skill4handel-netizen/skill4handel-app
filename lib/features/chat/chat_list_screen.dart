import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import 'chat_screen.dart';

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

  Future<void> deleteChat(int id) async {
    await dio.delete('/chats/$id', queryParameters: {'userId': Session.id});
    await loadChats();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: loadChats,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Chats', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          if (chats.isEmpty)
            const Text('No chats yet.', style: TextStyle(color: AppColors.muted))
          else
            ...chats.map((chat) {
              return Dismissible(
                key: ValueKey(chat['id']),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => deleteChat(int.tryParse(chat['id'].toString()) ?? 0),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(chat['name']?.toString() ?? 'User'),
                  subtitle: Text(chat['last']?.toString() ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          name: chat['name']?.toString() ?? 'User',
                          otherId: int.tryParse(chat['otherId'].toString()) ?? 0,
                          chatId: int.tryParse(chat['id'].toString()),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}