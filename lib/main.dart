import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/main_shell.dart';
import 'core/constants/push_service.dart';
import 'core/constants/session.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/verify_email_screen.dart';
import 'features/home/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  } catch (_) {}
  await Session.load();
  await PushService.init();
  String? verifyToken;
  try {
    final initial = await AppLinks().getInitialLink();
    if (initial != null &&
        (initial.host == 'verify' || initial.path.contains('verify'))) {
      verifyToken = initial.queryParameters['token'];
    }
  } catch (_) {}
  runApp(SkillApp(verifyToken: verifyToken));
}

class SkillApp extends StatefulWidget {
  const SkillApp({super.key, this.verifyToken});

  final String? verifyToken;

  @override
  State<SkillApp> createState() => _SkillAppState();
}

class _SkillAppState extends State<SkillApp> {
  String? verifyToken;
  Widget? lockedHome;

  Widget startHome() {
    if (lockedHome != null) return lockedHome!;
    final startVerify = (verifyToken ?? '').isNotEmpty;
    if (startVerify) return LoginScreen(verifyToken: verifyToken);
    if (Session.id > 0 && Session.emailVerified) return MainShell(userName: Session.name);
    if (Session.id > 0 && !Session.emailVerified) return const VerifyEmailScreen();
    return const WelcomeScreen();
  }

  @override
  void initState() {
    super.initState();
    verifyToken = widget.verifyToken;
    try {
      AppLinks().uriLinkStream.listen((uri) {
        if (uri.host == 'verify' || uri.path.contains('verify')) {
          final token = uri.queryParameters['token'];
          if (token != null && token.isNotEmpty && mounted) {
            setState(() => verifyToken = token);
          }
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Session.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Skill4Handel',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: lockedHome ??= startHome(),
        );
      },
    );
  }
}
