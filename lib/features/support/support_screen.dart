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
        title: Text(type == 'report' ? 'Submit a report' : 'Support'),
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
            child: const Text('Contact support by email'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await launchUrl(Uri.parse('https://www.skill4handel.com'), mode: LaunchMode.externalApplication);
              } catch (_) {}
            },
            child: const Text('Visit skill4handel.com'),
          ),
          if ((widget.initialOtherName ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('Subject: ${widget.initialOtherName}', style: const TextStyle(color: AppColors.muted)),
            ),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Request type'),
            items: const [
              DropdownMenuItem(value: 'support', child: Text('Support')),
              DropdownMenuItem(value: 'arbitration', child: Text('Arbitration')),
              DropdownMenuItem(value: 'report', child: Text('Report a member')),
              DropdownMenuItem(value: 'fraud', child: Text('Fraud')),
            ],
            onChanged: (value) => setState(() => type = value ?? 'support'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: text,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Details'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: sending ? null : sendTicket,
              style: AppTheme.solid(AppColors.green),
              child: Text(sending ? 'Submitting...' : 'Submit ticket', style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Frequently asked questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          faq('What is Skill4Handel?', 'Skill4Handel is a platform for exchanging skills and practical assistance without direct payment between members.'),
          faq('Is the service free of charge?', 'Registration is free of charge. Core skill exchanges do not require cash between members. S4H tokens may be used when a direct exchange is not possible.'),
          faq('How does an exchange work?', 'Members record the skills they can provide and the skills they require, send an offer, agree on the terms, complete the session, and submit a review.'),
          faq('Is a skill required?', 'Yes. Participation is based on giving and receiving skills, including language, practical assistance, study support, or volunteer work.'),
          faq('May exchanges take place online?', 'Yes. Members may select an online or in-person meeting when submitting an offer.'),
          faq('Who may use the application?', 'The service is available to users aged 16 and over. Members are advised to review profiles and meet in a safe location.'),
          faq('What activity is prohibited?', 'Sexual services, pornography, violence, weapons, illegal drugs, fraud, theft and other unlawful activity are prohibited and will result in account suspension.'),
          faq('Who is responsible for quality?', 'The two parties to the exchange are responsible for the quality of the work. Skill4Handel provides matching services only and is not the service provider.'),
          faq('When may an offer be cancelled?', 'An accepted offer may be cancelled up to 24 hours before the agreed date and time. A pending offer with no response is cancelled after 24 hours.'),
          faq('How may arbitration be requested?', 'Select Arbitration, describe the matter, and submit the ticket. Correspondence may also be sent to info@skill4handel.com.'),
        ],
      ),
    );
  }
}