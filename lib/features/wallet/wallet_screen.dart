import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadWallet();
  }

  Future<void> loadWallet() async {
    setState(() => loading = true);
    try {
      final response = await dio.get(
        '/auth/me',
        queryParameters: {'userId': Session.id},
        options: Options(headers: {
          if (Session.token.isNotEmpty) 'Authorization': 'Bearer ${Session.token}',
        }),
      );
      final data = response.data;
      final user = data is Map && data['user'] is Map ? data['user'] : data;
      Session.apply(Map<String, dynamic>.from(user as Map));
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final items = Session.history;
    return RefreshIndicator(
      onRefresh: loadWallet,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Wallet', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('S4H balance', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  loading ? '...' : '${Session.balance} S4H',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text('No transactions yet.', style: TextStyle(color: AppColors.muted))
          else
            ...items.map((item) {
              final row = item is Map ? Map<String, dynamic>.from(item) : {'title': item.toString(), 'amount': ''};
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(row['title']?.toString() ?? '')),
                    Text(
                      row['amount']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}