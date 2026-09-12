import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';

class CompleteSwapScreen extends StatefulWidget {
  const CompleteSwapScreen({
    super.key,
    required this.otherName,
    required this.chatId,
    this.otherId = 0,
    this.photoUrl,
    this.isCounter = false,
    this.initialSkillRequested = '',
  });

  final String otherName;
  final int chatId;
  final int otherId;
  final String? photoUrl;
  final bool isCounter;
  final String initialSkillRequested;

  @override
  State<CompleteSwapScreen> createState() => _CompleteSwapScreenState();
}

class _CompleteSwapScreenState extends State<CompleteSwapScreen> {
  late final skillRequested = TextEditingController(text: widget.initialSkillRequested);
  final skillOffered = TextEditingController();
  final extraTokens = TextEditingController();
  final location = TextEditingController();
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  String duration = '60';
  String mode = 'Online';
  String payMode = 'skill';
  String selectedOffer = '';
  List<String> otherSkills = [];
  bool acceptedQuality = false;
  bool working = false;
  DateTime? when;

  DateTime get minWhen =>
      widget.isCounter ? DateTime.now() : DateTime.now().add(const Duration(hours: 24));
  bool get useSkill => payMode == 'skill' || payMode == 'both';
  bool get useTokens => payMode == 'tokens' || payMode == 'both';
  bool get volunteer => payMode == 'volunteer';

  @override
  void initState() {
    super.initState();
    if (widget.isCounter) loadOtherSkills();
  }

  Future<void> loadOtherSkills() async {
    if (widget.otherId == 0) return;
    try {
      final response = await dio.get('/users/${widget.otherId}');
      final user = response.data is Map ? (response.data['user'] ?? response.data) : null;
      final raw = user is Map ? (user['offers']?.toString() ?? '') : '';
      final list = raw.split(RegExp(r'[,/]')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
      if (mounted) setState(() => otherSkills = list);
    } catch (_) {}
  }

  Future<void> pickWhen() async {
    final min = minWhen;
    final date = await showDatePicker(
      context: context,
      initialDate: (when ?? min).isAfter(min) ? (when ?? min) : min,
      firstDate: DateTime(min.year, min.month, min.day),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(when ?? min));
    final next = DateTime(date.year, date.month, date.day, time?.hour ?? min.hour, time?.minute ?? min.minute);
    setState(() => when = next.isBefore(min) ? min : next);
  }

  String earliestLabel() {
    final min = minWhen;
    return '${min.day} ${_month(min.month)} ${min.year}, ${TimeOfDay.fromDateTime(min).format(context)}';
  }

  String _month(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Future<void> submit() async {
    final requested = widget.isCounter ? widget.initialSkillRequested.trim() : skillRequested.text.trim();
    final offered = widget.isCounter ? selectedOffer : skillOffered.text.trim();
    if (requested.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The requested skill is missing.')));
      return;
    }
    if (useSkill && offered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isCounter
            ? 'Please select one skill from the original member’s list.'
            : 'Please enter the skill offered in return.'),
      ));
      return;
    }
    if (useTokens && (int.tryParse(extraTokens.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter between 1 and 10 tokens.')));
      return;
    }
    if (when == null || when!.isBefore(minWhen)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isCounter ? 'Please select a date and time.' : 'The earliest available time is 24 hours from now.'),
      ));
      return;
    }
    if (!acceptedQuality) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please confirm responsibility for the quality of the work.')));
      return;
    }
    setState(() => working = true);
    try {
      await dio.post('/chats/${widget.chatId}/swap', data: {
        'userId': Session.id,
        'proposedByName': Session.name,
        'skillRequested': requested,
        'skillOffered': volunteer ? '' : offered,
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
    final types = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'skill', child: Text('Skill for skill')),
      const DropdownMenuItem(value: 'both', child: Text('Skill and S4H tokens')),
      const DropdownMenuItem(value: 'tokens', child: Text('S4H tokens only')),
      if (widget.isCounter) const DropdownMenuItem(value: 'volunteer', child: Text('Volunteer assistance')),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        title: Text(widget.isCounter ? 'Counter-offer to ${widget.otherName}' : 'Offer to ${widget.otherName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            widget.isCounter
                ? 'The original requested skill stays the same. You may accept it as volunteer assistance, or choose one skill from the other member’s list, with or without tokens.'
                : 'Select the terms of the exchange. The meeting must be scheduled at least 24 hours from now.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: payMode,
            decoration: const InputDecoration(labelText: 'Exchange type'),
            items: types,
            onChanged: (value) => setState(() => payMode = value ?? 'skill'),
          ),
          const SizedBox(height: 12),
          if (widget.isCounter)
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Requested skill'),
              child: Text(
                widget.initialSkillRequested.isEmpty ? '—' : widget.initialSkillRequested,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          else
            TextField(
              controller: skillRequested,
              decoration: const InputDecoration(labelText: 'Requested skill'),
            ),
          if (useSkill && widget.isCounter) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedOffer.isEmpty ? null : selectedOffer,
              decoration: const InputDecoration(labelText: 'Skill you ask from their list'),
              items: [
                for (final skill in otherSkills) DropdownMenuItem(value: skill, child: Text(skill)),
              ],
              onChanged: (value) => setState(() => selectedOffer = value ?? ''),
            ),
            if (otherSkills.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('This member has not listed skills to offer.', style: TextStyle(color: AppColors.muted)),
              ),
          ] else if (useSkill) ...[
            const SizedBox(height: 12),
            TextField(
              controller: skillOffered,
              decoration: const InputDecoration(labelText: 'Skill offered in return'),
            ),
          ],
          if (useTokens) ...[
            const SizedBox(height: 12),
            TextField(
              controller: extraTokens,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'S4H tokens (maximum 10 per hour)'),
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date and time', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(
              when == null
                  ? (widget.isCounter ? 'Not set' : 'Not set. Earliest available: ${earliestLabel()}')
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
            decoration: InputDecoration(labelText: mode == 'Online' ? 'Meeting link or note' : 'Meeting place'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: acceptedQuality,
            onChanged: (value) => setState(() => acceptedQuality = value ?? false),
            title: const Text('I understand that the quality and outcome of this exchange are the responsibility of the parties.'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: working ? null : submit,
              style: AppTheme.solid(AppColors.green),
              child: Text(
                working ? 'Sending…' : (widget.isCounter ? 'Send counter-offer' : 'Send offer'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}