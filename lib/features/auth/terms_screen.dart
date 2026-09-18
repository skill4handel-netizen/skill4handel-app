import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Widget item(String emoji, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t('terms'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '📜',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          Text(
            S.t('termsTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            S.t('termsSource'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          item('🤝', S.t('termWhatTitle'), S.t('termWhatBody')),
          item('🔁', S.t('termReciprocityTitle'), S.t('termReciprocityBody')),
          item('🪙', S.t('termTokensTitle'), S.t('termTokensBody')),
          item('🎂', S.t('termAgeTitle'), S.t('termAgeBody')),
          item('👀', S.t('termMeetTitle'), S.t('termMeetBody')),
          item('🚫', S.t('termBanTitle'), S.t('termBanBody')),
          item('⚖️', S.t('termRespTitle'), S.t('termRespBody')),
          item('⏰', S.t('termCancelTitle'), S.t('termCancelBody')),
          item('✉️', S.t('termReportTitle'), S.t('termReportBody')),
        ],
      ),
    );
  }
}
