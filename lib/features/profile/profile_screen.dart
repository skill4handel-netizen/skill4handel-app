import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/session.dart';
import '../../core/constants/skill_items.dart';
import '../../core/constants/skills.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/skill_labels.dart';
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
  final dio = Dio(
    BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'),
  );
  late final name = TextEditingController(
    text: Session.name.isNotEmpty ? Session.name : (widget.userName ?? ''),
  );
  late final city = TextEditingController(text: Session.city);
  late final bio = TextEditingController(
    text: Session.bio.isNotEmpty ? Session.bio : Session.needs,
  );
  String gender = Session.gender.isNotEmpty ? Session.gender : 'prefer_not';
  late List<SkillItem> selectedSkills = parseSkills(Session.offers);
  bool saving = false;

  int get customCount =>
      selectedSkills.where((item) => !allowedSkills.contains(item.name)).length;

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
              title: Text(S.t('takePhoto')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(S.t('chooseGallery')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 45,
      maxWidth: 600,
    );
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    Session.photoUrl = dataUrl;
    await Session.save();
    if (mounted) setState(() {});
    try {
      final response = await dio.post(
        '/auth/photo',
        data: {'id': Session.id, 'photoUrl': dataUrl},
      );
      final user = response.data is Map ? response.data['user'] : null;
      if (user is Map) {
        final previous = Session.photoUrl;
        Session.apply(Map<String, dynamic>.from(user));
        if (Session.photoUrl.trim().isEmpty) Session.photoUrl = previous;
      }
      if (mounted) {
        setState(() {});
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('photoError'))));
    }
  }

  Future<void> addSkill() async {
    if (selectedSkills.length >= 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('skillLimit'))));
      return;
    }
    final chosen = await pickSkill(
      context,
      alreadySelected: selectedSkills.map((item) => item.name).toList(),
    );
    if (chosen == null || selectedSkills.any((item) => item.name == chosen))
      return;
    final noteController = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(chosen),
        content: TextField(
          controller: noteController,
          maxLength: 100,
          maxLines: 3,
          decoration: InputDecoration(hintText: S.t('skillNoteHint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ''),
            child: Text(S.t('skip')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, noteController.text.trim()),
            child: Text(S.t('save')),
          ),
        ],
      ),
    );
    if (note == null) return;
    setState(() => selectedSkills.add(SkillItem(name: chosen, note: note)));
    Session.offers = encodeSkills(selectedSkills);
    await Session.save();
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      final encoded = encodeSkills(selectedSkills);
      final response = await dio.post(
        '/auth/profile',
        data: {
          'id': Session.id,
          'name': name.text,
          'city': city.text,
          'offers': encoded,
          'needs': bio.text.trim(),
          'gender': gender,
          'age': Session.age,
          'language': Session.language,
        },
      );
      final user = response.data is Map ? response.data['user'] : response.data;
      if (user is Map) {
        Session.apply(Map<String, dynamic>.from(user));
      }
      Session.offers = encoded;
      Session.bio = bio.text.trim();
      Session.needs = bio.text.trim();
      await Session.save();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('saved'))));
      widget.onSaved?.call();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('saveError'))));
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.t('changePassword')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: current,
              obscureText: true,
              decoration: InputDecoration(labelText: S.t('currentPassword')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: next,
              obscureText: true,
              decoration: InputDecoration(labelText: S.t('newPassword')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.t('save')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.post(
        '/auth/change-password',
        data: {
          'userId': Session.id,
          'currentPassword': current.text,
          'newPassword': next.text,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('passwordUpdated'))));
    } catch (e) {
      if (!mounted) return;
      final message = e is DioException && e.response?.data is Map
          ? e.response!.data['message'].toString()
          : S.t('passwordChangeFailed');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
    return Column(
      children: [
        AppHeader(title: S.t('profile'), subtitle: Session.name),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.blue,
                      backgroundImage: photo,
                      child: photo == null
                          ? Text(
                              Session.name.isNotEmpty
                                  ? Session.name[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        onPressed: pickPhoto,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.green,
                        ),
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
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
                onChanged: (value) =>
                    setState(() => Session.language = value ?? 'en'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: name,
                decoration: InputDecoration(labelText: S.t('name')),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(labelText: S.t('email')),
                child: Text(
                  Session.email.isEmpty ? '-' : Session.email,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                Session.emailVerified
                    ? S.t('emailConfirmed')
                    : S.t('verifyBanner'),
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(labelText: S.t('city')),
                child: Text(
                  Session.city.isEmpty ? '-' : Session.city,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                S.t('cityLockedHint'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bio,
                maxLength: 180,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: S.t('bio'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: gender,
                decoration: InputDecoration(labelText: S.t('gender')),
                items: [
                  DropdownMenuItem(value: 'female', child: Text(S.t('female'))),
                  DropdownMenuItem(value: 'male', child: Text(S.t('male'))),
                  DropdownMenuItem(value: 'other', child: Text(S.t('other'))),
                  DropdownMenuItem(
                    value: 'prefer_not',
                    child: Text(S.t('preferNot')),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => gender = value ?? 'prefer_not'),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(labelText: 'Age'),
                child: Text(
                  Session.age > 0 ? '${Session.age}' : S.t('setAtRegistration'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                S.t('skillsOffer'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '${S.t('skillLimit')} ${S.t('skillNoteHint')} $customCount/3',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                children: [
                  for (final skill in selectedSkills)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: InputChip(
                        backgroundColor: const Color(0xFFEEE8FF),
                        side: const BorderSide(color: AppColors.purple),
                        labelStyle: const TextStyle(
                          color: Color(0xFF3D2BB3),
                          fontWeight: FontWeight.w800,
                        ),
                        deleteIconColor: AppColors.purple,
                        label: Text(
                          skill.note.isEmpty
                              ? skill.name
                              : '${skillLabel(skill.name)} •',
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(skillLabel(skill.name)),
                              content: Text(
                                skill.note.isEmpty
                                    ? S.t('noDescription')
                                    : skill.note,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(S.t('close')),
                                ),
                              ],
                            ),
                          );
                        },
                        onDeleted: () =>
                            setState(() => selectedSkills.remove(skill)),
                      ),
                    ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: addSkill,
                icon: const Icon(Icons.add),
                label: Text(
                  selectedSkills.length >= 10
                      ? S.t('limitReached')
                      : S.t('addSkill'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: saving ? null : save,
                  style: AppTheme.solid(AppColors.green),
                  child: Text(
                    saving ? S.t('saving') : S.t('save'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(S.t('darkMode')),
                value: Session.themeMode.value == ThemeMode.dark,
                onChanged: (value) {
                  Session.themeMode.value = value
                      ? ThemeMode.dark
                      : ThemeMode.light;
                  setState(() {});
                },
              ),
              TextButton(
                onPressed: changePassword,
                child: Text(S.t('changePassword')),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BlockedScreen(),
                  ),
                ),
                child: Text(S.t('blocked')),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen()),
                ),
                child: Text(S.t('terms')),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportScreen(),
                  ),
                ),
                child: Text(S.t('support')),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: logout,
                  child: Text(S.t('logOut')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
