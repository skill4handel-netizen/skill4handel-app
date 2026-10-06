import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_page.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final dio = Api.client;
  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final response = await dio.get('/auth/alerts', queryParameters: {'userId': Session.id});
      items = ((response.data as List?) ?? []).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      items = [];
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> markRead(Map<String, dynamic> item) async {
    try {
      await dio.post('/auth/alerts/read', data: {'id': item['id'], 'userId': Session.id});
    } catch (_) {
      return;
    }
    load();
  }

  String when(dynamic value) {
    final date = DateTime.tryParse('${value ?? ''}');
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.day}/${local.month} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Notifications',
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (loading) const LinearProgressIndicator(),
            if (!loading && items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: AppColors.blue),
                    SizedBox(height: 8),
                    Text('No notifications yet', style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            ...items.map((item) {
              final unread = item['is_read'] != true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: AppTheme.card(color: unread ? AppColors.mint : Colors.white),
                child: ListTile(
                  leading: Icon(unread ? Icons.notifications_active : Icons.notifications_none, color: AppColors.blue),
                  title: Text(item['title']?.toString() ?? 'Notice', style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${when(item['created_at'])}\n${item['body'] ?? ''}'.trim()),
                  isThreeLine: true,
                  onTap: () => markRead(item),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
