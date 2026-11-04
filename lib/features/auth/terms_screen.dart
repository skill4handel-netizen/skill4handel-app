import 'package:flutter/material.dart';
import '../../core/l10n/app_strings.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  Widget item(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2F6FED)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
      appBar: AppBar(title: const Text('Terms, rules and privacy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Skill4Handel terms, exchange rules and privacy notice',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'This notice explains how the service works and how personal data is handled under the EU GDPR.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          item(Icons.handshake_outlined, 'What Skill4Handel is',
              'Skill4Handel is a platform for exchanging skills between adults. Members offer skills they can teach and request skills they need. The service does not employ members and does not provide the exchanged service itself.'),
          item(Icons.swap_horiz, 'Exchange rules',
              'The first member selects the skill they need from the other member’s list. The other member may accept, decline, or send one counter-offer. A counter-offer may be a skill, skill plus tokens, tokens only, or voluntary help. A second counter-offer is not allowed. The earliest session time is 24 hours from the request. If there is no response within 24 hours, the offer is cancelled automatically for both members and cannot be edited.'),
          item(Icons.volunteer_activism, 'Tokens and voluntary help',
              'Tokens may be used instead of, or in addition to, a return skill. A one-hour exchange has a maximum of 10 tokens. Voluntary help does not require a return skill or tokens. A volunteer badge may be shown on a profile.'),
          item(Icons.event_available, 'Completion and reviews',
              'Both members confirm completion. Tokens move only after both confirmations when the offer uses tokens. Reviews and stars are available only after both members have confirmed completion. A review of 3 stars or fewer requires a written reason. A review may be reported by the two members within 24 hours.'),
          item(Icons.cake_outlined, 'Age',
              'The service is only for people aged 18 or older. Date of birth is collected to confirm this.'),
          item(Icons.place_outlined, 'Meetings',
              'Sessions may be online or in person. In-person meetings should use a public place. Members are responsible for their own safety.'),
          item(Icons.block, 'Prohibited activity',
              'Illegal activity, fraud, sexual services, weapons, drugs, and any activity that harms another person are not allowed. Accounts may be suspended.'),
          item(Icons.gavel, 'Responsibility',
              'Members are responsible for the quality of their work and the fairness of the exchange. Skill4Handel may review reports and arbitration tickets, but it is not a party to the exchange.'),
          item(Icons.timer_outlined, 'Cancellation',
              'The requester may cancel an unanswered offer before the scheduled time. If the other member deletes the chat before answering, the offer is cancelled and both members receive a notice. After cancellation or expiry, both members may start a new request.'),
          item(Icons.flag_outlined, 'Reports and support',
              'Members may report a profile, a review, or an exchange, and may open a support or arbitration ticket. Blocking hides the member from matches and chat.'),
          const SizedBox(height: 8),
          const Text('Privacy notice (GDPR)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          item(Icons.person_outline, 'Data controller',
              'Skill4Handel, contact: info@skill4handel.com. For privacy requests, use the same address or a support ticket.'),
          item(Icons.folder_outlined, 'Data we collect',
              'Account data: name, email, password hash, date of birth, age, city, phone if provided, language, profile photo, skills, bio, accessibility preference, volunteer preference, and terms acceptance time. Activity data: chats, offers, wallet entries, reviews, reports, tickets, and in-app alerts. Technical data: device push token and basic logs needed to run the service.'),
          item(Icons.task_alt, 'Why we use it',
              'To create and secure the account, verify age, show profiles and matches, run exchanges, calculate tokens, send service messages, handle reports, and keep the service safe. Legal bases are contract, legitimate interest in safety, and consent where a choice is optional, such as phone, photo, accessibility, and volunteer status.'),
          item(Icons.share_outlined, 'Sharing',
              'Profile information needed for an exchange is visible to other members. We do not sell personal data. Processors may include hosting, database, email, and push notification providers. Data may be processed outside the EU only with an appropriate safeguard.'),
          item(Icons.schedule, 'Retention',
              'Account data is kept while the account is active. Exchange, review, and ticket records may be kept for safety and dispute handling. Deleted chats remain as a short activity log for both members. You may request deletion of the account.'),
          item(Icons.verified_user_outlined, 'Your rights',
              'You may request access, correction, deletion, restriction, or a copy of your data, and you may object to processing based on legitimate interest. You may withdraw optional consent at any time. You may lodge a complaint with your local data protection authority.'),
          item(Icons.lock_outline, 'Security',
              'Passwords are stored as hashes. Access tokens are kept in secure device storage. You are responsible for keeping your login details private.'),
          const SizedBox(height: 8),
          Text(
            S.t('termsSource'),
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
