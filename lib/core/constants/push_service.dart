import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'session.dart';

const String kNotifyChannelId = 'skill4handel';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService {
  static final dio = Dio(
    BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'),
  );
  static final local = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      await local.initialize(
        const InitializationSettings(android: androidInit),
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
        );
      });
      await registerToken();
      FirebaseMessaging.instance.onTokenRefresh.listen(saveToken);
    } catch (error) {
      print('PUSH INIT ERROR $error');
    }
  }

  static Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await saveToken(token);
    } catch (error) {
      print('PUSH TOKEN ERROR $error');
    }
  }

  static Future<void> saveToken(String token) async {
    if (Session.id <= 0 || token.isEmpty) return;
    try {
      await dio.post(
        '/auth/device-token',
        data: {'userId': Session.id, 'token': token, 'platform': 'android'},
      );
    } catch (error) {
      print('PUSH SAVE ERROR $error');
    }
  }
}
