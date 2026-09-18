import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'session.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService {
  static final dio = Dio(
    BaseOptions(baseUrl: 'https://skill4handel-api.onrender.com'),
  );

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      await registerToken();
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        saveToken(token);
      });
    } catch (_) {}
  }

  static Future<void> registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await saveToken(token);
    } catch (_) {}
  }

  static Future<void> saveToken(String token) async {
    if (Session.id <= 0 || token.isEmpty) return;
    try {
      await dio.post(
        '/auth/device-token',
        data: {'userId': Session.id, 'token': token, 'platform': 'android'},
      );
    } catch (_) {}
  }
}
