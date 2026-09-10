import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/user.dart';

final userRepositoryProvider = Provider((ref) {
  return UserRepository(ref.watch(dioProvider));
});

final currentUserProvider = FutureProvider<User>((ref) {
  return ref.read(userRepositoryProvider).getMe();
});

class UserRepository {
  final Dio _dio;

  UserRepository(this._dio);

  Future<List<User>> searchUsers(String query) async {
    final response = await _dio.get('/users', queryParameters: {'search': query});
    final data = response.data as List;
    return data.map((json) => User.fromJson(json)).toList();
  }

  Future<User> getMe() async {
    final response = await _dio.get('/users/me');
    return User.fromJson(response.data);
  }

  Future<User> updateProfile({String? name, String? bio, String? avatarUrl}) async {
    final response = await _dio.put('/users/me', data: {
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
    return User.fromJson(response.data);
  }
}
