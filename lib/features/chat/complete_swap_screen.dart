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
  final extraTokens = TextEditingController();
  final location = TextEditingController();
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  String duration = '60';
  String mode = 'Online';
  String payMode = 'skill';
  String selectedSkill = '';
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
    loadOtherSkills();
  }

  String apiError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) return data['message'].toString();
    }
    return 'The request could not be sent.';
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

  String prettyWhen(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}  •  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> submit() async {
    final requested = widget.isCounter ? widget.initialSkillRequested.trim() : selectedSkill;
    final offered = widget.isCounter && useSkill ? selectedSkill : '';
    if (!widget.isCounter && requested.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a skill from their list.')));
      return;
    }
    if (widget.isCounter && useSkill && offered.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a skill from their list.')));
      return;
    }
    if (useTokens && (int.tryParse(extraTokens.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter between 1 and 10 tokens.')));
      return;
    }
    if (when == null || when!.isBefore(minWhen)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isCounter ? 'Please select a date and time.' : 'Please choose a time at least 24 hours from now.'),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Widget typeCard(String value, IconData icon, String title, String subtitle) {
    final selected = payMode == value;
    return InkWell(
      onTap: () => setState(() => payMode = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F8EF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.green : const Color(0xFFE4E7EC)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: selected ? AppColors.green : AppColors.soft,
              child: Icon(icon, color: selected ? Colors.white : AppColors.blue),
            ),
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
            Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? AppColors.green : Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        title: Text(widget.isCounter ? 'Counter-offer' : 'New offer'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text(
            widget.isCounter ? 'Reply to ${widget.otherName}' : 'Offer to ${widget.otherName}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isCounter
                ? 'The requested skill stays the same. Choose one skill from their list, or use tokens or volunteer assistance.'
                : 'Select the skill you need from their list.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (widget.isCounter) ...[
            typeCard('skill', Icons.swap_horiz, 'Skill from their list', 'Ask for one of their skills in return'),
            typeCard('both', Icons.toll, 'Skill and tokens', 'A skill plus S4H tokens'),
            typeCard('tokens', Icons.account_balance_wallet_outlined, 'Tokens only', 'Pay with S4H tokens'),
            typeCard('volunteer', Icons.volunteer_activism, 'Volunteer assistance', 'Do the requested skill with no return'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Requested skill', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                        Text(
                          widget.initialSkillRequested.isEmpty ? '—' : widget.initialSkillRequested,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!widget.isCounter || useSkill) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: otherSkills.contains(selectedSkill) ? selectedSkill : null,
              decoration: InputDecoration(
                labelText: widget.isCounter ? 'Skill you ask from their list' : 'Skill you need from their list',
              ),
              items: [for (final skill in otherSkills) DropdownMenuItem(value: skill, child: Text(skill))],
              onChanged: (value) => setState(() => selectedSkill = value ?? ''),
            ),
            if (otherSkills.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('This member has not listed skills to offer.', style: TextStyle(color: AppColors.muted)),
              ),
          ],
          if (widget.isCounter && useTokens) ...[
            const SizedBox(height: 12),
            TextField(
              controller: extraTokens,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'S4H tokens (1–10)', prefixIcon: Icon(Icons.toll)),
            ),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: pickWhen,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE4E7EC)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: AppColors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      when == null
                          ? (widget.isCounter ? 'Choose date and time' : 'Choose a time at least 24 hours from now')
                          : prettyWhen(when!),
                      style: TextStyle(fontWeight: FontWeight.w700, color: when == null ? AppColors.muted : Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: duration,
                  decoration: const InputDecoration(labelText: 'Minutes'),
                  items: const [
                    DropdownMenuItem(value: '30', child: Text('30')),
                    DropdownMenuItem(value: '60', child: Text('60')),
                    DropdownMenuItem(value: '90', child: Text('90')),
                  ],
                  onChanged: (value) => setState(() => duration = value ?? '60'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: mode,
                  decoration: const InputDecoration(labelText: 'How'),
                  items: const [
                    DropdownMenuItem(value: 'Online', child: Text('Online')),
                    DropdownMenuItem(value: 'In person', child: Text('In person')),
                  ],
                  onChanged: (value) => setState(() => mode = value ?? 'Online'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: location,
            decoration: InputDecoration(
              labelText: mode == 'Online' ? 'Link or note' : 'Meeting place',
              prefixIcon: Icon(mode == 'Online' ? Icons.link : Icons.place_outlined),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: acceptedQuality,
            onChanged: (value) => setState(() => acceptedQuality = value ?? false),
            title: const Text('I accept responsibility for the quality of this exchange.'),
          ),
          const SizedBox(height: 8),
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