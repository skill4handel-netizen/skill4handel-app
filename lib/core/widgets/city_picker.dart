import 'package:flutter/material.dart';
import '../constants/cities.dart';
import '../l10n/app_strings.dart';

class CityPicker extends StatefulWidget {
  const CityPicker({super.key, required this.controller, this.label = 'City'});

  final TextEditingController controller;
  final String label;

  @override
  State<CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<CityPicker> {
  List<String> suggestions = [];
  bool open = false;

  void search(String value) {
    final list = filterCities(value);
    setState(() {
      suggestions = list;
      open = list.isNotEmpty;
    });
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
            helperText: S.t('cityHint'),
          ),
          onTap: () => search(widget.controller.text),
          onChanged: search,
        ),
        if (open)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final city in suggestions)
                  ListTile(
                    dense: true,
                    title: Text(city),
                    onTap: () {
                      widget.controller.text = city.contains(',')
                          ? city.split(',').first.trim()
                          : city;
                      setState(() => open = false);
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
