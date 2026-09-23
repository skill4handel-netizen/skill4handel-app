import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.verifyUrl = ''});

  final String verifyUrl;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final dio = Api.client;
  bool sending = false;

  Future<void> resend() async {
    setState(() => sending = true);
    try {
      await dio.post('/auth/resend-verify', data: {'email': Session.email});
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('verifySent'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('verifySent'))));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void goLogin() {
    Session.token = '';
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('verifyTitle')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          const Icon(
            Icons.mark_email_unread_outlined,
            size: 72,
            color: AppColors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            S.t('verifyBody'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
          if (Session.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                Session.email,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Open the message in your email inbox and tap the confirmation link there. The app cannot confirm the address for you.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: sending ? null : resend,
            child: Text(sending ? S.t('saving') : S.t('verifyResend')),
          ),
          TextButton(onPressed: goLogin, child: Text(S.t('login'))),
        ],
      ),
    );
  }
}
