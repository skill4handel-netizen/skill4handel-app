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
  final extraTokens = TextEditingController(text: '0');
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  String duration = '60';
  String mode = 'Online';
  String level = 'Normal';
  String payMode = 'skill';
  bool working = false;
  DateTime when = DateTime.now().add(const Duration(days: 1));

  bool get useSkill => payMode == 'skill' || payMode == 'both';
  bool get useTokens => payMode == 'tokens' || payMode == 'both';
  bool get volunteer => payMode == 'volunteer';

  Future<void> pickWhen() async {
    final date = await showDatePicker(
      context: context,
      initialDate: when,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(when),
    );
    setState(() {
      when = DateTime(date.year, date.month, date.day, time?.hour ?? when.hour, time?.minute ?? when.minute);
    });
  }

  Future<void> submit() async {
    if (skillRequested.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write the requested skill')));
      return;
    }
    if (useSkill && skillOffered.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Write the skill you offer')));
      return;
    }
    if (useTokens && (int.tryParse(extraTokens.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter tokens (1 to 10 per hour)')));
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
        'level': volunteer ? 'Volunteer' : level,
        'when': when.toIso8601String(),
        'scheduledAt': when.toIso8601String(),
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
      appBar: AppBar(title: Text(widget.otherName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Skill exchange', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('If there is no answer in 24 hours, the offer is cancelled.', style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          TextField(
            controller: skillRequested,
            decoration: const InputDecoration(labelText: 'Skill you need', prefixIcon: Icon(Icons.flag_outlined)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: payMode,
            decoration: const InputDecoration(labelText: 'What you give', prefixIcon: Icon(Icons.swap_horiz)),
            items: const [
              DropdownMenuItem(value: 'skill', child: Text('Skill only')),
              DropdownMenuItem(value: 'tokens', child: Text('Tokens only')),
              DropdownMenuItem(value: 'both', child: Text('Skill + tokens')),
              DropdownMenuItem(value: 'volunteer', child: Text('Volunteer')),
            ],
            onChanged: (value) => setState(() => payMode = value ?? 'skill'),
          ),
          if (useSkill) ...[
            const SizedBox(height: 12),
            TextField(
              controller: skillOffered,
              decoration: const InputDecoration(labelText: 'Skill you offer', prefixIcon: Icon(Icons.handshake_outlined)),
            ),
          ],
          if (useTokens) ...[
            const SizedBox(height: 12),
            TextField(
              controller: extraTokens,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tokens (max 10 per hour)', prefixIcon: Icon(Icons.token_outlined)),
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: const Text('When'),
            subtitle: Text('${MaterialLocalizations.of(context).formatFullDate(when)}, ${TimeOfDay.fromDateTime(when).format(context)}'),
            onTap: pickWhen,
          ),
          DropdownButtonFormField<String>(
            initialValue: duration,
            decoration: const InputDecoration(labelText: 'Duration', prefixIcon: Icon(Icons.schedule)),
            items: const [
              DropdownMenuItem(value: '30', child: Text('30 min')),
              DropdownMenuItem(value: '60', child: Text('60 min')),
              DropdownMenuItem(value: '90', child: Text('90 min')),
            ],
            onChanged: (value) => setState(() => duration = value ?? '60'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: mode,
            decoration: const InputDecoration(labelText: 'How', prefixIcon: Icon(Icons.place_outlined)),
            items: const [
              DropdownMenuItem(value: 'Online', child: Text('Online')),
              DropdownMenuItem(value: 'In person', child: Text('In person')),
            ],
            onChanged: (value) => setState(() => mode = value ?? 'Online'),
          ),
          if (!volunteer) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: level,
              decoration: const InputDecoration(labelText: 'Level', prefixIcon: Icon(Icons.tune)),
              items: const [
                DropdownMenuItem(value: 'Beginner', child: Text('Beginner')),
                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                DropdownMenuItem(value: 'Advanced', child: Text('Advanced')),
              ],
              onChanged: (value) => setState(() => level = value ?? 'Normal'),
            ),
          ],
          const SizedBox(height: 24),
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