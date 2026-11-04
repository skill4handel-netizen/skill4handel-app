import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/session.dart';
import '../../core/constants/skill_items.dart';
import '../../core/constants/skills.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/skill_labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/skill_picker.dart';
import '../../core/widgets/city_picker.dart';
import '../auth/login_screen.dart';
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
  final dio = Api.client;
  late final name = TextEditingController(
    text: Session.name.isNotEmpty ? Session.name : (widget.userName ?? ''),
  );
  late final city = TextEditingController(text: Session.city);
  late final phone = TextEditingController(text: Session.phone);
  bool accessibility = Session.accessibility;
  bool willingVolunteer = Session.willingVolunteer;
  int? day;
  int? month;
  int? year;
  final months = const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  late final bio = TextEditingController(
    text: Session.bio.isNotEmpty ? Session.bio : Session.needs,
  );
  String gender = Session.gender.isNotEmpty ? Session.gender : 'prefer_not';
  late List<SkillItem> selectedSkills = parseSkills(Session.offers);
  bool saving = false;
  bool dirty = false;
  bool editing = false;
  String baseline = '';

  String snapshot() => [name.text.trim(), city.text.trim(), bio.text.trim(), phone.text.trim(), gender, Session.language, encodeSkills(selectedSkills), Session.photoUrl, accessibility, willingVolunteer, day, month, year].join('|');


  int get customCount =>
      selectedSkills.where((item) => !allowedSkills.contains(item.name)).length;

  @override
  void initState() {
    super.initState();
    final birth = DateTime.tryParse(Session.birthDate);
    if (birth != null) {
      day = birth.day;
      month = birth.month;
      year = birth.year;
    }
    baseline = snapshot();
    for (final c in [name, city, bio, phone]) {
      c.addListener(() => setState(() => dirty = snapshot() != baseline));
    }
  }

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
    if (mounted) setState(() => dirty = snapshot() != baseline);
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
    setState(() { selectedSkills.add(SkillItem(name: chosen, note: note)); dirty = snapshot() != baseline; });
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
          'phone': phone.text.trim(),
          'accessibility': accessibility,
          'willingVolunteer': willingVolunteer,
          'offers': encoded,
          'needs': bio.text.trim(),
          'gender': gender,
          'age': year == null ? Session.age : DateTime.now().year - year!,
          'birthDate': year == null ? null : DateTime(year!, month ?? 1, day ?? 1).toIso8601String(),
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
      Session.city = city.text.trim();
      Session.phone = phone.text.trim();
      Session.accessibility = accessibility;
      Session.willingVolunteer = willingVolunteer;
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

  Future<void> setPassword() async {
    final next = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set a password'),
        content: TextField(
          controller: next,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(S.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(S.t('save'))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await dio.post('/auth/set-password', data: {'userId': Session.id, 'newPassword': next.text});
      Session.passwordSet = true;
      await Session.save();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password saved. You can now sign in with your email and this password.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
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

  Future<void> deleteAccount() async {
    final password = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.t('deleteAccount')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.t('deleteAccountBody')),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(labelText: S.t('password')),
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
              child: Text(S.t('deleteAccount')),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    try {
      await dio.delete('/auth/account', data: {'password': password.text});
      if (!mounted) return;
      await Session.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is DioException
          ? '${error.response?.data?['message'] ?? S.t('saveError')}'
          : S.t('saveError');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
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
              if (!editing) ...[
                Container(
                  decoration: AppTheme.card(),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: photo != null
                                ? Image(image: photo!, fit: BoxFit.cover)
                                : Container(
                                    color: AppColors.soft,
                                    child: Center(
                                      child: Text(
                                        Session.name.isNotEmpty ? Session.name[0].toUpperCase() : 'U',
                                        style: const TextStyle(fontSize: 72, color: AppColors.blue),
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              child: IconButton(
                                onPressed: () => setState(() => editing = true),
                                icon: const Icon(Icons.edit, color: AppColors.blue, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Session.name.isEmpty ? S.t('profile') : Session.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                            if (Session.city.isNotEmpty) Text(Session.city, style: const TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 10),
                            Text(Session.bio.trim().isEmpty ? S.t('bioHint') : Session.bio),
                            if (selectedSkills.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(S.t('skillsOffer'), style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                children: [
                                  for (final skill in selectedSkills)
                                    Container(
                                      margin: const EdgeInsets.only(right: 8, bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: const Color(0xFFEEE8FF), borderRadius: BorderRadius.circular(20)),
                                      child: Text(skill.name),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => setState(() => editing = true),
                    child: const Text('Edit profile', style: TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
              if (editing) ...[
              Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => setState(() => editing = false), icon: const Icon(Icons.arrow_back), label: const Text('Profile'))),
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              if (Session.accessibility || Session.willingVolunteer)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    if (Session.accessibility)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.accessible, color: AppColors.blue, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Accessibility',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    if (Session.willingVolunteer)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volunteer_activism, color: AppColors.green, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Volunteer',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              if (Session.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${S.t('phoneOptional')}: ${Session.phone}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: Session.language == 'nl' ? 'nl' : 'en',
                decoration: InputDecoration(labelText: S.t('language')),
                items: [
                  DropdownMenuItem(value: 'en', child: Text(S.t('english'))),
                  DropdownMenuItem(value: 'nl', child: Text(S.t('dutch'))),
                ],
                onChanged: (value) =>
                    setState(() { Session.language = value ?? 'en'; dirty = snapshot() != baseline; }),
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
              CityPicker(controller: city, label: S.t('city')),
              const SizedBox(height: 12),
              Text(S.t('dateOfBirth'), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: day,
                      decoration: InputDecoration(labelText: S.t('day')),
                      items: [for (var i = 1; i <= 31; i++) DropdownMenuItem(value: i, child: Text('$i'))],
                      onChanged: (value) => setState(() { day = value; dirty = snapshot() != baseline; }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      initialValue: month,
                      decoration: InputDecoration(labelText: S.t('month')),
                      items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(months[i - 1]))],
                      onChanged: (value) => setState(() { month = value; dirty = snapshot() != baseline; }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: year,
                decoration: InputDecoration(labelText: S.t('year')),
                items: [for (var i = DateTime.now().year - 18; i >= DateTime.now().year - 90; i--) DropdownMenuItem(value: i, child: Text('$i'))],
                onChanged: (value) => setState(() { year = value; dirty = snapshot() != baseline; }),
              ),
              const SizedBox(height: 6),
              const Text('18 years or older', style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: S.t('phoneOptional')),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: accessibility,
                onChanged: (value) => setState(() { accessibility = value ?? false; dirty = snapshot() != baseline; }),
                title: Text(S.t('accessNeed')),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: willingVolunteer,
                onChanged: (value) => setState(() { willingVolunteer = value ?? false; dirty = snapshot() != baseline; }),
                title: const Text('I am willing to offer voluntary help'),
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
                onChanged: (value) => setState(() {
                  gender = value ?? 'prefer_not';
                  dirty = snapshot() != baseline;
                }),
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: InputDecoration(labelText: S.t('age')),
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
                  onPressed: saving || !dirty ? null : save,
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
                onChanged: (value) async {
                  Session.themeMode.value = value ? ThemeMode.dark : ThemeMode.light;
                  await Session.save();
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 8),
              SizedBox(height: 52, child: OutlinedButton(onPressed: Session.passwordSet ? changePassword : setPassword, child: Text(Session.passwordSet ? S.t('changePassword') : 'Set a password'))),
              const SizedBox(height: 8),
              SizedBox(height: 52, child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedScreen())), child: Text(S.t('blocked')))),
              const SizedBox(height: 8),
              SizedBox(height: 52, child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen())), child: Text(S.t('support')))),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: logout,
                  child: Text(S.t('logOut')),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: deleteAccount,
                  child: Text(S.t('deleteAccount')),
                ),
              ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
