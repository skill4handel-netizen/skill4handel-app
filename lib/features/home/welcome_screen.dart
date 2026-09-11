import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> openSite() async {
    final url = Uri.parse('https://www.skill4handel.com');
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          children: [
            Center(
              child: Image.asset(
                'assets/logo.jpg',
                height: 96,
                errorBuilder: (context, error, stack) {
                  return Image.asset(
                    'assets/logo.jpeg',
                    height: 96,
                    errorBuilder: (context, error2, stack2) {
                      return const Icon(Icons.handshake, size: 72, color: AppColors.blue);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Skill4Handel',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share what you know.\nGet what you need.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.blue),
            ),
            const SizedBox(height: 8),
            const Text(
              'Skill sharing without money.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Skill4Handel connects people who can help each other with skills, knowledge and practical help. No cash between you.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _card(
              title: 'How it works',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Create your profile — what you can offer and what you need.'),
                  SizedBox(height: 8),
                  Text('2. Find a match — people whose skills complement yours.'),
                  SizedBox(height: 8),
                  Text('3. Swap and review — meet online or in person, then leave a short note.'),
                ],
              ),
            ),
            _card(
              title: 'The simple loop',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Give a skill you know.'),
                  Text('Connect with someone nearby who needs it.'),
                  Text('Get a skill, help, volunteer time, or S4H tokens when a direct swap is not possible.'),
                  Text('Repeat and help more people in your city.'),
                ],
              ),
            ),
            _card(
              title: 'What you can exchange',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Languages and conversation'),
                  Text('• Digital help: laptop, phone, documents'),
                  Text('• Learning and study help'),
                  Text('• Creative skills and feedback'),
                  Text('• Practical help and small repairs'),
                  Text('• Volunteer help for the community'),
                ],
              ),
            ),
            _card(
              title: 'Volunteer help',
              child: const Text(
                'Not every exchange has to be one-for-one. You can offer volunteer time: garden help, language practice, digital support, or a hand to a neighbour. Mark it as volunteer when you send an offer.',
              ),
            ),
            TextButton(
              onPressed: openSite,
              child: const Text('Open skill4handel.com'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                },
                style: AppTheme.solid(AppColors.green),
                child: const Text('Create account', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                },
                child: const Text('Log in'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _card({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}