import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/session.dart';
import '../../core/constants/skills.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/skill_picker.dart';
import '../auth/login_screen.dart';
import '../auth/terms_screen.dart';
import '../chat/blocked_screen.dart';
import '../support/support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userName, this.onSaved});

  final String? userName;
  final VoidCallback? onSaved;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  late final name = TextEditingController(text: Session.name.isNotEmpty ? Session.name : (widget.userName ?? ''));
  late final city = TextEditingController(text: Session.city);
  String gender = Session.gender.isNotEmpty ? Session.gender : 'prefer_not';
  late List<String> selectedSkills = Session.offers
      .split(RegExp(r'[,/]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  bool saving = false;

  int get customCount => selectedSkills.where((item) => !allowedSkills.contains(item)).length;

  ImageProvider? photoOf(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('data:')) {
      try {
        return MemoryImage(base64Decode(url.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  Future<void> pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photograph'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 45, maxWidth: 600);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    try {
      final response = await dio.post('/auth/photo', data: {'id': Session.id, 'photoUrl': dataUrl});
      final user = response.data is Map ? response.data['user'] : null;
      if (user is Map) Session.apply(Map<String, dynamic>.from(user));
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('photoError'))));
    }
  }

  Future<void> addSkill() async {
    if (selectedSkills.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You may select up to 10 skills.')));
      return;
    }
    final chosen = await pickSkill(context, alreadySelected: selectedSkills);
    if (chosen == null || selectedSkills.contains(chosen)) return;
    setState(() => selectedSkills.add(chosen));
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      final response = await dio.post('/auth/profile', data: {
        'id': Session.id,
        'name': name.text,
        'city': city.text,
        'offers': selectedSkills.join(', '),
        'needs': '',
        'gender': gender,
        'age': Session.age,
        'language': Session.language,
      });
      final user = response.data is Map ? response.data['user'] : response.data;
      if (user is Map) Session.apply(Map<String, dynamic>.from(user));
      Session.offers = selectedSkills.join(', ');
      Session.needs = '';
      await Session.save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('saved'))));
      widget.onSaved?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('saveError'))));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> logout() async {
    await Session.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = photoOf(Session.photoUrl);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 40),
      children: [
        Text(S.t('profile'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.blue,
                backgroundImage: photo,
                child: photo == null
                    ? Text(
                        Session.name.isNotEmpty ? Session.name[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 36),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton.filled(
                  onPressed: pickPhoto,
                  style: IconButton.styleFrom(backgroundColor: AppColors.green),
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: Session.language == 'nl' ? 'nl' : 'en',
          decoration: InputDecoration(labelText: S.t('language')),
          items: [
            DropdownMenuItem(value: 'en', child: Text(S.t('english'))),
            DropdownMenuItem(value: 'nl', child: Text(S.t('dutch'))),
          ],
          onChanged: (value) => setState(() => Session.language = value ?? 'en'),
        ),
        const SizedBox(height: 12),
        TextField(controller: name, decoration: InputDecoration(labelText: S.t('name'))),
        const SizedBox(height: 12),
        TextField(controller: city, decoration: InputDecoration(labelText: S.t('city'))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: gender,
          decoration: InputDecoration(labelText: S.t('gender')),
          items: [
            DropdownMenuItem(value: 'female', child: Text(S.t('female'))),
            DropdownMenuItem(value: 'male', child: Text(S.t('male'))),
            DropdownMenuItem(value: 'other', child: Text(S.t('other'))),
            DropdownMenuItem(value: 'prefer_not', child: Text(S.t('preferNot'))),
          ],
          onChanged: (value) => setState(() => gender = value ?? 'prefer_not'),
        ),
        const SizedBox(height: 12),
        InputDecorator(
          decoration: InputDecoration(labelText: S.t('ageRule')),
          child: Text(
            Session.age > 0 ? '${Session.age}' : 'Set at registration',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        Text(S.t('skillsOffer'), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'Choose up to 10 categories. Up to 3 may be written as Other. Custom: $customCount/3',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          children: [
            for (final skill in selectedSkills)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8),
                child: InputChip(
                  label: Text(skill),
                  onDeleted: () => setState(() => selectedSkills.remove(skill)),
                ),
              ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: addSkill,
          icon: const Icon(Icons.add),
          label: Text(selectedSkills.length >= 10 ? 'Limit reached' : 'Add a skill'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: saving ? null : save,
            style: AppTheme.solid(AppColors.green),
            child: Text(saving ? S.t('saving') : S.t('save'), style: const TextStyle(color: Colors.white)),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(S.t('darkMode')),
          value: Session.themeMode.value == ThemeMode.dark,
          onChanged: (value) {
            Session.themeMode.value = value ? ThemeMode.dark : ThemeMode.light;
            setState(() {});
          },
        ),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedScreen()));
          },
          child: Text(S.t('blocked')),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsScreen()));
          },
          child: Text(S.t('terms')),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
          },
          child: Text(S.t('support')),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: OutlinedButton(onPressed: logout, child: Text(S.t('logOut'))),
        ),
      ],
    );
  }
}