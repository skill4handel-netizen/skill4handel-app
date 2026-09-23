import '../../core/api/api_client.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/theme/app_theme.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  final dio = Api.client;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await dio.get(
        '/auth/blocks',
        queryParameters: {'userId': Session.id},
      );
      setState(() {
        items = ((response.data as List?) ?? [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } catch (_) {
      setState(() => items = []);
    }
  }

  Future<void> unblock(int otherId) async {
    await dio.post(
      '/auth/unblock',
      data: {'userId': Session.id, 'otherId': otherId},
    );
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom + 24;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('blocked')),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
          children: [
            if (items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.card(color: AppColors.soft),
                child: Column(
                  children: [
                    Icon(Icons.block, size: 56, color: AppColors.blue),
                    SizedBox(height: 8),
                    Text(
                      S.t('nobodyBlocked'),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ...items.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppTheme.card(),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.coral,
                    child: Icon(Icons.person_off, color: Colors.white),
                  ),
                  title: Text(
                    item['name']?.toString() ?? S.t('user'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(item['email']?.toString() ?? ''),
                  trailing: TextButton.icon(
                    onPressed: () =>
                        unblock(int.tryParse('${item['id']}') ?? 0),
                    icon: const Icon(Icons.lock_open),
                    label: Text(S.t('unblock')),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
