import 'package:flutter/material.dart';
import '../constants/skills.dart';
import '../theme/app_theme.dart';

Future<String?> pickSkill(
  BuildContext context, {
  required List<String> alreadySelected,
  int maxCustom = 3,
}) async {
  final customCount = alreadySelected.where((item) => !allowedSkills.contains(item)).length;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _SkillPickerSheet(
      alreadySelected: alreadySelected,
      canAddCustom: customCount < maxCustom,
    ),
  );
}

class _SkillPickerSheet extends StatefulWidget {
  const _SkillPickerSheet({required this.alreadySelected, required this.canAddCustom});

  final List<String> alreadySelected;
  final bool canAddCustom;

  @override
  State<_SkillPickerSheet> createState() => _SkillPickerSheetState();
}

class _SkillPickerSheetState extends State<_SkillPickerSheet> {
  final query = TextEditingController();
  final other = TextEditingController();
  bool otherMode = false;

  List<String> get filtered {
    final q = query.text.trim().toLowerCase();
    return allowedSkills
        .where((item) => !widget.alreadySelected.contains(item))
        .where((item) => q.isEmpty || item.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Select a skill', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: query,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Type to filter',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final skill in filtered)
                    ListTile(
                      title: Text(skill),
                      onTap: () => Navigator.pop(context, skill),
                    ),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No matching category.', style: TextStyle(color: AppColors.muted)),
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Other'),
                    subtitle: Text(widget.canAddCustom ? 'Add a skill outside this list' : 'Custom skill limit reached'),
                    enabled: widget.canAddCustom,
                    onTap: widget.canAddCustom ? () => setState(() => otherMode = true) : null,
                  ),
                  if (otherMode && widget.canAddCustom)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: other,
                              decoration: const InputDecoration(hintText: 'Write the skill'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final value = other.text.trim();
                              if (value.isEmpty) return;
                              Navigator.pop(context, value);
                            },
                            style: AppTheme.solid(AppColors.green),
                            child: const Text('Add', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}