import 'package:flutter/material.dart';
import 'app/main_shell.dart';
import 'core/constants/push_service.dart';
import 'core/constants/session.dart';
import 'core/theme/app_theme.dart';
import 'features/home/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Session.load();
  await PushService.init();
  runApp(const SkillApp());
}

class SkillApp extends StatelessWidget {
  const SkillApp({super.key});

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
          home: Session.id > 0
              ? MainShell(userName: Session.name)
              : const WelcomeScreen(),
        );
      },
    );
  }
}
