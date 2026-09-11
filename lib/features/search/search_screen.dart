import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  List<Map<String, dynamic>> all = [];
  List<Map<String, dynamic>> results = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      List users = [];
      try {
        final matches = await dio.get('/matches', queryParameters: {'userId': Session.id});
        users = matches.data as List;
      } catch (_) {
        final response = await dio.get('/users');
        users = response.data as List;
      }
      final mapped = users
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((item) => item['id'].toString() != Session.id.toString())
          .toList();
      setState(() {
        all = mapped;
        results = mapped;
      });
    } catch (e) {
      setState(() {
        all = [];
        results = [];
      });
    }
  }

  void search(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      results = all.where((person) {
        final blob =
            '${person['name']} ${person['city']} ${person['offers']} ${person['needs']}'
                .toLowerCase();
        return q.isEmpty || blob.contains(q);
      }).toList();
    });
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
          otherId: int.tryParse(person['id'].toString()) ?? 0,
          rating: double.tryParse('${person['rating'] ?? 0}') ?? 0,
          reviews: const [],
          photoUrl: person['photoUrl']?.toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.blue,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: const SafeArea(
            bottom: false,
            child: Text('Search', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              TextField(
                controller: controller,
                onChanged: search,
                decoration: const InputDecoration(
                  hintText: 'Search by name, city or skill',
                  prefixIcon: Icon(Icons.search),
                  border: UnderlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (results.isEmpty)
                const Text('No users found.', style: TextStyle(color: AppColors.muted))
              else
                ...results.map((person) {
                  final name = person['name']?.toString() ?? 'User';
                  final photo = person['photoUrl']?.toString() ?? '';
                  final skills = [
                    if ((person['offers'] ?? '').toString().isNotEmpty) person['offers'],
                    if ((person['needs'] ?? '').toString().isNotEmpty) person['needs'],
                  ].join(', ');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: GestureDetector(
                      onTap: () => openProfile(person),
                      child: CircleAvatar(
                        backgroundColor: AppColors.blue,
                        backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty
                            ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white))
                            : null,
                      ),
                    ),
                    title: GestureDetector(
                      onTap: () => openProfile(person),
                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    subtitle: Text(
                      [
                        if ((person['city'] ?? '').toString().isNotEmpty) person['city'],
                        if (skills.isNotEmpty) skills,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
}