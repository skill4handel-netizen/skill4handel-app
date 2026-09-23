import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../app/main_shell.dart';
import '../home/demo_screen.dart';
import '../../core/constants/push_service.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.verifyToken});

  final String? verifyToken;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final dio = Dio(
    BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'),
  );
  final email = TextEditingController();
  final password = TextEditingController();
  bool showPass = false;
  bool loading = false;
  bool waitingVerify = false;
  String notice = '';

  @override
  void initState() {
    super.initState();
    if ((widget.verifyToken ?? '').isNotEmpty) {
      confirmToken(widget.verifyToken!);
    }
  }

  Widget logo() {
    return Image.asset(
      'assets/logo.jpg',
      height: 92,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Image.asset(
        'assets/logo.jpeg',
        height: 92,
        fit: BoxFit.contain,
        errorBuilder: (context, error2, stack2) {
          return const Icon(Icons.handshake, size: 72, color: AppColors.blue);
        },
      ),
    );
  }

  Future<void> confirmToken(String token) async {
    setState(() {
      loading = true;
      notice = S.t('verifyingEmail');
    });
    try {
      final response = await dio.post('/auth/verify', data: {'token': token});
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      if (data['user'] is Map) {
        Session.apply(Map<String, dynamic>.from(data['user'] as Map));
        if (data['token'] != null) Session.token = data['token'].toString();
        await Session.save();
        await PushService.registerToken();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => Session.demoSeen
                ? MainShell(userName: Session.name)
                : DemoScreen(userName: Session.name),
          ),
          (route) => false,
        );
        return;
      }
      setState(() => notice = S.t('emailVerifiedLogin'));
    } catch (_) {
      setState(() => notice = S.t('verifyFailed'));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> login() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('fillEmailPassword'))));
      return;
    }
    setState(() => loading = true);
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'email': email.text.trim(), 'password': password.text},
      );
      final user = Map<String, dynamic>.from(response.data['user'] as Map);
      final verified =
          user['emailVerified'] == true || user['emailVerified'] == 'true';
      if (!verified) {
        setState(() {
          waitingVerify = true;
          notice = S.t('verifyBeforeLogin');
        });
        return;
      }
      Session.apply(user);
      if (response.data['token'] != null)
        Session.token = response.data['token'].toString();
      await Session.save();
      await PushService.registerToken();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => Session.demoSeen
              ? MainShell(userName: Session.name)
              : DemoScreen(userName: Session.name),
        ),
        (route) => false,
      );
    } on DioException catch (error) {
      final raw = error.response?.data;
      final message = raw is Map ? raw['message']?.toString() ?? '' : '';
      if (message.toLowerCase().contains('not verified') ||
          message.toLowerCase().contains('email not')) {
        setState(() {
          waitingVerify = true;
          notice = S.t('verifyBeforeLogin');
        });
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.t('wrongEmailPassword'))));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('wrongEmailPassword'))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resend() async {
    if (email.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('fillEmailPassword'))));
      return;
    }
    try {
      await dio.post('/auth/resend-verify', data: {'email': email.text.trim()});
      if (!mounted) return;
      setState(() => notice = S.t('verifyMailSent'));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('verifyMailFailed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                      DropdownMenuItem(value: 'nl', child: Text(S.t('dutch'))),
                    ],
                    onChanged: (value) {
                      setState(() => Session.language = value ?? 'en');
                      Session.save();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: AppTheme.card(),
                  child: Column(
                    children: [
                      logo(),
                      const SizedBox(height: 12),
                      Text(
                        S.t('login'),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(labelText: S.t('email')),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: password,
                        obscureText: !showPass,
                        decoration: InputDecoration(
                          labelText: S.t('password'),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => showPass = !showPass),
                            icon: Icon(
                              showPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                      ),
                      if (notice.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.mint,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(notice),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (!waitingVerify)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: loading ? null : login,
                            style: AppTheme.solid(AppColors.blue),
                            child: Text(
                              loading ? S.t('pleaseWait') : S.t('login'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      if (waitingVerify)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: resend,
                            style: AppTheme.solid(AppColors.green),
                            child: Text(
                              S.t('resendVerification'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(S.t('forgotPassword')),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(S.t('createAccount')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
