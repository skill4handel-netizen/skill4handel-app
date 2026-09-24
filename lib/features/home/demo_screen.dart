import 'package:flutter/material.dart';
import '../../app/main_shell.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_strings.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key, this.userName});

  final String? userName;

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  int page = 0;

  List<_Slide> get slides => [
    _Slide(
      image:
          'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=1400&q=80',
      title: S.t('demoTitle1'),
      text: S.t('demoText1'),
    ),
    _Slide(
      image:
          'https://images.unsplash.com/photo-1521737711867-e3b97375f902?auto=format&fit=crop&w=1400&q=80',
      title: S.t('demoTitle2'),
      text: S.t('demoText2'),
    ),
    _Slide(
      image:
          'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=1400&q=80',
      title: S.t('demoTitle3'),
      text: S.t('demoText3'),
    ),
    _Slide(
      image:
          'https://images.unsplash.com/photo-1529156069898-49953e654a00?auto=format&fit=crop&w=1400&q=80',
      title: S.t('demoTitle4'),
      text: S.t('demoText4'),
    ),
    _Slide(
      image:
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?auto=format&fit=crop&w=1400&q=80',
      title: S.t('demoTitle5'),
      text: S.t('demoText5'),
    ),
  ];

  Future<void> finish() async {
    await Session.markDemoSeen();
    if (!mounted) return;
    if (Session.token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MainShell(userName: widget.userName ?? Session.name),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = slides[page];
    final last = page == slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.image,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) =>
                Container(color: AppColors.blue),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x66000000),
                  Color(0x00000000),
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName == null || widget.userName!.isEmpty
                        ? 'Welcome'
                        : 'Welcome, ${widget.userName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    S.t('howItWorks'),
                    style: TextStyle(color: Colors.white70),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: List.generate(
                      slides.length,
                      (index) => Container(
                        width: index == page ? 18 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: index == page ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!last) {
                          setState(() => page++);
                        } else {
                          finish();
                        }
                      },
                      style: AppTheme.solid(AppColors.green),
                      child: Text(
                        last ? S.t('demoContinue') : S.t('demoNext'),
                        style: const TextStyle(color: Colors.white),
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
}

class _Slide {
  const _Slide({required this.image, required this.title, required this.text});
  final String image;
  final String title;
  final String text;
}
