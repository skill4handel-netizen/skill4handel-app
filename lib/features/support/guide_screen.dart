import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  Widget section(IconData icon, Color color, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(height: 1.35)),
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
      appBar: AppBar(title: Text(S.t('guide'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(S.t('guideTitle'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(S.t('guideIntro'), style: TextStyle(color: AppColors.muted, height: 1.35)),
          const SizedBox(height: 18),
          section(Icons.handshake, AppColors.blue, S.t('guideWhatTitle'), S.t('guideWhatBody')),
          section(Icons.person, AppColors.purple, S.t('guideProfileTitle'), S.t('guideProfileBody')),
          section(Icons.search, AppColors.green, S.t('guideSearchTitle'), S.t('guideSearchBody')),
          section(Icons.chat_bubble, AppColors.blue, S.t('guideChatTitle'), S.t('guideChatBody')),
          section(Icons.swap_horiz, AppColors.coral, S.t('guideOfferTitle'), S.t('guideOfferBody')),
          section(Icons.reply, const Color(0xFFB45309), S.t('guideCounterTitle'), S.t('guideCounterBody')),
          section(Icons.event_available, AppColors.green, S.t('guideDoneTitle'), S.t('guideDoneBody')),
          section(Icons.account_balance_wallet, const Color(0xFF0F766E), S.t('guideWalletTitle'), S.t('guideWalletBody')),
          section(Icons.star, const Color(0xFFCA8A04), S.t('guideReviewTitle'), S.t('guideReviewBody')),
          section(Icons.notifications, AppColors.coral, S.t('guideNotifyTitle'), S.t('guideNotifyBody')),
          section(Icons.gavel, const Color(0xFF1F4E79), S.t('guideRulesTitle'), S.t('guideRulesBody')),
          section(Icons.support_agent, AppColors.purple, S.t('guideSupportTitle'), S.t('guideSupportBody')),
        ],
      ),
    );
  }
}
