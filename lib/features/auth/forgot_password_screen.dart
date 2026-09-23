import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final dio = Api.client;
  bool loading = false;
  String message = '';

  Future<void> submit() async {
    setState(() {
      loading = true;
      message = '';
    });
    try {
      await dio.post(
        '/auth/forgot-password',
        data: {'email': emailController.text.trim().toLowerCase()},
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      loading = false;
      message =
          'If this email has an account, a reset link has been sent. Open that email and choose a new password.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t('forgotPassword'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.t('resetPassword'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the email address of your account. A one-time link will be sent. The link expires after two hours.',
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: S.t('email'),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(message),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(loading ? S.t('pleaseWait') : 'Send link'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
