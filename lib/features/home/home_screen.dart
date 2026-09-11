import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSearchTap});

  final VoidCallback? onSearchTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));

  @override
  void initState() {
    super.initState();
    refreshMe();
  }

  Future<void> refreshMe() async {
    try {
      final response = await dio.get('/auth/me', queryParameters: {'userId': Session.id});
      final user = response.data is Map ? (response.data['user'] ?? response.data) : null;
      if (user is Map) Session.apply(Map<String, dynamic>.from(user));
    } catch (_) {}
    if (mounted) setState(() {});
  }

  List<String> chips(String value) {
    return value.split(RegExp(r'[,/]')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
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
    final photo = Session.photoUrl.trim();
    final name = Session.name.isEmpty ? 'You' : Session.name;
    final reviews = Session.reviews;

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
                IconButton(onPressed: refreshMe, icon: const Icon(Icons.refresh, color: Colors.white)),
                IconButton(onPressed: widget.onSearchTap, icon: const Icon(Icons.search, color: Colors.white)),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refreshMe,
            child: ListView(
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
                            photo.isNotEmpty
                                ? Image.network(photo, fit: BoxFit.cover)
                                : Container(
                                    color: AppColors.soft,
                                    child: Center(
                                      child: Text(
                                        name[0].toUpperCase(),
                                        style: const TextStyle(fontSize: 72, color: AppColors.blue),
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
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                                ),
                                const Icon(Icons.star, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(Session.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                            if (Session.email.isNotEmpty)
                              Text(Session.email, style: const TextStyle(color: AppColors.muted)),
                            if (Session.city.isNotEmpty) Text(Session.city),
                            if (Session.age > 0) Text('${Session.age} years'),
                            const SizedBox(height: 12),
                            const Text('Teaches', style: TextStyle(fontWeight: FontWeight.w800)),
                            Wrap(children: [
                              for (final skill in chips(Session.offers)) pill(skill, const Color(0xFF7B61FF)),
                              if (chips(Session.offers).isEmpty)
                                const Text('Add skills in Profile', style: TextStyle(color: AppColors.muted)),
                            ]),
                            const SizedBox(height: 4),
                            const Text('Wants', style: TextStyle(fontWeight: FontWeight.w800)),
                            Wrap(children: [
                              for (final skill in chips(Session.needs)) pill(skill, AppColors.blue),
                              if (chips(Session.needs).isEmpty)
                                const Text('Add what you need in Profile', style: TextStyle(color: AppColors.muted)),
                            ]),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: stat(Session.rating.toStringAsFixed(1), 'Rating')),
                                Expanded(child: stat('${Session.balance}', 'S4H')),
                                Expanded(child: stat('${reviews.length}', 'Reviews')),
                              ],
                            ),
                            if (reviews.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('Latest review', style: TextStyle(fontWeight: FontWeight.w800)),
                              Text(
                                '${reviews.first['fromName'] ?? reviews.first['name'] ?? 'User'}: ${reviews.first['text'] ?? ''}',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.muted),
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                  ).then((_) => refreshMe());
                                },
                                style: AppTheme.solid(AppColors.blue),
                                icon: const Icon(Icons.edit, color: Colors.white),
                                label: const Text('Edit profile', style: TextStyle(color: Colors.white)),
                              ),
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
        ),
      ],
    );
  }

  Widget stat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
      ],
    );
  }
}