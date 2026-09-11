import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
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
  int unread = 0;

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
      var count = 0;
      try {
        final chatsRes = await dio.get('/chats', queryParameters: {'userId': Session.id});
        final chats = ((chatsRes.data as List?) ?? []).map((item) => Map<String, dynamic>.from(item as Map));
        count = chats.where((chat) {
          final pending = chat['pendingSwap'] is Map && chat['pendingSwap']['status'] == 'pending';
          return pending && chat['pendingSwap']['proposedBy'].toString() != Session.id.toString();
        }).length;
      } catch (_) {}
      setState(() {
        people = users;
        unread = count;
      });
    } catch (e) {
      setState(() => people = []);
    }
  }

  void openProfile(Map<String, dynamic> person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          name: person['name']?.toString() ?? 'User',
          email: person['email']?.toString() ?? '',
          city: person['city']?.toString() ?? '',
          offers: person['offers']?.toString() ?? '',
          needs: person['needs']?.toString() ?? '',
          otherId: int.tryParse('${person['id'] ?? 0}') ?? 0,
          rating: double.tryParse('${person['rating'] ?? 0}') ?? 0,
          reviews: ((person['reviews'] as List?) ?? [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
          photoUrl: person['photoUrl']?.toString(),
        ),
      ),
    );
  }

  Widget photo(String name, String url, {double radius = 24}) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.blue,
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            )
          : null,
    );
  }

  Widget chip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offers = Session.offers.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty);
    final needs = Session.needs.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty);
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.blue,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Session.name.isNotEmpty ? Session.name : 'Skill4Handel',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                ),
                Text(
                  MaterialLocalizations.of(context).formatFullDate(DateTime.now()),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  photo(Session.name, Session.photoUrl, radius: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(Session.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(Session.email, style: const TextStyle(color: AppColors.muted)),
                        if (Session.city.isNotEmpty) Text(Session.city),
                      ],
                    ),
                  ),
                  IconButton(onPressed: widget.onSearchTap, icon: const Icon(Icons.search)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _stat(Icons.star, Session.rating.toStringAsFixed(1), 'Rating'),
                    _stat(Icons.account_balance_wallet_outlined, '${Session.balance}', 'S4H'),
                    _stat(Icons.chat_bubble_outline, '$unread', 'Unread'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text('Skills', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Teaching'),
              const SizedBox(height: 6),
              Wrap(children: [for (final item in offers) chip(item, AppColors.green)]),
              const Text('Learning'),
              const SizedBox(height: 6),
              Wrap(children: [for (final item in needs) chip(item, AppColors.blue)]),
              const SizedBox(height: 12),
              const Text('Matches', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (people.isEmpty)
                const Text('No matches yet.', style: TextStyle(color: AppColors.muted))
              else
                ...people.map((person) {
                  final name = person['name']?.toString() ?? 'User';
                  final photoUrl = person['photoUrl']?.toString() ?? '';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: GestureDetector(onTap: () => openProfile(person), child: photo(name, photoUrl)),
                    title: GestureDetector(
                      onTap: () => openProfile(person),
                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    subtitle: Text(person['city']?.toString() ?? ''),
                    trailing: Text(
                      '${person['score'] ?? 0}%',
                      style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w800),
                    ),
                    onTap: () => openProfile(person),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.blue),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}