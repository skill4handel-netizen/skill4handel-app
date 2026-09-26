import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/constants/favorites.dart';
import '../../core/constants/session.dart';
import '../../core/constants/skill_items.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/skill_labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/user_photo.dart';
import '../chat/chat_screen.dart';
import '../support/support_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.city,
    required this.offers,
    required this.needs,
    required this.otherId,
    this.rating = 0,
    this.reviews = const [],
    this.photoUrl,
    this.accessibility = false,
  });

  final String name;
  final String email;
  final String city;
  final String offers;
  final String needs;
  final int otherId;
  final double rating;
  final List<Map<String, dynamic>> reviews;
  final String? photoUrl;
  final bool accessibility;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final dio = Api.client;
  late String name = widget.name;
  late String email = widget.email;
  late String city = widget.city;
  late String offers = widget.offers;
  late String needs = widget.needs;
  late String photo = widget.photoUrl?.trim() ?? '';
  late double rating = widget.rating;
  late bool accessibility = widget.accessibility;
  late List<Map<String, dynamic>> reviews = List<Map<String, dynamic>>.from(
    widget.reviews,
  );
  bool liked = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadLike();
  }

  Future<void> loadLike() async {
    liked = await Favorites.has(widget.otherId);
    if (mounted) setState(() {});
  }

  Future<void> toggleLike() async {
    liked = await Favorites.toggle(widget.otherId);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(liked ? S.t('addedFav') : S.t('removedFav'))),
    );
  }

  Future<void> loadProfile() async {
    if (widget.otherId == 0) return;
    try {
      final response = await dio.get('/users/${widget.otherId}');
      final user = response.data is Map
          ? (response.data['user'] ?? response.data)
          : null;
      if (user is! Map) return;
      setState(() {
        name = user['name']?.toString() ?? name;
        email = user['email']?.toString() ?? email;
        city = user['city']?.toString() ?? city;
        offers = user['offers']?.toString() ?? offers;
        needs = user['needs']?.toString() ?? needs;
        photo = (user['photoUrl'] ?? user['photo_url'] ?? photo).toString();
        rating = double.tryParse('${user['rating'] ?? rating}') ?? rating;
        accessibility =
            user['accessibility'] == true || user['accessibility'] == 'true';
        if (user['reviews'] is List) {
          reviews = (user['reviews'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      });
    } catch (_) {}
  }

  Future<void> reportUser() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SupportScreen(initialType: 'report', initialOtherName: name),
      ),
    );
  }

  Future<void> blockUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.t('blockTitle')),
        content: Text(S.t('blockBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.t('block')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.post(
        '/auth/block',
        data: {'userId': Session.id, 'otherId': widget.otherId},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('blockedOk'))));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('requestFailed'))));
    }
  }

  void showSkill(SkillItem skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skillLabel(skill.name)),
        content: Text(skill.note.isEmpty ? S.t('noDescription') : skill.note),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.t('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skills = parseSkills(offers);
    final featured = skills.isEmpty ? null : skills.first;
    final bottom = MediaQuery.of(context).padding.bottom + 24;
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
        actions: [
          IconButton(
            onPressed: toggleLike,
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
        children: [
          Center(
            child: UserPhoto(
              url: photo,
              radius: 48,
              letter: name.isNotEmpty ? name[0] : '?',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          if (accessibility) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.accessible, color: AppColors.blue),
                const SizedBox(width: 6),
                Text(
                  S.t('accessMark'),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 6),
              Text(rating.toStringAsFixed(1)),
            ],
          ),
          if (city.isNotEmpty)
            Text(
              city,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          const SizedBox(height: 16),
          Text(
            S.t('skillsOffered'),
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (featured == null)
            Text(
              S.t('noSkillsListed'),
              style: TextStyle(color: AppColors.muted),
            )
          else ...[
            Text(
              featured.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if (featured.note.isNotEmpty) Text(featured.note),
            const SizedBox(height: 8),
            Wrap(
              children: [
                for (final skill in skills)
                  GestureDetector(
                    onTap: () => showSkill(skill),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8, bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEE8FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.purple),
                      ),
                      child: Text(
                        skill.name,
                        style: const TextStyle(
                          color: Color(0xFF3D2BB3),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      name: name,
                      otherId: widget.otherId,
                      photoUrl: photo,
                    ),
                  ),
                );
              },
              style: AppTheme.solid(AppColors.green),
              child: Text(
                S.t('connect'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.t('connectHint'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reportUser,
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(S.t('report')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: blockUser,
                  icon: const Icon(Icons.block),
                  label: Text(S.t('block')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            S.t('reviews'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (reviews.isEmpty)
            Text(S.t('noReviewsYet'), style: TextStyle(color: AppColors.muted))
          else
            ...reviews.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '${item['fromName'] ?? 'Member'}: ${item['text'] ?? ''} (${item['rating'] ?? ''})',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
