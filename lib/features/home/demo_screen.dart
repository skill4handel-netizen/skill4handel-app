import 'package:flutter/material.dart';
import '../../app/main_shell.dart';
import '../../core/theme/app_theme.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key, this.userName});

  final String? userName;

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  int page = 0;
  final pages = const [
    (
      'Create your profile',
      'Write the skills you can give and the skills you need. Add a photo, city, age and gender.',
    ),
    (
      'Find a match',
      'Search by name, city or skill. Open a profile, read reviews, then connect and chat.',
    ),
    (
      'Agree and swap',
      'Send an offer with skill, optional tokens, date and time. You can cancel until 24 hours before.',
    ),
    (
      'Stay safe',
      'No cash between you. Quality is your responsibility. Sex work, violence and illegal jobs are banned.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final item = pages[page];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome${widget.userName == null ? '' : ', ${widget.userName}'}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('A short tour before you start.', style: TextStyle(color: AppColors.muted)),
              const Spacer(),
              Text(item.$1, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.blue)),
              const SizedBox(height: 12),
              Text(item.$2, style: const TextStyle(fontSize: 16)),
              const Spacer(),
              Row(
                children: List.generate(
                  pages.length,
                  (index) => Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: index == page ? AppColors.green : AppColors.line,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (page < pages.length - 1) {
                      setState(() => page++);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => MainShell(userName: widget.userName)),
                      );
                    }
                  },
                  style: AppTheme.solid(AppColors.green),
                  child: Text(page < pages.length - 1 ? 'Next' : 'Start', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}