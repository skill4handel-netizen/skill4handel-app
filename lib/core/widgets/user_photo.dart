import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider? userPhoto(String? url) {
  final value = url?.trim() ?? '';
  if (value.isEmpty) return null;
  if (value.startsWith('data:')) {
    try {
      return MemoryImage(base64Decode(value.split(',').last));
    } catch (_) {
      return null;
    }
  }
  return NetworkImage(value);
}

class UserPhoto extends StatelessWidget {
  const UserPhoto({
    super.key,
    required this.url,
    this.radius = 24,
    this.letter = '?',
  });

  final String? url;
  final double radius;
  final String letter;

  @override
  Widget build(BuildContext context) {
    final image = userPhoto(url);
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFD7EBFF),
      backgroundImage: image,
      child: image == null
          ? Text(letter.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800))
          : null,
    );
  }
}