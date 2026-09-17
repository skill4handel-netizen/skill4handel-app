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
        'photoUrl': photoUrl,
        'gender': gender,
        'age': age,
        'rating': rating,
        'balance': balance,
        'token': token,
        'language': language,
      };

  static void apply(Map<String, dynamic> user) {
    id = int.tryParse('${user['id'] ?? id}') ?? id;
    name = user['name']?.toString() ?? name;
    email = user['email']?.toString() ?? email;
    city = user['city']?.toString() ?? city;
    final incomingBio = user['bio']?.toString() ?? user['needs']?.toString();
    if (incomingBio != null && incomingBio.trim().isNotEmpty) bio = incomingBio;
    offers = user['offers']?.toString() ?? offers;
    needs = user['needs']?.toString() ?? needs;
    photoUrl = user['photoUrl']?.toString() ?? photoUrl;
    gender = user['gender']?.toString() ?? gender;
    age = int.tryParse('${user['age'] ?? age}') ?? age;
    rating = double.tryParse('${user['rating'] ?? rating}') ?? rating;
    balance = num.tryParse('${user['balance'] ?? balance}') ?? balance;
    if (user['token'] != null) token = user['token'].toString();
    final nextLang = user['language']?.toString();
    if (nextLang == 'nl' || nextLang == 'en') language = nextLang!;
    if (user['reviews'] is List) {
      reviews = (user['reviews'] as List).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    }
    if (user['history'] is List) {
      history = (user['history'] as List).whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    }
    save();
  }

  static Future<void> save() async {
    await _storage.write(key: 'session', value: jsonEncode(toJson()));
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
    reviews = [];
    history = [];
    await _storage.delete(key: 'session');
  }
}
