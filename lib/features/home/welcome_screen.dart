import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import 'demo_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
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
              children: [
                Text(
                  S.t('privacySafety'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(S.t('privacyIntro')),
                const SizedBox(height: 12),
                Text(S.t('reviewBeforeMeet')),
                const SizedBox(height: 8),
                Text(S.t('meetInPublic')),
                const SizedBox(height: 8),
                Text(S.t('tokensNotCurrency')),
                const SizedBox(height: 8),
                Text(S.t('writeIfWrong')),
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
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: circle(180, Colors.white.withValues(alpha: 0.12)),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: circle(160, AppColors.gold.withValues(alpha: 0.22)),
          ),
          Positioned(
            top: 90,
            left: 20,
            child: circle(70, AppColors.green.withValues(alpha: 0.25)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: DropdownButton<String>(
                      value: Session.language == 'nl' ? 'nl' : 'en',
                      dropdownColor: Colors.white,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text(S.t('english')),
                        ),
                        DropdownMenuItem(
                          value: 'nl',
                          child: Text(S.t('dutch')),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => Session.language = value ?? 'en');
                        Session.save();
                      },
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                    decoration: AppTheme.card(),
                    child: Column(
                      children: [
                        logo(),
                        const SizedBox(height: 18),
                        Text(
                          S.t('welcomeSlogan'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          S.t('welcomeTag'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            openUrl('https://www.skill4handel.com'),
                        icon: const Icon(Icons.language, color: Colors.white),
                        label: Text(
                          S.t('website'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => openPrivacy(context),
                        icon: const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                        ),
                        label: Text(
                          S.t('privacy'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DemoScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text(
                        'How it works',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      style: AppTheme.solid(AppColors.green),
                      icon: const Icon(
                        Icons.person_add_alt_1,
                        color: Colors.white,
                      ),
                      label: Text(
                        S.t('createAccount'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      style: AppTheme.solid(Colors.white),
                      icon: const Icon(Icons.login, color: AppColors.blueDeep),
                      label: Text(
                        S.t('logIn'),
                        style: const TextStyle(
                          color: AppColors.blueDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
