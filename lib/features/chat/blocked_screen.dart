import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final response = await dio.get('/auth/blocks', queryParameters: {'userId': Session.id});
      setState(() {
        items = ((response.data as List?) ?? []).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      });
    } catch (_) {
      setState(() => items = []);
    }
  }

  Future<void> unblock(int otherId) async {
    await dio.post('/auth/unblock', data: {'userId': Session.id, 'otherId': otherId});
    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked people')),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (items.isEmpty) const Text('Nobody is blocked.', style: TextStyle(color: AppColors.muted)),
            ...items.map((item) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['name']?.toString() ?? 'User'),
                subtitle: Text(item['email']?.toString() ?? ''),
                trailing: TextButton(
                  onPressed: () => unblock(int.tryParse('${item['id']}') ?? 0),
                  child: const Text('Unblock'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}