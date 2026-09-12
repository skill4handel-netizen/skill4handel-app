import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bottom_nav.dart';
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

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  late String name = widget.name;
  late String email = widget.email;
  late String city = widget.city;
  late String offers = widget.offers;
  late String needs = widget.needs;
  late String photo = widget.photoUrl?.trim() ?? '';
  late double rating = widget.rating;
  late List<Map<String, dynamic>> reviews = List<Map<String, dynamic>>.from(widget.reviews);

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  List<String> chips(String value) {
    return value.split(RegExp(r'[,/]')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }

  Future<void> loadProfile() async {
    if (widget.otherId == 0) return;
    try {
      final response = await dio.get('/users/${widget.otherId}');
      final user = response.data is Map ? (response.data['user'] ?? response.data) : null;
      if (user is! Map) return;
      setState(() {
        name = user['name']?.toString() ?? name;
        email = user['email']?.toString() ?? email;
        city = user['city']?.toString() ?? city;
        offers = user['offers']?.toString() ?? offers;
        needs = user['needs']?.toString() ?? needs;
        photo = (user['photoUrl'] ?? user['photo_url'] ?? photo).toString();
        rating = double.tryParse('${user['rating'] ?? rating}') ?? rating;
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
        builder: (context) => SupportScreen(
          initialType: 'report',
          initialOtherName: name,
        ),
      ),
    );
  }

  Future<void> blockUser() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this member?'),
        content: const Text('This member will no longer appear in Search, Matches or Chat.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Block')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.post('/auth/block', data: {
        'userId': Session.id,
        'otherId': widget.otherId,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The member has been blocked and will no longer appear in matches or chat.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The member could not be blocked.')),
      );
    }
  }

  Widget pill(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7B61FF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF7B61FF), fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offerChips = chips(offers);
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: UserPhoto(url: photo, radius: 48, letter: name.isNotEmpty ? name[0] : '?')),
          const SizedBox(height: 16),
          Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 6),
              Text(rating.toStringAsFixed(1)),
            ],
          ),
          if (city.isNotEmpty) Text(city, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          const Text('Skills offered', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (offerChips.isEmpty)
            const Text('No skills have been listed.', style: TextStyle(color: AppColors.muted))
          else
            Wrap(children: [for (final skill in offerChips) pill(skill)]),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(name: name, otherId: widget.otherId, photoUrl: photo),
                  ),
                );
              },
              style: AppTheme.solid(AppColors.green),
              child: const Text('Connect', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: reportUser,
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: blockUser,
                  icon: const Icon(Icons.block),
                  label: const Text('Block'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (reviews.isEmpty)
            const Text('No reviews have been submitted.', style: TextStyle(color: AppColors.muted))
          else
            ...reviews.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('${item['fromName'] ?? 'Member'}: ${item['text'] ?? ''} (${item['rating'] ?? ''})'),
                )),
        ],
      ),
    );
  }
}