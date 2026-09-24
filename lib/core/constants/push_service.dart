import '../api/api_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'session.dart';

const String kNotifyChannelId = 'skill4handel';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushService {
  static final dio = Api.client;
  static final local = FlutterLocalNotificationsPlugin();
  static String lastToken = '';
  static int pendingChatId = 0;
  static VoidCallback? onChatOpened;

  static int chatIdFrom(RemoteMessage message) {
    return int.tryParse('${message.data['chatId'] ?? ''}') ?? 0;
  }

  static void remember(RemoteMessage message) {
    final id = chatIdFrom(message);
    if (id > 0) {
      pendingChatId = id;
      onChatOpened?.call();
    }
  }

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      await Firebase.initializeApp();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await local.initialize(
        const InitializationSettings(android: androidInit),
        onDidReceiveNotificationResponse: (response) {
          final id = int.tryParse(response.payload ?? '') ?? 0;
          if (id > 0) {
            pendingChatId = id;
            onChatOpened?.call();
          }
        },
      );
      const channel = AndroidNotificationChannel(
        kNotifyChannelId,
        'Skill4Handel',
        description: 'Messages and exchange offers',
        importance: Importance.high,
      );
      await local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
      await local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
      FirebaseMessaging.onMessage.listen((message) {
        final title =
            message.notification?.title ??
            message.data['title'] ??
            'Skill4Handel';
        final body = message.notification?.body ?? message.data['body'] ?? '';
        final chatId = chatIdFrom(message);
        local.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              kNotifyChannelId,
              'Skill4Handel',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: chatId > 0 ? '$chatId' : null,
        );
      });
      FirebaseMessaging.onMessageOpenedApp.listen(remember);
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) remember(initial);
      FirebaseMessaging.instance.onTokenRefresh.listen(saveToken);
      await registerToken();
    } catch (error) {
      print('PUSH INIT ERROR $error');
    }
  }

  static Future<void> registerToken() async {
    if (kIsWeb) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await saveToken(token);
      } else if (lastToken.isNotEmpty) {
        await saveToken(lastToken);
      }
    } catch (error) {
      print('PUSH TOKEN ERROR $error');
    }
  }

  static Future<void> saveToken(String token) async {
    lastToken = token;
    if (Session.id <= 0 || token.isEmpty) return;
    try {
      await dio.post(
        '/auth/device-token',
        data: {
          'userId': Session.id,
          'token': token,
          'platform': kIsWeb ? 'web' : 'android',
        },
      );
    } catch (error) {
      print('PUSH SAVE ERROR $error');
    }
  }
}
