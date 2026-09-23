import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/skill_labels.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/user_photo.dart';
import '../profile/user_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  final dio = Api.client;
  List<Map<String, dynamic>> all = [];
  List<Map<String, dynamic>> results = [];

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  bool isOnline(Map person) {
    if (person['online'] == true) return true;
    final raw =
        person['lastSeen'] ?? person['updatedAt'] ?? person['updated_at'];
    final time = DateTime.tryParse(raw?.toString() ?? '');
    return time != null && DateTime.now().difference(time).inMinutes < 15;
  }

  Future<void> loadUsers() async {
    final scores = <String, int>{};
    try {
      final matches = await dio.get(
        '/matches',
        queryParameters: {'userId': Session.id},
      );
      for (final item in ((matches.data as List?) ?? [])) {
        final map = Map<String, dynamic>.from(item as Map);
        scores[map['id'].toString()] =
            int.tryParse('${map['score'] ?? 0}') ?? 0;
      }
    } catch (_) {}
    try {
      final response = await dio.get(
        '/users',
        queryParameters: {'userId': Session.id},
      );
      final users =
          (response.data as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .where((item) => item['id'].toString() != Session.id.toString())
              .map((item) {
                item['score'] = scores[item['id'].toString()] ?? 0;
                return item;
              })
              .toList()
            ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
      setState(() {
        all = users;
        results = users;
      });
    } catch (_) {
      setState(() {
        all = [];
        results = [];
      });
    }
  }

  void search(String value) {
    final q = value.trim().toLowerCase();
    setState(() {
      results = all.where((person) {
        final offers = skillLabel(person['offers']?.toString() ?? '');
        final blob =
            '${person['name']} ${person['city']} ${person['offers']} $offers ${person['needs']}'
                .toLowerCase();
        return q.isEmpty || blob.contains(q);
      }).toList();
    });
  }

  void openProfile(Map person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          name: person['name']?.toString() ?? S.t('user'),
          email: person['email']?.toString() ?? '',
          city: person['city']?.toString() ?? '',
          offers: person['offers']?.toString() ?? '',
          needs: person['needs']?.toString() ?? '',
          otherId: int.tryParse('${person['id'] ?? 0}') ?? 0,
          rating: double.tryParse('${person['rating'] ?? 0}') ?? 0,
          reviews: ((person['reviews'] as List?) ?? [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
          photoUrl: (person['photoUrl'] ?? person['photo_url'] ?? '')
              .toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppHeader(title: S.t('search'), subtitle: S.t('searchHint')),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: [
              TextField(
                controller: controller,
                onChanged: search,
                decoration: InputDecoration(
                  hintText: S.t('searchHint'),
                  prefixIcon: const Icon(Icons.search, color: AppColors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (results.isEmpty)
                Text(
                  S.t('noUsers'),
                  style: const TextStyle(color: AppColors.muted),
                )
              else
                ...results.map((person) {
                  final name = person['name']?.toString() ?? S.t('user');
                  final photo =
                      (person['photoUrl'] ?? person['photo_url'] ?? '')
                          .toString();
                  final city = person['city']?.toString() ?? '';
                  final rating =
                      double.tryParse('${person['rating'] ?? 0}') ?? 0;
                  final score = int.tryParse('${person['score'] ?? 0}') ?? 0;
                  final online = isOnline(person);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: AppTheme.card(),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Stack(
                        children: [
                          UserPhoto(
                            url: photo,
                            radius: 28,
                            letter: name.isNotEmpty ? name[0] : '?',
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: online ? AppColors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Row(
                        children: [
                          if (city.isNotEmpty) ...[
                            const Icon(
                              Icons.place,
                              size: 14,
                              color: AppColors.blue,
                            ),
                            const SizedBox(width: 2),
                            Text(city),
                            const SizedBox(width: 8),
                          ],
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: AppColors.gold,
                          ),
                          Text(rating.toStringAsFixed(1)),
                        ],
                      ),
                      trailing: score > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$score%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.green,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.chevron_right,
                              color: AppColors.purple,
                            ),
                      onTap: () => openProfile(person),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
