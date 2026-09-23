import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/constants/favorites.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/user_photo.dart';
import '../profile/user_profile_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final dio = Api.client;
  List<Map<String, dynamic>> people = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final liked = await Favorites.ids();
    try {
      final response = await dio.get(
        '/users',
        queryParameters: {'userId': Session.id},
      );
      final users = ((response.data as List?) ?? [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      people = users
          .where(
            (item) => liked.contains(int.tryParse('${item['id'] ?? 0}') ?? 0),
          )
          .toList();
    } catch (_) {
      people = [];
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 24;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('favorites')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
          children: [
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (!loading && people.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.card(color: AppColors.cream),
                child: Text(S.t('noFavoritesYet')),
              ),
            ...people.map((person) {
              final name = person['name']?.toString() ?? S.t('member');
              final photo = (person['photoUrl'] ?? person['photo_url'] ?? '')
                  .toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppTheme.card(),
                child: ListTile(
                  leading: UserPhoto(
                    url: photo,
                    radius: 24,
                    letter: name.isNotEmpty ? name[0] : '?',
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(person['city']?.toString() ?? ''),
                  trailing: const Icon(Icons.favorite, color: AppColors.coral),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(
                          name: name,
                          email: person['email']?.toString() ?? '',
                          city: person['city']?.toString() ?? '',
                          offers: person['offers']?.toString() ?? '',
                          needs: person['needs']?.toString() ?? '',
                          otherId: int.tryParse('${person['id'] ?? 0}') ?? 0,
                          rating:
                              double.tryParse('${person['rating'] ?? 0}') ?? 0,
                          photoUrl: photo,
                        ),
                      ),
                    ).then((_) => load());
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
