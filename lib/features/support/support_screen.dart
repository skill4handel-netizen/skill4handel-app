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
  late final otherName = TextEditingController(text: widget.initialOtherName ?? '');
  late String type = widget.initialType ?? 'support';
  bool sending = false;

  String cleanError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
      if (error.response?.statusCode != null) {
        return 'Could not send ticket (${error.response?.statusCode}). Try again.';
      }
    }
    return 'Could not send ticket. Try again.';
  }

  Future<void> sendTicket() async {
    if (text.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write your message first')));
      return;
    }
    setState(() => sending = true);
    try {
      await dio.post('/auth/ticket', data: {
        'userId': Session.id,
        'name': Session.name,
        'type': type,
        'otherName': otherName.text.trim(),
        'text': text.text.trim(),
      });
      text.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(cleanError(e))));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Widget faq(String title, String body) {
    return ExpansionTile(
      title: Text(title),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(body),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        automaticallyImplyLeading: Navigator.canPop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          const Text('info@skill4handel.com', style: TextStyle(fontWeight: FontWeight.w700)),
          TextButton(
            onPressed: () async {
              try {
                await launchUrl(Uri.parse('mailto:info@skill4handel.com'));
              } catch (_) {}
            },
            child: const Text('Email support'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await launchUrl(Uri.parse('https://www.skill4handel.com'), mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: const Text('Open skill4handel.com'),
          ),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(value: 'support', child: Text('Support')),
              DropdownMenuItem(value: 'arbitration', child: Text('Arbitration')),
              DropdownMenuItem(value: 'report', child: Text('Report a person')),
              DropdownMenuItem(value: 'fraud', child: Text('Fraud')),
            ],
            onChanged: (value) => setState(() => type = value ?? 'support'),
          ),
          const SizedBox(height: 12),
          TextField(controller: otherName, decoration: const InputDecoration(labelText: 'Person involved')),
          const SizedBox(height: 12),
          TextField(controller: text, maxLines: 5, decoration: const InputDecoration(labelText: 'Details')),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: sending ? null : sendTicket,
              style: AppTheme.solid(AppColors.green),
              child: Text(sending ? 'Sending...' : 'Send ticket', style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('FAQ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          faq('What is Skill4Handel?', 'A place to exchange skills and practical help without paying each other. You share what you know and get what you need.'),
          faq('Is it free?', 'Joining is free. Core skill swaps stay without cash between people. S4H tokens help when a direct swap is not possible.'),
          faq('How does a swap work?', 'List what you can give and what you want. Find someone nearby or online. Meet, help each other, mark the task done, and leave a short review.'),
          faq('Do I need a skill?', 'Yes. The idea is give and get. That can be language, a small repair, study help, everyday know-how, or volunteer help.'),
          faq('Can I swap online?', 'Some skills work over a call or a screen. Others need a cafe or a doorstep. You choose in the offer.'),
          faq('Who can use the app?', 'Users 16 and older. Read the profile first and meet where you feel safe.'),
          faq('What is banned?', 'Sex work, pornography, violent work, weapons, illegal drugs, fraud, theft and other illegal activity. These accounts will be banned.'),
          faq('Who is responsible for quality?', 'The two people in the swap. Skill4Handel is a matching platform, not the service provider.'),
          faq('When can I cancel?', 'Until 24 hours before the agreed date and time.'),
          faq('How do I ask for arbitration?', 'Choose Arbitration in the form, write what happened, and send the ticket. You can also email info@skill4handel.com.'),
        ],
      ),
    );
  }
}