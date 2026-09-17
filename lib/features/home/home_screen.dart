import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/places_service.dart';
import '../../core/constants/safe_places.dart';
import '../../core/constants/session.dart';
import '../../core/constants/skill_items.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/user_photo.dart';
import '../chat/chat_screen.dart';
import '../chat/history_screen.dart';
import '../reviews/review_screen.dart';
import '../support/support_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onSearchTap,
    this.onChatTap,
    this.onWalletTap,
    this.onProfileTap,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onWalletTap;
  final VoidCallback? onProfileTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dio = Dio(BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'));
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> history = [];
  List<SafePlace> places = [];
  int unread = 0;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  bool reviewedByMe(Map item) {
    final reviewedBy = item['reviewedBy'];
    if (reviewedBy is! List) return false;
    return reviewedBy.any((value) => value.toString() == Session.id.toString());
  }

  Future<void> refresh() async {
    try {
      final me = await dio.get('/auth/me', queryParameters: {'userId': Session.id});
      final user = me.data is Map ? (me.data['user'] ?? me.data) : null;
      if (user is Map) Session.apply(Map<String, dynamic>.from(user));
    } catch (_) {}
    try {
      final response = await dio.get('/chats', queryParameters: {'userId': Session.id});
      chats = ((response.data as List?) ?? []).map((item) => Map<String, dynamic>.from(item as Map)).toList();
      unread = chats.where((item) => item['unread'] == true).length;
    } catch (_) {
      chats = [];
      unread = 0;
    }
    try {
      final response = await dio.get('/chats/history', queryParameters: {'userId': Session.id});
      history = ((response.data as List?) ?? []).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } catch (_) {
      history = [];
    }
    try {
      places = await PlacesService.load(Session.city);
    } catch (_) {
      places = safePlacesFor(Session.city);
    }
    if (mounted) setState(() {});
  }

  void showSkill(SkillItem skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(skill.name),
        content: Text(skill.note.isEmpty ? 'No description yet.' : skill.note),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  String today() {
    final now = DateTime.now();
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  List<Map<String, dynamic>> activityItems() {
    final items = <Map<String, dynamic>>[];
    for (final chat in chats) {
      final swap = chat['pendingSwap'];
      final status = swap is Map ? swap['status']?.toString() : '';
      if (chat['unread'] == true) {
        items.add({'title': chat['name'] ?? 'Member', 'reason': 'New message', 'chat': chat});
      }
      if (status == 'pending') {
        final mine = swap['proposedBy']?.toString() == Session.id.toString();
        items.add({
          'title': chat['name'] ?? 'Member',
          'reason': mine ? 'Offer sent. Awaiting a response within 24 hours.' : 'An offer is awaiting your response.',
          'chat': chat,
        });
      } else if (status == 'accepted') {
        items.add({
          'title': chat['name'] ?? 'Member',
          'reason': 'Open session. Confirm completion after the scheduled time.',
          'chat': chat,
        });
      }
    }
    for (final item in history) {
      final status = item['status']?.toString();
      if (status == 'completed' && !reviewedByMe(item)) {
        items.add({'title': item['otherName'] ?? 'Member', 'reason': 'Review pending after a completed exchange.', 'review': item});
      } else if (status == 'cancelled' || status == 'expired') {
        items.add({
          'title': item['otherName'] ?? 'Member',
          'reason': 'The previous offer was closed. Both members may start a new request.',
          'chatId': item['chatId'],
          'otherId': item['otherId'],
          'name': item['otherName'],
        });
      }
    }
    return items;
  }

  void openChatFrom(Map<String, dynamic> item) {
    final chat = item['chat'] as Map?;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          name: (chat?['name'] ?? item['name'] ?? 'Member').toString(),
          otherId: int.tryParse('${chat?['otherId'] ?? item['otherId'] ?? 0}') ?? 0,
          chatId: int.tryParse('${chat?['id'] ?? item['chatId'] ?? 0}'),
          photoUrl: (chat?['photoUrl'] ?? item['photoUrl'] ?? '').toString(),
        ),
      ),
    ).then((_) => refresh());
  }

  Future<void> openMaps(SafePlace place) async {
    final query = place.lat != null ? '${place.lat},${place.lng}' : place.address;
    await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  void showPlace(SafePlace place) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  place.photoUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(height: 120, color: AppColors.soft),
                ),
              ),
              const SizedBox(height: 12),
              Text(place.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(place.kind, style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Suggestion only. Confirm opening hours and that the place is public and suitable before you meet.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Text(place.details),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place, color: AppColors.coral),
                  const SizedBox(width: 6),
                  Expanded(child: Text(place.address, style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => openMaps(place),
                style: AppTheme.solid(AppColors.blue),
                icon: const Icon(Icons.map, color: Colors.white),
                label: const Text('Open in Google Maps', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = Session.photoUrl.trim();
    final image = userPhoto(photo);
    final name = Session.name.isEmpty ? 'there' : Session.name;
    final skills = parseSkills(Session.offers);
    final featured = skills.isEmpty ? null : skills.first;
    final live = activityItems();
    final bottom = MediaQuery.of(context).padding.bottom + 24;

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, $name', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                      Text(today(), style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(onPressed: refresh, icon: const Icon(Icons.refresh, color: Colors.white)),
                IconButton(onPressed: widget.onSearchTap, icon: const Icon(Icons.search, color: Colors.white)),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom),
              children: [
                Container(
                  decoration: AppTheme.card(),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3,
                            child: image != null
                                ? Image(image: image, fit: BoxFit.cover)
                                : Container(
                                    color: AppColors.soft,
                                    child: Center(child: Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 72, color: AppColors.blue))),
                                  ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              child: IconButton(
                                onPressed: widget.onProfileTap,
                                icon: const Icon(Icons.edit, color: AppColors.blue, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(Session.name.isEmpty ? 'Your profile' : Session.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                            if (Session.city.isNotEmpty) Text(Session.city, style: const TextStyle(color: AppColors.muted)),
                            const SizedBox(height: 10),
                            Text(Session.bio.trim().isEmpty ? 'Add a short bio in Edit profile.' : Session.bio, style: const TextStyle(height: 1.35)),
                            if (skills.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text('Skills offered', style: TextStyle(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              const Text('Tap a skill to read its description.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                              const SizedBox(height: 8),
                              Wrap(
                                children: [
                                  for (final skill in skills)
                                    GestureDetector(
                                      onTap: () => showSkill(skill),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(color: const Color(0xFFEEE8FF), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.purple)),
                                        child: Text(skill.name, style: const TextStyle(color: Color(0xFF3D2BB3), fontWeight: FontWeight.w800)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: stat(Icons.chat_bubble_rounded, '$unread', 'Messages', widget.onChatTap ?? () {}, AppColors.soft, AppColors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: stat(Icons.star_rounded, Session.rating.toStringAsFixed(1), 'Reviews', refresh, AppColors.cream, AppColors.gold)),
                    const SizedBox(width: 8),
                    Expanded(child: stat(Icons.account_balance_wallet_rounded, '${Session.balance}', 'Wallet', widget.onWalletTap ?? () {}, AppColors.mint, AppColors.green)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: actionTile(Icons.search, 'Search', AppColors.blue, widget.onSearchTap ?? () {})),
                    const SizedBox(width: 8),
                    Expanded(child: actionTile(Icons.favorite, 'Favorites', AppColors.coral, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen()));
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: actionTile(Icons.history, 'History', AppColors.purple, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())).then((_) => refresh());
                    })),
                    const SizedBox(width: 8),
                    Expanded(child: actionTile(Icons.support_agent, 'Support', AppColors.green, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
                    })),
                  ],
                ),
                const SizedBox(height: 20),
                Text(Session.city.isEmpty ? 'Suggested meeting places' : 'Suggested meeting places in ${Session.city}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'These are suggestions only. Check the place yourself before you meet.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 196,
                  child: places.isEmpty
                      ? const Center(child: Text('Looking up public places...'))
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final place in places)
                              GestureDetector(
                                onTap: () => showPlace(place),
                                child: Container(
                                  width: 220,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: AppTheme.card(),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.network(
                                        place.photoUrl,
                                        height: 110,
                                        width: 220,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) => Container(height: 110, color: AppColors.soft, child: const Icon(Icons.location_city, color: AppColors.blue, size: 40)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                                            Text(place.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                const Text('Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (live.isEmpty)
                  const Text('No current activity.', style: TextStyle(color: AppColors.muted))
                else
                  ...live.map((item) {
                    return Card(
                      child: ListTile(
                        title: Text(item['title']?.toString() ?? 'Member'),
                        subtitle: Text(item['reason']?.toString() ?? ''),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          if (item['review'] is Map) {
                            final review = item['review'] as Map;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReviewScreen(
                                  otherId: int.tryParse('${review['otherId'] ?? 0}') ?? 0,
                                  otherName: review['otherName']?.toString() ?? 'Member',
                                  skill: review['skillRequested']?.toString() ?? '',
                                ),
                              ),
                            );
                            await refresh();
                            return;
                          }
                          openChatFrom(item);
                        },
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget stat(IconData icon, String value, String label, VoidCallback onTap, Color bg, Color accent) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: accent),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
