import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../chat/data/repositories/user_repository.dart';
import '../../../chat/presentation/providers/conversations_provider.dart';

const secureStorage = FlutterSecureStorage();

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  AuthState({this.isLoading = false, this.isAuthenticated = false, this.error});
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkAuth();
    return AuthState();
  }

  Future<void> _checkAuth() async {
    final token = await secureStorage.read(key: 'jwt_token');
    if (token == null) return;

    // Verify the token is still valid against the server
    try {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3001/api'));
      dio.options.headers['Authorization'] = 'Bearer $token';
      await dio.get('/users/me');
      // Token is valid
      state = AuthState(isAuthenticated: true);
    } catch (e) {
      // Token invalid or user deleted — force re-login
      await secureStorage.delete(key: 'jwt_token');
      state = AuthState(isAuthenticated: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.login(email, password);
      await secureStorage.write(key: 'jwt_token', value: response['token']);
      // Clear any cached data from a previous session
      _clearUserCache();
      state = AuthState(isAuthenticated: true);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> register(String username, String email, String password, String name) async {
    state = AuthState(isLoading: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final response = await repository.register(username, email, password, name);
      await secureStorage.write(key: 'jwt_token', value: response['token']);
      state = AuthState(isAuthenticated: true);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'jwt_token');
    _clearUserCache();
    state = AuthState();
  }

  void _clearUserCache() {
    // Invalidate all providers that cache user-specific data
    // so the next user gets fresh data, not the previous user's
    ref.invalidate(conversationsProvider);
    ref.invalidate(currentUserProvider);
  }
}
