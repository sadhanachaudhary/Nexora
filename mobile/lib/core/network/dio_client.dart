import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const secureStorage = FlutterSecureStorage();

final dioProvider = Provider<Dio>((ref) {
  // Use 10.0.2.2 for Android emulator, 127.0.0.1 for iOS simulator / Web
  final dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:3001/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await secureStorage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Token is invalid or expired — clear it so the router redirects to /login
          await secureStorage.delete(key: 'jwt_token');
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
