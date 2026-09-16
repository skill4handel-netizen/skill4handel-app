import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CityPicker extends StatefulWidget {
  const CityPicker({super.key, required this.controller, this.label = 'City'});

  final TextEditingController controller;
  final String label;

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {'User-Agent': 'Skill4Handel/1.0 (info@skill4handel.com)'},
  ));
  Timer? timer;
  List<String> suggestions = [];
  bool open = false;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> search(String value) async {
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        suggestions = [];
        open = false;
      });
      return;
    }
    try {
      final response = await dio.get('/search', queryParameters: {
        'q': q,
        'format': 'json',
        'addressdetails': 1,
        'limit': 6,
        'featuretype': 'city',
      });
      final items = <String>{};
      for (final raw in ((response.data as List?) ?? [])) {
        final map = Map<String, dynamic>.from(raw as Map);
        final address = map['address'] is Map ? Map<String, dynamic>.from(map['address'] as Map) : {};
        final city = (address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? map['name'] ?? '').toString().trim();
        final country = (address['country'] ?? '').toString();
        if (city.isEmpty) continue;
        items.add(country.isEmpty ? city : '$city, $country');
      }
      if (!mounted) return;
      setState(() {
        suggestions = items.toList();
        open = suggestions.isNotEmpty;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: const Icon(Icons.location_city, size: 28),
            suffixIcon: const Icon(Icons.map_outlined),
            helperText: 'Start typing. Choose a city from the list.',
          ),
          onChanged: (value) {
            timer?.cancel();
            timer = Timer(const Duration(milliseconds: 400), () => search(value));
          },
        ),
        if (open)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            decoration: AppTheme.card(),
            child: Column(
              children: [
                for (final item in suggestions)
                  ListTile(
                    leading: const Icon(Icons.place, color: AppColors.blue),
                    title: Text(item),
                    onTap: () {
                      widget.controller.text = item.split(',').first.trim();
                      setState(() {
                        open = false;
                        suggestions = [];
                      });
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
