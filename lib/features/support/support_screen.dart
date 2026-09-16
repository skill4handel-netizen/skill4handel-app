import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.initialType, this.initialOtherName});

  final String? initialType;
  final String? initialOtherName;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  final text = TextEditingController();
  late String type = widget.initialType ?? 'support';
  bool sending = false;

  String cleanError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      if (error.response?.statusCode != null) {
        return 'The ticket could not be submitted (${error.response?.statusCode}). Please try again.';
      }
    }
    return 'The ticket could not be submitted. Please try again.';
  }

  Future<void> sendTicket() async {
    if (text.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the details of your request.')),
      );
      return;
    }
    setState(() => sending = true);
    try {
      await dio.post('/auth/ticket', data: {
        'userId': Session.id,
        'name': Session.name,
        'type': type,
        'otherName': widget.initialOtherName ?? '',
        'text': text.text.trim(),
      });
      text.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your ticket has been submitted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> openLink(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
    );
  }

  Widget typeCard(String value, IconData icon, String title, String subtitle, Color color) {
    final selected = type == value;
    return InkWell(
      onTap: () => setState(() => type = value),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : const Color(0xFFE4E7EC)),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? color : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget contactCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: AppColors.blue, child: Icon(icon, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget faq(IconData icon, String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE4E7EC)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.soft,
            child: Icon(icon, color: AppColors.blue, size: 18),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(body, style: const TextStyle(color: AppColors.muted)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reported = widget.initialOtherName ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(type == 'report' ? 'Report' : 'Support'),
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          sectionTitle('Contact'),
          contactCard(Icons.email_outlined, 'Email', 'info@skill4handel.com', () => openLink('mailto:info@skill4handel.com')),
          const SizedBox(height: 8),
          contactCard(Icons.language, 'Website', 'www.skill4handel.com', () => openLink('https://www.skill4handel.com')),
          const SizedBox(height: 20),
          sectionTitle('New ticket'),
          if (reported.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(14)),
              child: Text('Member: $reported', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          typeCard('support', Icons.support_agent, 'Support', 'A general question or account issue', AppColors.blue),
          typeCard('arbitration', Icons.gavel, 'Arbitration', 'A dispute after an exchange', const Color(0xFFE3A008)),
          typeCard('report', Icons.flag_outlined, 'Report a member', 'Inappropriate or unsafe behaviour', const Color(0xFFD92D20)),
          typeCard('fraud', Icons.warning_amber_rounded, 'Fraud', 'Suspicion of misuse or deception', const Color(0xFFB42318)),
          const SizedBox(height: 8),
          TextField(
            controller: text,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Details',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: sending ? null : sendTicket,
              style: AppTheme.solid(AppColors.green),
              icon: const Icon(Icons.send, color: Colors.white),
              label: Text(sending ? 'Submitting…' : 'Submit ticket', style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          sectionTitle('Frequently asked questions'),
          faq(Icons.info_outline, 'What is Skill4Handel?',
              'Skill4Handel is a platform for exchanging skills and practical assistance without cash payment between members.'),
          faq(Icons.payments_outlined, 'Is the service free of charge?',
              'Registration is free of charge. Core skill exchanges do not require cash. S4H tokens may be used when a direct exchange is not possible.'),
          faq(Icons.swap_horiz, 'How does an exchange work?',
              'Members record the skills they can provide, send an offer, agree on the terms, complete the session, and submit a review.'),
          faq(Icons.videocam_outlined, 'May exchanges take place online?',
              'Yes. Members may select an online or in-person meeting when submitting an offer.'),
          faq(Icons.badge_outlined, 'Who may use the application?',
              'The service is available to users aged 18 and over. Members are advised to review profiles and meet in a safe location.'),
          faq(Icons.block, 'What activity is prohibited?',
              'Sexual services, pornography, violence, weapons, illegal drugs, fraud, theft and other unlawful activity are prohibited.'),
          faq(Icons.verified_user_outlined, 'Who is responsible for quality?',
              'The two parties to the exchange are responsible for the quality of the work. Skill4Handel provides matching only.'),
          faq(Icons.event_busy, 'When may an offer be cancelled?',
              'A pending offer with no response is cancelled after 24 hours. An accepted offer may be cancelled until 24 hours before the agreed time.'),
          faq(Icons.gavel, 'How may arbitration be requested?',
              'Select Arbitration, describe the matter, and submit the ticket. Correspondence may also be sent to info@skill4handel.com.'),
        ],
      ),
    );
  }
}