import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> openUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void openPrivacy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Privacy and safety', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 12),
                Text('Skill4Handel is a platform for exchanging skills and practical help without payment between members.'),
                SizedBox(height: 12),
                Text('Review a profile before you arrange to meet.'),
                SizedBox(height: 8),
                Text('Meet in public where appropriate.'),
                SizedBox(height: 8),
                Text('Tokens are not currency and not cryptocurrency. They are used when a direct skill swap is not possible.'),
                SizedBox(height: 8),
                Text('If something is wrong, write to info@skill4handel.com.'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget logo() {
    return Image.asset(
      'assets/logo.jpg',
      height: 176,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Image.asset(
        'assets/logo.jpeg',
        height: 176,
        fit: BoxFit.contain,
        errorBuilder: (context, error2, stack2) {
          return const Icon(Icons.handshake, size: 96, color: AppColors.blue);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          child: Column(
            children: [
              const Spacer(),
              logo(),
              const SizedBox(height: 24),
              const Text(
                'Share what you know.\nGet what you need.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25),
              ),
              const SizedBox(height: 8),
              const Text(
                'Skill sharing without money.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => openUrl('https://www.skill4handel.com'),
                child: const Text('www.skill4handel.com'),
              ),
              TextButton(
                onPressed: () => openPrivacy(context),
                child: const Text('Privacy and safety'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
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
                width: double.infinity,
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
      ),
    );
  }
}