import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/city_picker.dart';
import 'terms_screen.dart';
import 'verify_email_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final dio = Dio(
    BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'),
  );
  final name = TextEditingController();
  final city = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  int? year;
  int? month;
  int? day;
  bool accepted = false;
  bool showPass = false;
  bool showConfirm = false;
  bool loading = false;

  DateTime? get birthDate {
    if (year == null || month == null || day == null) return null;
    final last = DateTime(year!, month! + 1, 0).day;
    final safeDay = day! > last ? last : day!;
    return DateTime(year!, month!, safeDay);
  }

  int daysInMonth() {
    if (year == null || month == null) return 31;
    return DateTime(year!, month! + 1, 0).day;
  }

  int? ageFromBirth() {
    final date = birthDate;
    if (date == null) return null;
    final now = DateTime.now();
    var age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day))
      age -= 1;
    return age;
  }

  Future<void> signup() async {
    final age = ageFromBirth();
    if (name.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        password.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('signupFill'))));
      return;
    }
    if (password.text != confirm.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('signupPassMatch'))));
      return;
    }
    if (password.text.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('signupPassLen'))));
      return;
    }
    if (birthDate == null || age == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('signupDob'))));
      return;
    }
    if (age < 18) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('signupAge'))));
      return;
    }
    if (!accepted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('signupTerms'))));
      return;
    }
    setState(() => loading = true);
    try {
      final response = await dio.post(
        '/auth/signup',
        data: {
          'name': name.text.trim(),
          'city': city.text.trim(),
          'email': email.text.trim(),
          'password': password.text,
          'age': age,
          'birthDate': birthDate!.toIso8601String(),
          'language': Session.language,
          'acceptedTerms': true,
        },
      );
      final user = Map<String, dynamic>.from(response.data['user'] as Map);
      Session.apply(user);
      Session.token = '';
      Session.emailVerified = false;
      await Session.save();
      if (!mounted) return;
      final link = (response.data['verifyUrl'] ?? '').toString();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => VerifyEmailScreen(verifyUrl: link),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.t('signupFail'))));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 24;
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('createAccount')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottom),
        children: [
          Text(
            '🤝',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 42),
          ),
          const SizedBox(height: 8),
          Text(
            S.t('welcomeLine1'),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            S.t('welcomeLine2'),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            S.t('welcomeTag'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
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
            decoration: InputDecoration(
              labelText: S.t('name'),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),
          CityPicker(controller: city, label: S.t('city')),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: S.t('email'),
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: !showPass,
            decoration: InputDecoration(
              labelText: S.t('password'),
              prefixIcon: const Icon(Icons.key),
              suffixIcon: IconButton(
                onPressed: () => setState(() => showPass = !showPass),
                icon: Icon(showPass ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirm,
            obscureText: !showConfirm,
            decoration: InputDecoration(
              labelText: S.t('confirmPassword'),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => showConfirm = !showConfirm),
                icon: Icon(
                  showConfirm ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            S.t('dateOfBirth'),
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: day,
                  decoration: InputDecoration(labelText: 'Day'),
                  items: [
                    for (var i = 1; i <= daysInMonth(); i++)
                      DropdownMenuItem(value: i, child: Text('$i')),
                  ],
                  onChanged: (value) => setState(() => day = value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  initialValue: month,
                  decoration: InputDecoration(labelText: 'Month'),
                  items: [
                    for (var i = 1; i <= 12; i++)
                      DropdownMenuItem(value: i, child: Text(months[i - 1])),
                  ],
                  onChanged: (value) => setState(() => month = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: year,
            decoration: InputDecoration(labelText: 'Year'),
            items: [
              for (var i = now.year - 18; i >= now.year - 90; i--)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (value) => setState(() => year = value),
          ),
          const SizedBox(height: 6),
          Text('18 years or older', style: TextStyle(color: AppColors.muted)),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: accepted,
            onChanged: (value) => setState(() => accepted = value ?? false),
            title: Text(S.t('acceptTerms')),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsScreen()),
            ),
            child: Text(S.t('readTerms')),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: loading ? null : signup,
              style: AppTheme.solid(AppColors.green),
              child: Text(
                loading ? S.t('saving') : S.t('createAccount'),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
