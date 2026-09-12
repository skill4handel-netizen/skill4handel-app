import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../home/demo_screen.dart';
import 'terms_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  DateTime? birthDate;
  bool accepted = false;
  bool showPass = false;
  bool showConfirm = false;
  bool loading = false;

  int? ageFromBirth() {
    final date = birthDate;
    if (date == null) return null;
    final now = DateTime.now();
    var age = now.year - date.year;
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
      age -= 1;
    }
    return age;
  }

  String birthLabel() {
    final date = birthDate;
    if (date == null) return 'Date of birth';
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> pickBirthDate() async {
    final now = DateTime.now();
    final last = DateTime(now.year - 18, now.month, now.day);
    final first = DateTime(now.year - 100, 1, 1);
    final selected = await showDatePicker(
      context: context,
      initialDate: birthDate ?? last,
      firstDate: first,
      lastDate: last,
      helpText: 'Date of birth',
    );
    if (selected != null) setState(() => birthDate = selected);
  }

  Future<void> signup() async {
    final age = ageFromBirth();
    if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all fields.')));
      return;
    }
    if (password.text != confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The passwords do not match.')));
      return;
    }
    if (password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The password must contain at least 6 characters.')));
      return;
    }
    if (birthDate == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your date of birth.')));
      return;
    }
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Members must be 18 years of age or older.')));
      return;
    }
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the terms to create an account.')));
      return;
    }
    setState(() => loading = true);
    try {
      final response = await dio.post('/auth/signup', data: {
        'name': name.text.trim(),
        'email': email.text.trim(),
        'password': password.text,
        'age': age,
        'birthDate': birthDate!.toIso8601String(),
        'acceptedTerms': true,
      });
      Session.apply(Map<String, dynamic>.from(response.data['user'] as Map));
      if (response.data['token'] != null) Session.token = response.data['token'].toString();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DemoScreen(userName: Session.name)),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The account could not be created.')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration field(String emoji, String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: '$emoji  $label',
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('🤝', textAlign: TextAlign.center, style: TextStyle(fontSize: 42)),
          const SizedBox(height: 8),
          const Text(
            'Share what you know. Get what you need.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'A simple way to exchange skills without money.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          TextField(controller: name, decoration: field('👤', 'Name')),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: field('✉️', 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: !showPass,
            decoration: field(
              '🔑',
              'Password',
              suffix: IconButton(
                onPressed: () => setState(() => showPass = !showPass),
                icon: Icon(showPass ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirm,
            obscureText: !showConfirm,
            decoration: field(
              '🔐',
              'Confirm password',
              suffix: IconButton(
                onPressed: () => setState(() => showConfirm = !showConfirm),
                icon: Icon(showConfirm ? Icons.visibility_off : Icons.visibility),
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: pickBirthDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '📅  Date of birth',
                helperText: '18 years or older',
                suffixIcon: Icon(Icons.calendar_month),
              ),
              child: Text(
                birthDate == null ? 'Select date' : birthLabel(),
                style: TextStyle(
                  fontSize: 16,
                  color: birthDate == null ? AppColors.muted : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: accepted,
            onChanged: (value) => setState(() => accepted = value ?? false),
            title: const Text('I have read and accept the terms and community rules.'),
            secondary: const Text('📜', style: TextStyle(fontSize: 22)),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsScreen()));
            },
            child: const Text('Read the terms'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : signup,
              style: AppTheme.solid(AppColors.green),
              child: Text(loading ? 'Creating account…' : 'Create account', style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}