import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';

class CompleteSwapScreen extends StatefulWidget {
  const CompleteSwapScreen({
    super.key,
    required this.otherName,
    required this.chatId,
    this.photoUrl,
  });

  final String otherName;
  final int chatId;
  final String? photoUrl;

  @override
  State<CompleteSwapScreen> createState() => _CompleteSwapScreenState();
}

class _CompleteSwapScreenState extends State<CompleteSwapScreen> {
  final skillRequested = TextEditingController();
  final skillOffered = TextEditingController();
  final extraTokens = TextEditingController();
  final location = TextEditingController();
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  String duration = '60';
  String mode = 'Online';
  String payMode = 'skill';
  bool acceptedQuality = false;
  bool working = false;
  DateTime? when;

  DateTime get minWhen => DateTime.now().add(const Duration(hours: 24));
  bool get useSkill => payMode == 'skill' || payMode == 'both';
  bool get useTokens => payMode == 'tokens' || payMode == 'both';
  bool get volunteer => payMode == 'volunteer';

  Future<void> pickWhen() async {
    final min = minWhen;
    final date = await showDatePicker(
      context: context,
      initialDate: (when ?? min).isAfter(min) ? (when ?? min) : min,
      firstDate: min,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(when ?? min),
    );
    final next = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? min.hour,
      time?.minute ?? min.minute,
    );
    setState(() => when = next.isBefore(min) ? min : next);
  }

  String earliestLabel() {
    final min = minWhen;
    return '${min.day} ${_month(min.month)}, ${TimeOfDay.fromDateTime(min).format(context)}';
  }

  String _month(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> submit() async {
    if (skillRequested.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write the skill you request')));
      return;
    }
    if (useSkill && skillOffered.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write the skill you offer')));
      return;
    }
    if (useTokens && (int.tryParse(extraTokens.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter tokens (1 to 10)')));
      return;
    }
    if (when == null || when!.isBefore(minWhen)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The earliest time is 24 hours from now')));
      return;
    }
    if (!acceptedQuality) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirm the quality responsibility')));
      return;
    }
    setState(() => working = true);
    try {
      await dio.post('/chats/${widget.chatId}/swap', data: {
        'userId': Session.id,
        'proposedByName': Session.name,
        'skillRequested': skillRequested.text.trim(),
        'skillOffered': volunteer ? 'Volunteer help' : (useSkill ? skillOffered.text.trim() : ''),
        'payWithTokens': useTokens,
        'volunteer': volunteer,
        'extraTokens': useTokens ? (int.tryParse(extraTokens.text) ?? 0) : 0,
        'duration': duration,
        'mode': mode,
        'level': volunteer ? 'Volunteer' : 'Normal',
        'location': location.text.trim(),
        'when': when!.toIso8601String(),
        'scheduledAt': when!.toIso8601String(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        title: Text('Offer to ${widget.otherName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const Text(
            'Choose how you want to exchange. The meeting must be at least 24 hours from now.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: payMode,
            decoration: const InputDecoration(labelText: 'Exchange type'),
            items: const [
              DropdownMenuItem(value: 'skill', child: Text('Skill for skill')),
              DropdownMenuItem(value: 'both', child: Text('Skill + S4H tokens')),
              DropdownMenuItem(value: 'tokens', child: Text('Only S4H tokens')),
              DropdownMenuItem(value: 'volunteer', child: Text('Volunteer help')),
            ],
            onChanged: (value) => setState(() => payMode = value ?? 'skill'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: skillRequested,
            decoration: const InputDecoration(labelText: 'Skill you request'),
          ),
          if (useSkill) ...[
            const SizedBox(height: 12),
            TextField(
              controller: skillOffered,
              decoration: const InputDecoration(labelText: 'Skill you offer in return'),
            ),
          ],
          if (useTokens) ...[
            const SizedBox(height: 12),
            TextField(
              controller: extraTokens,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'S4H tokens (max 10 per hour)'),
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date and time', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              when == null
                  ? 'Not set. Earliest: ${earliestLabel()}'
                  : '${MaterialLocalizations.of(context).formatMediumDate(when!)}, ${TimeOfDay.fromDateTime(when!).format(context)}',
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: pickWhen,
          ),
          DropdownButtonFormField<String>(
            initialValue: duration,
            decoration: const InputDecoration(labelText: 'Duration (minutes)'),
            items: const [
              DropdownMenuItem(value: '30', child: Text('30')),
              DropdownMenuItem(value: '60', child: Text('60')),
              DropdownMenuItem(value: '90', child: Text('90')),
            ],
            onChanged: (value) => setState(() => duration = value ?? '60'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: mode,
            decoration: const InputDecoration(labelText: 'Mode'),
            items: const [
              DropdownMenuItem(value: 'Online', child: Text('Online')),
              DropdownMenuItem(value: 'In person', child: Text('In person')),
            ],
            onChanged: (value) => setState(() => mode = value ?? 'Online'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: location,
            decoration: const InputDecoration(labelText: 'Place or meeting note'),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: acceptedQuality,
            onChanged: (value) => setState(() => acceptedQuality = value ?? false),
            controlAffinity: ListTileControlAffinity.trailing,
            title: const Text('I understand the quality of this work is our responsibility, not Skill4Handel.'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: working ? null : submit,
              style: AppTheme.solid(AppColors.green),
              child: Text(working ? 'Sending...' : 'Send offer', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}