import 'package:dio/dio.dart';

class AuthApi {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://skill4handel-api.onrender.com/',
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/auth/signup',
      data: {'name': name, 'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }
}
