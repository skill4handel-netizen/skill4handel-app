import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> openSite() async {
    await launchUrl(
      Uri.parse('https://www.skill4handel.com'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              Image.asset(
                'assets/logo.jpg',
                height: 88,
                errorBuilder: (context, error, stack) => Image.asset(
                  'assets/logo.jpeg',
                  height: 88,
                  errorBuilder: (context, error2, stack2) {
                    return const Icon(Icons.handshake, size: 72, color: AppColors.blue);
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Skill4Handel',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const Text(
                'Share what you know. Get what you need.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.blue),
              ),
              const Text(
                'Skill sharing without money.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Step(icon: Icons.person_outline, label: 'Profile'),
                  _Step(icon: Icons.search, label: 'Match'),
                  _Step(icon: Icons.handshake_outlined, label: 'Exchange'),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: const [
                  Chip(avatar: Icon(Icons.chat_bubble_outline, size: 16), label: Text('Languages')),
                  Chip(avatar: Icon(Icons.laptop_mac, size: 16), label: Text('Digital')),
                  Chip(avatar: Icon(Icons.menu_book_outlined, size: 16), label: Text('Learning')),
                  Chip(avatar: Icon(Icons.palette_outlined, size: 16), label: Text('Creative')),
                  Chip(avatar: Icon(Icons.build_outlined, size: 16), label: Text('Practical')),
                  Chip(avatar: Icon(Icons.map_outlined, size: 16), label: Text('Local')),
                ],
              ),
              const Spacer(),
              TextButton(onPressed: openSite, child: const Text('skill4handel.com')),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                  },
                  style: AppTheme.solid(AppColors.green),
                  child: const Text('Create account', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  child: const Text('Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.soft,
          child: Icon(icon, color: AppColors.blue),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}