import 'dart:async';
import 'package:flutter/material.dart';
import '../../app/main_shell.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.verifyUrl = ''});

  final String verifyUrl;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final dio = Api.client;
  bool sending = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) => checkVerified());
    checkVerified();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkVerified() async {
    if (Session.email.isEmpty) return;
    try {
      final status = await dio.post('/auth/verification-status', data: {'email': Session.email});
      final verified = status.data is Map && status.data['verified'] == true;
      if (!verified || !mounted) return;
      if (Session.token.isEmpty) return;
      final response = await dio.get('/auth/me');
      final data = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : <String, dynamic>{};
      final user = data['user'] is Map ? Map<String, dynamic>.from(data['user'] as Map) : data;
      Session.apply(user);
      Session.emailVerified = true;
      await Session.save();
      timer?.cancel();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainShell(userName: Session.name)),
        (route) => false,
      );
    } catch (_) {}
  }

  Future<void> resend() async {
    setState(() => sending = true);
    try {
      await dio.post('/auth/resend-verify', data: {'email': Session.email});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('verifySent'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('verifySent'))));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('verifyTitle')),
        automaticallyImplyLeading: false,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.headerGradient)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        children: [
          const Icon(Icons.mark_email_unread_outlined, size: 72, color: AppColors.blue),
          const SizedBox(height: 16),
          Text(S.t('verifyBody'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.4)),
          if (Session.email.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(Session.email, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          const SizedBox(height: 16),
          const Text(
            'Open the confirmation link on any device. This screen signs you in automatically after confirmation. The link works once.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: sending ? null : resend,
              style: AppTheme.solid(AppColors.green),
              child: Text(sending ? S.t('saving') : S.t('verifyResend'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}
