import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.otherId,
    required this.otherName,
    required this.skill,
  });

  final int otherId;
  final String otherName;
  final String skill;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  final text = TextEditingController();
  int rating = 5;
  bool saving = false;

  Future<void> save() async {
    if (rating <= 3 && text.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A reason is required for 3 stars or less')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await dio.post('/auth/review', data: {
        'fromId': Session.id,
        'fromName': Session.name,
        'toId': widget.otherId,
        'rating': rating,
        'text': text.text,
        'skill': widget.skill,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review ${widget.otherName}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(widget.skill, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => setState(() => rating = value),
                icon: Icon(
                  value <= rating ? Icons.star : Icons.star_border,
                  color: AppColors.gold,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: text,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Your review',
              hintText: 'Required if 3 stars or less',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: saving ? null : save,
              style: AppTheme.solid(AppColors.green),
              child: Text(saving ? 'Saving...' : 'Save review', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}