import 'package:dio/dio.dart';
import 'safe_places.dart';

class PlacesService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {'User-Agent': 'Skill4Handel/1.0 (info@skill4handel.com)'},
    connectTimeout: const Duration(seconds: 12),
  ));

  static Future<List<SafePlace>> load(String city) async {
    final place = city.trim().isEmpty ? 'Netherlands' : city.trim();
    final queries = [
      'public library $place',
      'community centre $place',
      'buurthuis $place',
      'park cafe $place',
    ];
    final found = <SafePlace>[];
    final seen = <String>{};
    for (final query in queries) {
      try {
        final response = await _dio.get('/search', queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 2,
        });
        for (final raw in ((response.data as List?) ?? [])) {
          final item = Map<String, dynamic>.from(raw as Map);
          final name = item['display_name']?.toString() ?? '';
          if (name.isEmpty || seen.contains(name)) continue;
          seen.add(name);
          found.add(SafePlace(
            name: (item['name']?.toString().isNotEmpty == true) ? item['name'].toString() : name.split(',').first,
            kind: _kind(query),
            summary: name.split(',').take(3).join(', '),
            details: name,
            address: name,
            photoUrl: _photo(_kind(query)),
            lat: double.tryParse('${item['lat'] ?? ''}'),
            lng: double.tryParse('${item['lon'] ?? ''}'),
          ));
        }
      } catch (_) {}
    }
    if (found.isEmpty) return safePlacesFor(place);
    return found.take(6).toList();
  }

  static String _kind(String query) {
    if (query.contains('library')) return 'Library';
    if (query.contains('park')) return 'Park cafe';
    return 'Community venue';
  }

  static String _photo(String kind) {
    if (kind == 'Library') return 'https://images.unsplash.com/photo-1521587760476-6c12a4b040da?auto=format&fit=crop&w=900&q=70';
    if (kind == 'Park cafe') return 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=900&q=70';
    return 'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&w=900&q=70';
  }
}
