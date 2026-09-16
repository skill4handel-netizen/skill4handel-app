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
      height: 168,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Image.asset(
        'assets/logo.jpeg',
        height: 168,
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
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
          Positioned(top: -40, right: -30, child: circle(180, Colors.white.withValues(alpha: 0.12))),
          Positioned(bottom: 120, left: -50, child: circle(160, AppColors.gold.withValues(alpha: 0.22))),
          Positioned(top: 90, left: 20, child: circle(70, AppColors.green.withValues(alpha: 0.25))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    decoration: AppTheme.card(),
                    child: Column(
                      children: [
                        logo(),
                        const SizedBox(height: 18),
                        const Text(
                          'Share what you know.\nGet what you need.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25, color: AppColors.text),
                        ),
                        const SizedBox(height: 8),
                        const Text('Skill sharing without money.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => openUrl('https://www.skill4handel.com'),
                        icon: const Icon(Icons.language, color: Colors.white),
                        label: const Text('Website', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      TextButton.icon(
                        onPressed: () => openPrivacy(context),
                        icon: const Icon(Icons.verified_user_outlined, color: Colors.white),
                        label: const Text('Privacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                      },
                      style: AppTheme.solid(AppColors.green),
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                      label: const Text('Create account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      },
                      style: AppTheme.solid(Colors.white),
                      icon: const Icon(Icons.login, color: AppColors.blueDeep),
                      label: const Text('Log in', style: TextStyle(color: AppColors.blueDeep, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget circle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
