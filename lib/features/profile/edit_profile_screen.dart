import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final nameController = TextEditingController(text: Session.name);
  final cityController = TextEditingController(text: Session.city);
  final offersController = TextEditingController(text: Session.offers);
  final needsController = TextEditingController(text: Session.needs);
  final dio = Api.client;
  bool loading = false;
  String error = '';

  Future<void> save() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final response = await dio.post(
        '/auth/profile',
        data: {
          'id': Session.id,
          'name': nameController.text.trim(),
          'city': cityController.text.trim(),
          'offers': offersController.text.trim(),
          'needs': needsController.text.trim(),
        },
      );
      final user = response.data['user'];
      Session.name = user['name']?.toString() ?? Session.name;
      Session.city = user['city']?.toString() ?? '';
      Session.offers = user['offers']?.toString() ?? '';
      Session.needs = user['needs']?.toString() ?? '';
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        error = 'Could not save profile.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.t('editProfile'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: S.t('fullName'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: S.t('city'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: offersController,
                decoration: InputDecoration(
                  labelText: S.t('skillsOffer'),
                  hintText: S.t('skillsShareHint'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: needsController,
                decoration: InputDecoration(
                  labelText: S.t('skillsNeed'),
                  border: const OutlineInputBorder(),
                ),
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(error, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: loading ? null : save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(loading ? S.t('pleaseWait') : S.t('save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
