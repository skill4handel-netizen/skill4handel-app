import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../home/demo_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key, this.initialType, this.initialOtherName});

  final String? initialType;
  final String? initialOtherName;

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final dio = Api.client;
  final text = TextEditingController();
  late String type = widget.initialType ?? 'support';
  bool sending = false;

  String cleanError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null)
        return data['message'].toString();
      if (error.response?.statusCode != null) {
        return 'The ticket could not be submitted (${error.response?.statusCode}). Please try again.';
      }
    }
    return S.t('ticketFail');
  }

  Future<void> sendTicket() async {
    if (text.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('ticketEmpty'))));
      return;
    }
    setState(() => sending = true);
    try {
      await dio.post(
        '/auth/ticket',
        data: {
          'userId': Session.id,
          'name': Session.name,
          'type': type,
          'otherName': widget.initialOtherName ?? '',
          'text': text.text.trim(),
        },
      );
      text.clear();
      type = widget.initialType ?? 'support';
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('ticketSent'))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(cleanError(e))));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> openLink(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppColors.blue),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget typeCard(
    String value,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
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
          border: Border.all(
            color: selected ? color : const Color(0xFFE4E7EC),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 28,
              color: selected ? color : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget contactCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
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
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.blue,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 28),
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
            child: Icon(icon, color: AppColors.blue, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
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
    final bottom = MediaQuery.of(context).padding.bottom + 24;
    return Scaffold(
      appBar: AppBar(
        title: Text(type == 'report' ? S.t('report') : S.t('support')),
        automaticallyImplyLeading: Navigator.canPop(context),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
        children: [
          sectionTitle('Help', Icons.menu_book_outlined),
          Material(
            color: const Color(0xFFE8F1FF),
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const CircleAvatar(
                backgroundColor: AppColors.blue,
                child: Icon(Icons.play_circle_outline, color: Colors.white),
              ),
              title: const Text(
                'How Skill4Handel works',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(S.t('productGuide')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DemoScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          sectionTitle(S.t('contact'), Icons.phone_in_talk),
          contactCard(
            Icons.email_outlined,
            S.t('email'),
            'info@skill4handel.com',
            () => openLink('mailto:info@skill4handel.com'),
          ),
          const SizedBox(height: 8),
          contactCard(
            Icons.language,
            S.t('website'),
            'www.skill4handel.com',
            () => openLink('https://www.skill4handel.com'),
          ),
          const SizedBox(height: 20),
          sectionTitle(S.t('newTicket'), Icons.edit_note),
          if (reported.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4D6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${S.t('member')}: $reported',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          typeCard(
            'support',
            Icons.support_agent,
            S.t('support'),
            S.t('supportHint'),
            AppColors.blue,
          ),
          typeCard(
            'arbitration',
            Icons.gavel,
            S.t('arbitration'),
            S.t('arbitrationHint'),
            const Color(0xFFE3A008),
          ),
          typeCard(
            'report',
            Icons.flag_outlined,
            S.t('reportMember'),
            S.t('reportHint'),
            const Color(0xFFD92D20),
          ),
          typeCard(
            'fraud',
            Icons.warning_amber_rounded,
            S.t('fraud'),
            S.t('fraudHint'),
            const Color(0xFFB42318),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: text,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: S.t('details'),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: sending ? null : sendTicket,
              style: AppTheme.solid(AppColors.green),
              icon: const Icon(Icons.send, color: Colors.white, size: 26),
              label: Text(
                sending ? S.t('sending') : S.t('submitTicket'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 24),
          sectionTitle(S.t('faq'), Icons.help_outline),
          faq(Icons.info_outline, S.t('faq1q'), S.t('faq1a')),
          faq(Icons.payments_outlined, S.t('faq2q'), S.t('faq2a')),
          faq(Icons.swap_horiz, S.t('faq3q'), S.t('faq3a')),
          faq(Icons.videocam_outlined, S.t('faq4q'), S.t('faq4a')),
          faq(Icons.badge_outlined, S.t('faq5q'), S.t('faq5a')),
          faq(Icons.block, S.t('faq6q'), S.t('faq6a')),
          faq(Icons.verified_user_outlined, S.t('faq7q'), S.t('faq7a')),
          faq(Icons.event_busy, S.t('faq8q'), S.t('faq8a')),
          faq(Icons.gavel, S.t('faq9q'), S.t('faq9a')),
        ],
      ),
    );
  }
}
