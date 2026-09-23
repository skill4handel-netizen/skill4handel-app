import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  static const _storage = FlutterSecureStorage();
  static int id = 0;
  static String name = '';
  static String email = '';
  static String city = '';
  static String bio = '';
  static String offers = '';
  static String needs = '';
  static String photoUrl = '';
  static String gender = '';
  static int age = 0;
  static double rating = 0;
  static num balance = 0;
  static String token = '';
  static String language = 'en';
  static bool emailVerified = false;
  static bool demoSeen = false;
  static List<Map<String, dynamic>> reviews = [];
  static List<Map<String, dynamic>> history = [];
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'city': city,
    'bio': bio,
    'offers': offers,
    'needs': needs,
    'photoUrl': photoUrl.length > 20000 ? '' : photoUrl,
    'gender': gender,
    'age': age,
    'rating': rating,
    'balance': balance,
    'token': token,
    'language': language,
    'emailVerified': emailVerified,
    'demoSeen': demoSeen,
  };

  static String pickText(Map user, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = user[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  static void apply(Map<String, dynamic> user) {
    id = int.tryParse('${user['id'] ?? id}') ?? id;
    name = pickText(user, ['name'], name);
    email = pickText(user, ['email'], email);
    city = pickText(user, ['city'], city);
    final incomingBio = pickText(user, ['bio', 'needs'], '');
    if (incomingBio.isNotEmpty) bio = incomingBio;
    offers = pickText(user, ['offers'], offers);
    needs = pickText(user, ['needs'], needs);
    photoUrl = pickText(user, ['photoUrl', 'photo_url'], photoUrl);
    gender = pickText(user, ['gender'], gender);
    age = int.tryParse('${user['age'] ?? age}') ?? age;
    rating = double.tryParse('${user['rating'] ?? rating}') ?? rating;
    balance = num.tryParse('${user['balance'] ?? balance}') ?? balance;
    if (user['token'] != null) token = user['token'].toString();
    final nextLang = user['language']?.toString();
    if (nextLang == 'nl' || nextLang == 'en') language = nextLang!;
    if (user['emailVerified'] != null) {
      emailVerified =
          user['emailVerified'] == true || user['emailVerified'] == 'true';
    }
    if (user['demoSeen'] != null) {
      demoSeen = user['demoSeen'] == true || user['demoSeen'] == 'true';
    }
    if (user['reviews'] is List) {
      reviews = (user['reviews'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (user['history'] is List) {
      history = (user['history'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    save();
  }

  static Future<void> save() async {
    try {
      await _storage.write(key: 'session', value: jsonEncode(toJson()));
    } catch (_) {}
  }

  static Future<void> load() async {
    final raw = await _storage.read(key: 'session');
    if (raw == null || raw.isEmpty) return;
    try {
      apply(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {}
  }

  static Future<void> clear() async {
    id = 0;
    name = '';
    email = '';
    city = '';
    bio = '';
    offers = '';
    needs = '';
    photoUrl = '';
    gender = '';
    age = 0;
    rating = 0;
    balance = 0;
    token = '';
    language = 'en';
    emailVerified = true;
    demoSeen = false;
    reviews = [];
    history = [];
    await _storage.delete(key: 'session');
  }

  static bool get profileComplete =>
      name.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      photoUrl.trim().isNotEmpty &&
      offers.trim().isNotEmpty;

  static String get profileMissing {
    final missing = <String>[];
    if (name.trim().isEmpty) missing.add('name');
    if (city.trim().isEmpty) missing.add('city');
    if (photoUrl.trim().isEmpty) missing.add('photo');
    if (offers.trim().isEmpty) missing.add('skill');
    return missing.join(', ');
  }
}
