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
  int index = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final usersRes = await dio.get('/matches', queryParameters: {'userId': Session.id});
      setState(() {
        people = (usersRes.data as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
        index = 0;
      });
    } catch (_) {
      setState(() => people = []);
    }
  }

  Map<String, dynamic>? get person =>
      people.isEmpty ? null : people[index.clamp(0, people.length - 1)];

  List<String> chips(dynamic value) {
    return value
        .toString()
        .split(RegExp(r'[,/]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void openProfile() {
    final item = person;
    if (item == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          name: item['name']?.toString() ?? 'User',
          email: item['email']?.toString() ?? '',
          city: item['city']?.toString() ?? '',
          offers: item['offers']?.toString() ?? '',
          needs: item['needs']?.toString() ?? '',
          otherId: int.tryParse('${item['id'] ?? 0}') ?? 0,
          rating: double.tryParse('${item['rating'] ?? 0}') ?? 0,
          reviews: ((item['reviews'] as List?) ?? [])
              .map((row) => Map<String, dynamic>.from(row as Map))
              .toList(),
          photoUrl: item['photoUrl']?.toString(),
        ),
      ),
    );
  }

  void invite() {
    final item = person;
    if (item == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          name: item['name']?.toString() ?? 'User',
          otherId: int.tryParse('${item['id'] ?? 0}') ?? 0,
          photoUrl: item['photoUrl']?.toString(),
        ),
      ),
    );
  }

  void nextCard() {
    if (people.isEmpty) return;
    setState(() => index = (index + 1) % people.length);
  }

  Widget pill(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = person;
    final photo = item?['photoUrl']?.toString() ?? '';
    final name = item?['name']?.toString() ?? 'User';
    final reviews = ((item?['reviews'] as List?) ?? []);
    final rating = double.tryParse('${item?['rating'] ?? 0}') ?? 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.blue,
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Expanded(
                  child: Text('Home', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                ),
                IconButton(onPressed: loadData, icon: const Icon(Icons.refresh, color: Colors.white)),
                IconButton(onPressed: widget.onSearchTap, icon: const Icon(Icons.search, color: Colors.white)),
              ],
            ),
          ),
        ),
        Expanded(
          child: item == null
              ? const Center(child: Text('No profiles yet.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                GestureDetector(
                                  onTap: openProfile,
                                  child: photo.isNotEmpty
                                      ? Image.network(photo, fit: BoxFit.cover)
                                      : Container(
                                          color: AppColors.soft,
                                          child: Center(
                                            child: Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                                              style: const TextStyle(fontSize: 72, color: AppColors.blue),
                                            ),
                                          ),
                                        ),
                                ),
                                const Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Chip(
                                    backgroundColor: Color(0xFF4CC84A),
                                    label: Text('Online', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      onPressed: nextCard,
                                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: openProfile,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                                      ),
                                      const Icon(Icons.star, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                if ((item['city'] ?? '').toString().isNotEmpty)
                                  Text(item['city'].toString(), style: const TextStyle(color: AppColors.muted)),
                                const SizedBox(height: 12),
                                const Text('Teaches', style: TextStyle(fontWeight: FontWeight.w800)),
                                Wrap(children: [for (final skill in chips(item['offers'])) pill(skill, const Color(0xFF7B61FF))]),
                                const Text('Wants', style: TextStyle(fontWeight: FontWeight.w800)),
                                Wrap(children: [for (final skill in chips(item['needs'])) pill(skill, AppColors.blue)]),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: stat('${item['score'] ?? 0}%', 'Match')),
                                    Expanded(child: stat('${reviews.length}', 'Reviews')),
                                    Expanded(child: stat((item['city'] ?? '-').toString(), 'City')),
                                  ],
                                ),
                                if (reviews.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${reviews.first['fromName'] ?? 'User'}: ${reviews.first['text'] ?? ''}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.muted),
                                    ),
                                  ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    _round(Icons.close, Colors.red, nextCard),
                                    const SizedBox(width: 12),
                                    _round(Icons.info_outline, AppColors.blue, openProfile),
                                    const SizedBox(width: 12),
                                    _round(Icons.favorite, AppColors.green, invite),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }

  Widget _round(IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: CircleAvatar(
          radius: 26,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
      ),
    );
  }
}