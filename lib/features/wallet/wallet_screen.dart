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
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF4CC84A), Color(0xFF2EA3F2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text('S4H wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  loading ? '...' : '${Session.balance}',
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
                ),
                const Text('tokens', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.card(color: AppColors.cream),
              child: const Column(
                children: [
                  Icon(Icons.toll, size: 42, color: AppColors.gold),
                  SizedBox(height: 8),
                  Text('No transactions yet.', style: TextStyle(color: AppColors.muted)),
                ],
              ),
            )
          else
            ...items.map((item) {
              final row = Map<String, dynamic>.from(item);
              final amount = row['amount']?.toString() ?? '';
              final positive = amount.contains('+') || !(amount.startsWith('-'));
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.card(),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: positive ? AppColors.mint : const Color(0xFFFFE4E0),
                      child: Icon(positive ? Icons.south_west : Icons.north_east, color: positive ? AppColors.green : AppColors.coral),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(row['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text(amount, style: TextStyle(fontWeight: FontWeight.w800, color: positive ? AppColors.green : AppColors.coral)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
