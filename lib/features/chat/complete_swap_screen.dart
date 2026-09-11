import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/constants/session.dart';
import '../../core/theme/app_theme.dart';

class CompleteSwapScreen extends StatefulWidget {
  const CompleteSwapScreen({
    super.key,
    required this.otherName,
    required this.chatId,
    this.photoUrl,
  });

  final String otherName;
  final int chatId;
  final String? photoUrl;

  @override
  State<CompleteSwapScreen> createState() => _CompleteSwapScreenState();
}

class _CompleteSwapScreenState extends State<CompleteSwapScreen> {
  final skillRequested = TextEditingController();
  final skillOffered = TextEditingController();
  final extraTokens = TextEditingController(text: '0');
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  String duration = '60';
  String mode = 'online';
  bool payWithTokens = false;
  bool working = false;

  Future<void> submit() async {
    setState(() => working = true);
    try {
      await dio.post('/chats/${widget.chatId}/swap', data: {
        'userId': Session.id,
        'skillRequested': skillRequested.text.trim(),
        'skillOffered': payWithTokens ? '' : skillOffered.text.trim(),
        'payWithTokens': payWithTokens,
        'extraTokens': int.tryParse(extraTokens.text) ?? 0,
        'duration': duration,
        'mode': mode,
      });
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: skillRequested,
            decoration: const InputDecoration(
              labelText: 'Requested skill',
              prefixIcon: Icon(Icons.flag_outlined),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pay with tokens'),
            value: payWithTokens,
            onChanged: (value) => setState(() => payWithTokens = value),
          ),
          if (!payWithTokens)
            TextField(
              controller: skillOffered,
              decoration: const InputDecoration(
                labelText: 'Offered skill',
                prefixIcon: Icon(Icons.handshake_outlined),
              ),
            )
          else
            TextField(
              controller: extraTokens,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tokens',
                prefixIcon: Icon(Icons.token_outlined),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: duration,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.schedule)),
            items: const [
              DropdownMenuItem(value: '30', child: Text('30 min')),
              DropdownMenuItem(value: '60', child: Text('60 min')),
              DropdownMenuItem(value: '90', child: Text('90 min')),
            ],
            onChanged: (value) => setState(() => duration = value ?? '60'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: mode,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.place_outlined)),
            items: const [
              DropdownMenuItem(value: 'online', child: Text('Online')),
              DropdownMenuItem(value: 'in_person', child: Text('In person')),
            ],
            onChanged: (value) => setState(() => mode = value ?? 'online'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: working ? null : submit,
              style: AppTheme.solid(AppColors.green),
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('Send offer', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}