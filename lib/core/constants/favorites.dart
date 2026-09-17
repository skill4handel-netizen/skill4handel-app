import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'session.dart';

class Favorites {
  static const _storage = FlutterSecureStorage();

  static String get _key => 'favorite_ids_${Session.id}';

  static Future<List<int>> ids() async {
    if (Session.id == 0) return [];
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').map((item) => int.tryParse(item) ?? 0).where((item) => item > 0).toList();
  }

  static Future<bool> has(int id) async {
    if (id == 0) return false;
    return (await ids()).contains(id);
  }

  static Future<bool> toggle(int id) async {
    if (id == 0 || Session.id == 0) return false;
    final current = await ids();
    if (current.contains(id)) {
      current.remove(id);
      await _storage.write(key: _key, value: current.join(','));
      return false;
    }
    current.add(id);
    await _storage.write(key: _key, value: current.join(','));
    return true;
  }
}
