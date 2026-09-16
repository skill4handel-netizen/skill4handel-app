import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../app/main_shell.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPass = false;
  bool loading = false;

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill email and password')));
      return;
    }
    setState(() => loading = true);
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email.text.trim(),
        'password': password.text,
      });
      Session.apply(Map<String, dynamic>.from(response.data['user'] as Map));
      if (response.data['token'] != null) Session.token = response.data['token'].toString();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainShell(userName: Session.name)),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email or password is wrong')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> forgotPassword() async {
    final newPass = TextEditingController();
    final confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Email: ${email.text.trim().isEmpty ? 'enter it on the login form first' : email.text.trim()}'),
            const SizedBox(height: 12),
            TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'New password')),
            const SizedBox(height: 8),
            TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true) return;
    if (email.text.trim().isEmpty || newPass.text.isEmpty || newPass.text != confirm.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email and matching new password are required')));
      return;
    }
    try {
      await dio.post('/auth/forgot-password', data: {'email': email.text.trim(), 'password': newPass.text});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Log in with the new password.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not reset password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 24;
    return AppScaffold(
      title: 'Log in',
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottom),
        children: [
          Center(
            child: Image.asset(
              'assets/logo.jpg',
              height: 150,
              errorBuilder: (context, error, stack) => Image.asset(
                'assets/logo.jpeg',
                height: 150,
                errorBuilder: (context, error2, stack2) => const Icon(Icons.handshake, size: 96, color: AppColors.blue),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Icon(Icons.lock_open_rounded, size: 40, color: AppColors.green),
          const SizedBox(height: 20),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email, size: 28)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: !showPass,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.key, size: 28),
              suffixIcon: IconButton(
                onPressed: () => setState(() => showPass = !showPass),
                icon: Icon(showPass ? Icons.visibility_off : Icons.visibility, size: 28),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(onPressed: forgotPassword, icon: const Icon(Icons.help_outline), label: const Text('Forgot password')),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: loading ? null : login,
              style: AppTheme.solid(AppColors.green),
              icon: const Icon(Icons.login, color: Colors.white, size: 28),
              label: Text(loading ? 'Signing in...' : 'Log in', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
              icon: const Icon(Icons.person_add_alt_1, size: 28),
              label: const Text('Create account'),
            ),
          ),
        ],
      ),
    );
  }
}
