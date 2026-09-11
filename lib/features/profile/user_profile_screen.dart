import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../chat/chat_screen.dart';

class UserProfileScreen extends StatelessWidget {
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
  });

  final String name;
  final String email;
  final String city;
  final String offers;
  final String needs;
  final int otherId;
  final double rating;
  final List<Map<String, dynamic>> reviews;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber),
              const SizedBox(width: 6),
              Text(rating.toStringAsFixed(1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(email, style: const TextStyle(color: AppColors.muted)),
          if (city.isNotEmpty) Text(city),
          const SizedBox(height: 16),
          const Text('Offers', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(offers.isEmpty ? '-' : offers),
          const SizedBox(height: 12),
          const Text('Needs', style: TextStyle(fontWeight: FontWeight.w700)),
          Text(needs.isEmpty ? '-' : needs),
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
                      otherId: otherId,
                    ),
                  ),
                );
              },
              style: AppTheme.solid(AppColors.green),
              child: const Text('Connect', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (reviews.isEmpty)
            const Text('No reviews yet.', style: TextStyle(color: AppColors.muted))
          else
            ...reviews.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('${item['fromName'] ?? 'User'}: ${item['text'] ?? ''} (${item['rating'] ?? ''})'),
                )),
        ],
      ),
    );
  }
}