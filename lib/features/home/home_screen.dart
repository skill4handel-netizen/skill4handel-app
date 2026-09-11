import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../chat/chat_screen.dart';
import '../profile/user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSearchTap});

  final VoidCallback? onSearchTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  List<Map<String, dynamic>> people = [];
  List<Map<String, dynamic>> alerts = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final usersRes = await dio.get('/matches', queryParameters: {'userId': Session.id});
      final users = (usersRes.data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final chatsRes = await dio.get('/chats', queryParameters: {'userId': Session.id});
      final chats = ((chatsRes.data as List?) ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      setState(() {
        people = users;
        alerts = chats;
      });
    } catch (e) {
      setState(() {
        people = [];
        alerts = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          Session.name.isNotEmpty ? 'Hello, ${Session.name}' : 'Hello',
          style: const TextStyle(fontSize: 16, color: AppColors.muted),
        ),
        const SizedBox(height: 4),
        const Text('What do you need today?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: widget.onSearchTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(16)),
            child: const Row(
              children: [
                Icon(Icons.search, color: AppColors.muted),
                SizedBox(width: 10),
                Text('Search a skill you need', style: TextStyle(color: AppColors.muted, fontSize: 16)),
              ],
            ),
          ),
        ),
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...alerts.map((chat) {
            final pending = chat['pendingSwap'] is Map && chat['pendingSwap']['status'] == 'pending';
            final waitingForMe = pending &&
                chat['pendingSwap']['proposedBy'].toString() != Session.id.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
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
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: waitingForMe ? const Color(0xFFEAF7EE) : AppColors.soft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    waitingForMe
                        ? 'New offer from ${chat['name']}'
                        : 'Chat with ${chat['name']}: ${chat['last'] ?? ''}',
                  ),
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 24),
        const Text('Suggested matches', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (Session.offers.trim().isEmpty && Session.needs.trim().isEmpty)
          const Text('Set your skills in Profile to see real matches.', style: TextStyle(color: AppColors.muted))
        else if (people.isEmpty)
          const Text('No skill matches yet.', style: TextStyle(color: AppColors.muted))
        else
          ...people.map((person) {
            final name = person['name']?.toString() ?? 'User';
            final otherId = int.tryParse(person['id'].toString()) ?? 0;
            final reasons = ((person['reasons'] as List?) ?? []).map((item) => item.toString()).toList();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        name: name,
                        email: person['email']?.toString() ?? '',
                        city: person['city']?.toString() ?? '',
                        offers: person['offers']?.toString() ?? '',
                        needs: person['needs']?.toString() ?? '',
                        otherId: otherId,
                        rating: double.tryParse(person['rating'].toString()) ?? 0,
                        reviews: ((person['reviews'] as List?) ?? [])
                            .map((item) => Map<String, dynamic>.from(item as Map))
                            .toList(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('${person['score'] ?? 0}% match',
                          style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
                      if ((person['city'] ?? '').toString().isNotEmpty) Text(person['city'].toString()),
                      if ((person['offers'] ?? '').toString().isNotEmpty) Text('Offers: ${person['offers']}'),
                      if ((person['needs'] ?? '').toString().isNotEmpty) Text('Needs: ${person['needs']}'),
                      if (reasons.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(reasons.join(' • '),
                              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}