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
  bool payWithTokens = false;
  bool volunteer = false;
  bool working = false;
  DateTime when = DateTime.now().add(const Duration(days: 1));

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
    if (!payWithTokens && !volunteer && skillOffered.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer a skill, volunteer, or pay with tokens')));
      return;
    }
    setState(() => working = true);
    try {
      await dio.post('/chats/${widget.chatId}/swap', data: {
        'userId': Session.id,
        'proposedByName': Session.name,
        'skillRequested': skillRequested.text.trim(),
        'skillOffered': payWithTokens || volunteer ? '' : skillOffered.text.trim(),
        'payWithTokens': payWithTokens,
        'volunteer': volunteer,
        'extraTokens': int.tryParse(extraTokens.text) ?? 0,
        'duration': duration,
        'mode': mode,
        'level': level,
        'when': when.toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pay with tokens'),
            value: payWithTokens,
            onChanged: (value) => setState(() {
              payWithTokens = value;
              if (value) volunteer = false;
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Volunteer'),
            subtitle: const Text('Offer help without a return skill'),
            value: volunteer,
            onChanged: (value) => setState(() {
              volunteer = value;
              if (value) payWithTokens = false;
            }),
          ),
          if (!payWithTokens && !volunteer)
            TextField(
              controller: skillOffered,
              decoration: const InputDecoration(labelText: 'Skill you offer', prefixIcon: Icon(Icons.handshake_outlined)),
            )
          else if (payWithTokens)
            TextField(
              controller: extraTokens,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tokens (max 10 per hour)', prefixIcon: Icon(Icons.token_outlined)),
            ),
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