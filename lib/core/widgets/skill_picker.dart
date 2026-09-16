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

  List<String> get filtered {
    final q = query.text.trim().toLowerCase();
    return allowedSkills
        .where((item) => !widget.alreadySelected.contains(item))
        .where((item) => q.isEmpty || item.toLowerCase().contains(q))
        .toList();
  }

  void addCustom(String value) {
    final text = value.trim();
    if (text.isEmpty || !widget.canAddCustom) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final typed = query.text.trim();
    final typedIsNew = typed.isNotEmpty &&
        !allowedSkills.any((item) => item.toLowerCase() == typed.toLowerCase());

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
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
                  hintText: 'Type to filter, or write a custom skill',
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Other', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          widget.canAddCustom
                              ? 'Write a skill that is not in the list. Maximum 3 custom skills.'
                              : 'Custom skill limit reached.',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: other,
                          enabled: widget.canAddCustom,
                          decoration: const InputDecoration(hintText: 'Write the skill'),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: widget.canAddCustom ? () => addCustom(other.text) : null,
                                style: AppTheme.solid(AppColors.green),
                                child: const Text('Add Other', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            if (typedIsNew && widget.canAddCustom) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => addCustom(typed),
                                  child: Text('Add "$typed"'),
                                ),
                              ),
                            ],
                          ],
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