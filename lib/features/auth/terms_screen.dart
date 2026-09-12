import 'package:flutter/material.dart';

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
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
      appBar: AppBar(title: const Text('Terms and rules')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('📜', textAlign: TextAlign.center, style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text(
            'Skill4Handel terms',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Taken from skill4handel.com and the community safety rules.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),
          item('🤝', 'What Skill4Handel is',
              'A platform for exchanging skills and practical help without payment between members. Share what you know. Get what you need. Skill sharing without money.'),
          item('🔁', 'Reciprocity',
              'You must offer a skill. The model is reciprocal. Everyday knowledge counts.'),
          item('🪙', 'Tokens',
              'Tokens are used when a direct swap is not possible. They are not currency and not cryptocurrency. Early Users receive one grant of 5 Tokens per email when access is activated.'),
          item('🎂', 'Age',
              'You must be 16 years of age or older to create an account.'),
          item('👀', 'Before a meeting',
              'Review a profile before you arrange to meet. Meet in public where appropriate.'),
          item('🚫', 'What is not allowed',
              'Sex work and sexual services, pornography, violent work, weapons, illegal drugs, theft, fraud, and any other illegal activity. Accounts that offer these will be removed.'),
          item('⚖️', 'Responsibility',
              'Skill4Handel is a matching platform. The quality, safety and result of each exchange are the responsibility of the two parties.'),
          item('⏰', 'Cancellation',
              'An accepted exchange may be cancelled until 24 hours before the agreed date and time. An unanswered offer is cancelled after 24 hours.'),
          item('✉️', 'Reports',
              'Use Report in Support. Write to info@skill4handel.com if something is wrong.'),
        ],
      ),
    );
  }
}