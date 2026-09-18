import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
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
  final dio = Dio(
    BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'),
  );
  final text = TextEditingController();
  int rating = 5;
  bool saving = false;

  Future<void> save() async {
    if (rating <= 3 && text.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('reasonLowStars'))));
      return;
    }
    setState(() => saving = true);
    try {
      await dio.post(
        '/auth/review',
        data: {
          'fromId': Session.id,
          'fromName': Session.name,
          'toId': widget.otherId,
          'rating': rating,
          'text': text.text,
          'skill': widget.skill,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 24;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.fill('reviewOf', {'name': widget.otherName})),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
        children: [
          const Icon(Icons.rate_review, size: 64, color: AppColors.gold),
          const SizedBox(height: 8),
          Text(
            widget.skill,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => setState(() => rating = value),
                icon: Icon(
                  value <= rating ? Icons.star : Icons.star_border,
                  color: AppColors.gold,
                  size: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: text,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: S.t('yourReview'),
              hintText: S.t('requiredIf3'),
              prefixIcon: const Icon(Icons.edit, size: 28),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: saving ? null : save,
              style: AppTheme.solid(AppColors.green),
              icon: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 28,
              ),
              label: Text(
                saving ? S.t('saving') : S.t('saveReview'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
