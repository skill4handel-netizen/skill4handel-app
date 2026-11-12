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

void openPhoto(BuildContext context, String? url) {
  final image = userPhoto(url);
  if (image == null) return;
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: InteractiveViewer(child: Image(image: image, fit: BoxFit.contain)),
    ),
  );
}

class UserPhoto extends StatelessWidget {
  const UserPhoto({
    super.key,
    required this.url,
    this.radius = 24,
    this.letter = '?',
    this.onTap,
  });

  final String? url;
  final double radius;
  final String letter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final image = userPhoto(url);
    return GestureDetector(
      onTap: onTap ?? () => openPhoto(context, url),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFD7EBFF),
        backgroundImage: image,
        child: image == null
            ? Text(letter.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800))
            : null,
      ),
    );
  }
}
