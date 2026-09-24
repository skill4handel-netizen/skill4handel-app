import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/constants/skill_items.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/skill_labels.dart';
import '../../core/theme/app_theme.dart';

class CompleteSwapScreen extends StatefulWidget {
  const CompleteSwapScreen({
    super.key,
    required this.otherName,
    required this.chatId,
    this.otherId = 0,
    this.photoUrl,
    this.isCounter = false,
    this.isAccept = false,
    this.initialSkillRequested = '',
    this.initialDuration = '60',
    this.initialMode = 'Online',
    this.initialLocation = '',
    this.initialWhen,
    this.initialPayMode = 'skill',
    this.initialTokens = '',
  });

  final String otherName;
  final int chatId;
  final int otherId;
  final String? photoUrl;
  final bool isCounter;
  final bool isAccept;
  final String initialSkillRequested;
  final String initialDuration;
  final String initialMode;
  final String initialLocation;
  final DateTime? initialWhen;
  final String initialPayMode;
  final String initialTokens;

  @override
  State<CompleteSwapScreen> createState() => _CompleteSwapScreenState();
}

class _CompleteSwapScreenState extends State<CompleteSwapScreen> {
  late final extraTokens = TextEditingController();
  late final location = TextEditingController(text: widget.initialLocation);
  final dio = Api.client;
  late String duration = widget.initialDuration.isEmpty
      ? '60'
      : widget.initialDuration;
  late String mode = widget.initialMode.isEmpty ? 'Online' : widget.initialMode;
  late String payMode;
  String selectedSkill = '';
  List<String> otherSkills = [];
  bool acceptedQuality = false;
  bool working = false;
  DateTime? when;

  DateTime get minWhen => DateTime.now().add(const Duration(hours: 24));
  bool get useSkill => payMode == 'skill' || payMode == 'both';
  bool get useTokens => payMode == 'tokens' || payMode == 'both';
  bool get volunteer => payMode == 'volunteer';
  bool get lockSchedule => widget.isAccept;

  @override
  void initState() {
    super.initState();
    when = widget.initialWhen;
    final incoming = widget.initialPayMode.toLowerCase();
    payMode = incoming.contains('volunteer')
        ? 'volunteer'
        : (incoming.isEmpty ? 'skill' : widget.initialPayMode);
    extraTokens.text = widget.initialTokens;
    loadOtherSkills();
  }

  String apiError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return S.t('sendFailed');
  }

  Future<void> loadOtherSkills() async {
    if (widget.otherId == 0) return;
    try {
      final response = await dio.get('/users/${widget.otherId}');
      final user = response.data is Map
          ? (response.data['user'] ?? response.data)
          : null;
      final raw = user is Map ? (user['offers']?.toString() ?? '') : '';
      final list = parseSkills(raw).map((item) => item.name).toSet().toList();
      if (mounted) setState(() => otherSkills = list);
    } catch (_) {}
  }

  Future<void> pickWhen() async {
    if (lockSchedule) return;
    final min = minWhen;
    final date = await showDatePicker(
      context: context,
      initialDate: (when ?? min).isAfter(min) ? (when ?? min) : min,
      firstDate: DateTime(min.year, min.month, min.day),
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

  String prettyWhen(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}  •  ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String typeLabel() {
    switch (payMode) {
      case 'both':
        return S.t('skillPlusTokens');
      case 'tokens':
        return S.t('tokensOnly');
      case 'volunteer':
        return 'Volunteer';
      default:
        return S.t('skillForSkill');
    }
  }

  Future<void> submit() async {
    final requested = widget.isCounter
        ? widget.initialSkillRequested.trim()
        : selectedSkill;
    final offered = useSkill ? selectedSkill : '';
    if (!widget.isAccept && !widget.isCounter && requested.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('pleaseSelectSkill'))));
      return;
    }
    if (widget.isCounter && useSkill && !volunteer && offered.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('pleaseSelectSkill'))));
      return;
    }
    if (useTokens && (int.tryParse(extraTokens.text) ?? 0) <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('pleaseTokens'))));
      return;
    }
    if (!widget.isAccept && (when == null || when!.isBefore(minWhen))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('pleaseTime24'))));
      return;
    }
    if (!acceptedQuality) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('pleaseQuality'))));
      return;
    }
    // Accept confirms the existing offer. No new skill is required.
    setState(() => working = true);
    try {
      if (widget.isAccept) {
        await dio.post(
          '/chats/${widget.chatId}/swap/respond',
          data: {
            'userId': Session.id,
            'action': 'accepted',
            'skillOffered': volunteer ? '' : selectedSkill,
          },
        );
      } else {
        await dio.post(
          '/chats/${widget.chatId}/swap',
          data: {
            'userId': Session.id,
            'proposedByName': Session.name,
            'skillRequested': requested,
            'skillOffered': volunteer ? '' : (widget.isCounter ? offered : ''),
            'payWithTokens': useTokens,
            'volunteer': volunteer,
            'extraTokens': useTokens
                ? (int.tryParse(extraTokens.text) ?? 0)
                : 0,
            'duration': duration,
            'mode': mode,
            'level': volunteer ? 'Volunteer' : typeLabel(),
            'location': location.text.trim(),
            'when': when!.toUtc().toIso8601String(),
            'scheduledAt': when!.toUtc().toIso8601String(),
          },
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isCounter ? S.t('counterSentOk') : S.t('offerSentOk'),
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(apiError(e))));
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
          border: Border.all(
            color: selected ? AppColors.green : const Color(0xFFE4E7EC),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: selected ? AppColors.green : AppColors.soft,
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.blue,
              ),
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
              color: selected ? AppColors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget lockedBox(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: AppColors.muted),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.isAccept
              ? S.t('acceptOffer')
              : (widget.isCounter ? S.t('counterOffer') : S.t('newOffer')),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          Text(
            widget.isAccept
                ? S.t('acceptThisOffer')
                : widget.isCounter
                ? S.fill('replyTo', {'name': widget.otherName})
                : S.fill('offerTo', {'name': widget.otherName}),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            widget.isAccept
                ? (volunteer ? S.t('volunteerHelp') : S.t('lockedAcceptHelp'))
                : widget.isCounter
                ? S.t('counterHelp')
                : S.t('newOfferHelp'),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          if (widget.isAccept)
            lockedBox(
              S.t('exchangeType'),
              typeLabel(),
              Icons.handshake_outlined,
            )
          else ...[
            typeCard(
              'skill',
              Icons.swap_horiz,
              S.t('skillFromList'),
              'Skill for skill',
            ),
            typeCard(
              'both',
              Icons.toll,
              S.t('skillAndTokens'),
              S.t('skillPlusTokens'),
            ),
            typeCard(
              'tokens',
              Icons.account_balance_wallet_outlined,
              S.t('tokensOnly'),
              S.t('payTokens'),
            ),
            typeCard(
              'volunteer',
              Icons.volunteer_activism,
              S.t('volunteer'),
              S.t('doVolunteer'),
            ),
          ],
          if (widget.isCounter) ...[
            const SizedBox(height: 8),
            lockedBox(
              S.t('requestedSkill'),
              widget.initialSkillRequested.isEmpty
                  ? '—'
                  : widget.initialSkillRequested,
              Icons.school_outlined,
            ),
          ],
          if (!widget.isAccept &&
              ((!widget.isCounter) || useSkill) &&
              !volunteer) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: otherSkills.contains(selectedSkill)
                  ? selectedSkill
                  : null,
              decoration: InputDecoration(
                labelText: widget.isCounter
                    ? S.t('skillYouAsk')
                    : S.t('skillYouNeed'),
              ),
              items: [
                for (final skill in otherSkills)
                  DropdownMenuItem(
                    value: skill,
                    child: Text(skillLabel(skill)),
                  ),
              ],
              onChanged: (value) => setState(() => selectedSkill = value ?? ''),
            ),
            if (otherSkills.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  S.t('noListedSkills'),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
          ],
          if (useTokens && !widget.isAccept) ...[
            const SizedBox(height: 12),
            TextField(
              controller: extraTokens,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: S.t('s4hRange'),
                prefixIcon: const Icon(Icons.toll),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (lockSchedule) ...[
            lockedBox(
              S.t('when'),
              when == null ? '—' : prettyWhen(when!),
              Icons.event_available,
            ),
            lockedBox(S.t('minutes'), '$duration min', Icons.timer_outlined),
            lockedBox(S.t('how'), mode, Icons.place_outlined),
            if (widget.isAccept && useTokens)
              lockedBox(
                S.t('tokensLabel'),
                extraTokens.text.isEmpty ? '0' : extraTokens.text,
                Icons.toll,
              ),
            if (location.text.trim().isNotEmpty)
              lockedBox(
                mode == 'Online' ? S.t('linkNote') : S.t('meetingPlace'),
                location.text.trim(),
                Icons.lock_outline,
              ),
          ] else ...[
            InkWell(
              onTap: pickWhen,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.blue, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.blue,
                      child: const Icon(
                        Icons.event_available,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.t('dateAndTime'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            when == null
                                ? S.t('tapDateTime')
                                : prettyWhen(when!),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            S.t('earliest24h'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.blue),
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
                    decoration: InputDecoration(labelText: S.t('minutes')),
                    items: const [
                      DropdownMenuItem(value: '30', child: Text('30')),
                      DropdownMenuItem(value: '60', child: Text('60')),
                      DropdownMenuItem(value: '90', child: Text('90')),
                    ],
                    onChanged: (value) =>
                        setState(() => duration = value ?? '60'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: mode,
                    decoration: InputDecoration(labelText: S.t('how')),
                    items: [
                      DropdownMenuItem(
                        value: 'Online',
                        child: Text(S.t('online')),
                      ),
                      DropdownMenuItem(
                        value: 'In person',
                        child: Text(S.t('inPerson')),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => mode = value ?? 'Online'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: location,
              decoration: InputDecoration(
                labelText: mode == 'Online'
                    ? S.t('linkNote')
                    : S.t('meetingPlace'),
                prefixIcon: Icon(
                  mode == 'Online' ? Icons.link : Icons.place_outlined,
                ),
              ),
            ),
          ],
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: acceptedQuality,
            onChanged: (value) =>
                setState(() => acceptedQuality = value ?? false),
            title: Text(S.t('quality')),
          ),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: working ? null : submit,
              style: AppTheme.solid(AppColors.green),
              child: Text(
                working
                    ? S.t('sending')
                    : (widget.isAccept
                          ? S.t('accept')
                          : (widget.isCounter
                                ? S.t('sendCounter')
                                : S.t('sendOffer'))),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
