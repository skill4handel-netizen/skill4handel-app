class SkillItem {
  SkillItem({required this.name, this.note = '', this.featured = false});

  final String name;
  final String note;
  final bool featured;
}

List<SkillItem> parseSkills(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return [];
  if (value.contains('::') || value.contains('|')) {
    return value.split('|').where((item) => item.trim().isNotEmpty).map((item) {
      final parts = item.split('::');
      final name = parts.first.trim();
      final note = parts.length > 1 ? parts.sublist(1).join('::').trim() : '';
      return SkillItem(name: name, note: note);
    }).where((item) => item.name.isNotEmpty).toList();
  }
  return value
      .split(RegExp(r'[,/]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .map((name) => SkillItem(name: name))
      .toList();
}

String encodeSkills(List<SkillItem> items) {
  return items
      .map((item) => item.note.trim().isEmpty ? item.name : '${item.name}::${item.note.trim()}')
      .join('|');
}

String skillNames(String raw) => parseSkills(raw).map((item) => item.name).join(', ');