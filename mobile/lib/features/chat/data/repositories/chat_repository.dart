import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';

final chatRepositoryProvider = Provider((ref) {
  return ChatRepository(ref.watch(dioProvider));
});

class ChatRepository {
  final Dio _dio;

  ChatRepository(this._dio);

  Future<List<Conversation>> getConversations() async {
    final response = await _dio.get('/conversations');
    final data = response.data as List;
    return data.map((json) => Conversation.fromJson(json)).toList();
  }

  Future<List<Message>> getMessages(String conversationId, {String? cursor}) async {
    final queryParameters = <String, dynamic>{
      'limit': 50,
      if (cursor != null) 'cursor': cursor,
    };
    
    final response = await _dio.get('/messages/$conversationId', queryParameters: queryParameters);
    final data = response.data as List;
    return data.map((json) => Message.fromJson(json)).toList();
  }

  Future<Message> sendMessage(String conversationId, String content) async {
    final response = await _dio.post('/messages/$conversationId', data: {
      'content': content,
    });
    return Message.fromJson(response.data);
  }

  Future<Conversation> createDirectConversation(String targetUserId) async {
    final response = await _dio.post('/conversations/direct', data: {
      'targetUserId': targetUserId,
    });
    return Conversation.fromJson(response.data);
  }

  Future<Conversation> createDirectConversationByEmail(String email) async {
    final response = await _dio.post('/conversations/direct', data: {
      'email': email.trim().toLowerCase(),
    });
    return Conversation.fromJson(response.data);
  }

  Future<Conversation> createGroupConversation(String name, List<String> memberIds) async {
    final response = await _dio.post('/conversations/group', data: {
      'name': name.trim(),
      'memberIds': memberIds,
    });
    return Conversation.fromJson(response.data);
  }
}
