import 'package:dio/dio.dart';
import '../constants/session.dart';

class Api {
  static const baseUrl = 'https://skill4handel-api.onrender.com';

  static final Dio client =
      Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: {'Content-Type': 'application/json'},
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 20),
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              final token = Session.token.trim();
              if (token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              return handler.next(options);
            },
          ),
        );
}
