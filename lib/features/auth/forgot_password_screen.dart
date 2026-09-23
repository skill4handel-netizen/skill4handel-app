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
  final passwordController = TextEditingController();
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
        data: {
          'email': emailController.text.trim().toLowerCase(),
          'password': passwordController.text,
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        message = S.t('noAccountEmail');
        loading = false;
      });
    }
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
              Text(
                S.t('forgotHint'),
                style: const TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: S.t('email'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: S.t('newPassword'),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(message, style: const TextStyle(color: Colors.red)),
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
                  child: Text(
                    loading ? S.t('pleaseWait') : S.t('updatePassword'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
