import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../auth/terms_screen.dart';
import '../chat/blocked_screen.dart';
import '../support/support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userName});

  final String? userName;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  late final name = TextEditingController(text: Session.name.isNotEmpty ? Session.name : (widget.userName ?? ''));
  late final city = TextEditingController(text: Session.city);
  late final offers = TextEditingController(text: Session.offers);
  late final needs = TextEditingController(text: Session.needs);
  late final age = TextEditingController(text: Session.age > 0 ? '${Session.age}' : '');
  String gender = Session.gender.isNotEmpty ? Session.gender : 'prefer_not';
  bool saving = false;

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
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 45, maxWidth: 600);
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

  Future<void> save() async {
    final parsedAge = int.tryParse(age.text.trim()) ?? 0;
    if (parsedAge > 0 && parsedAge < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skill4Handel is only for users 18 and older.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final response = await dio.post('/auth/profile', data: {
        'id': Session.id,
        'name': name.text,
        'city': city.text,
        'offers': offers.text,
        'needs': needs.text,
        'gender': gender,
        'age': parsedAge,
        'language': Session.language,
      });
      final user = response.data is Map ? response.data['user'] : response.data;
      if (user is Map) Session.apply(Map<String, dynamic>.from(user));
      await Session.save();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.t('saved'))));
      setState(() {});
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
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
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
        TextField(
          controller: age,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: S.t('ageRule')),
        ),
        const SizedBox(height: 12),
        TextField(controller: offers, decoration: InputDecoration(labelText: S.t('skillsOffer'))),
        const SizedBox(height: 12),
        TextField(controller: needs, decoration: InputDecoration(labelText: S.t('skillsNeed'))),
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