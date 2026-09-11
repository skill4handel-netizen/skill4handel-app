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
      final response = await dio.get('/users');
      final users = (response.data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((item) => item['id'].toString() != Session.id.toString())
          .toList();
      setState(() {
        all = users;
        results = users;
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
            '${person['name']} ${person['email']} ${person['city']} ${person['offers']} ${person['needs']}'
                .toLowerCase();
        return q.isEmpty || blob.contains(q);
      }).toList();
    });
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
                        otherId: int.tryParse(person['id'].toString()) ?? 0,
                        rating: double.tryParse(person['rating'].toString()) ?? 0,
                        reviews: const [],
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
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if ((person['city'] ?? '').toString().isNotEmpty) Text(person['city'].toString()),
                      if ((person['offers'] ?? '').toString().isNotEmpty) Text('Offers: ${person['offers']}'),
                      if ((person['needs'] ?? '').toString().isNotEmpty) Text('Needs: ${person['needs']}'),
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