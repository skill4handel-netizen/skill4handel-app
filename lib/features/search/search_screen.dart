import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/user_photo.dart';
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

  bool isOnline(Map person) {
    if (person['online'] == true) return true;
    final raw = person['lastSeen'] ?? person['updatedAt'] ?? person['updated_at'];
    final time = DateTime.tryParse(raw?.toString() ?? '');
    return time != null && DateTime.now().difference(time).inMinutes < 15;
  }

  Future<void> loadUsers() async {
    try {
      final response = await dio.get('/users', queryParameters: {'userId': Session.id});
      final users = (response.data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((item) => item['id'].toString() != Session.id.toString())
          .toList();
      setState(() {
        all = users;
        results = users;
      });
    } catch (_) {
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
        final blob = '${person['name']} ${person['city']} ${person['offers']} ${person['needs']}'.toLowerCase();
        return q.isEmpty || blob.contains(q);
      }).toList();
    });
  }

  Widget avatar(String name, String photo, bool online) {
    return Stack(
      children: [
        UserPhoto(url: photo, radius: 24, letter: name.isNotEmpty ? name[0] : '?'),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: online ? AppColors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Search', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          onChanged: search,
          decoration: const InputDecoration(
            hintText: 'Name, city or skill',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (results.isEmpty)
          const Text('No users found.', style: TextStyle(color: AppColors.muted))
        else
          ...results.map((person) {
            final name = person['name']?.toString() ?? 'User';
            final photo = (person['photoUrl'] ?? person['photo_url'] ?? '').toString();
            final online = isOnline(person);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: avatar(name, photo, online),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text([
                online ? 'Online' : 'Offline',
                if ((person['city'] ?? '').toString().isNotEmpty) person['city'],
                if ((person['offers'] ?? '').toString().isNotEmpty) person['offers'],
              ].join(' • ')),
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
                      otherId: int.tryParse('${person['id'] ?? 0}') ?? 0,
                      rating: double.tryParse('${person['rating'] ?? 0}') ?? 0,
                      reviews: ((person['reviews'] as List?) ?? [])
                          .map((item) => Map<String, dynamic>.from(item as Map))
                          .toList(),
                      photoUrl: photo,
                    ),
                  ),
                );
              },
            );
          }),
      ],
    );
  }
}