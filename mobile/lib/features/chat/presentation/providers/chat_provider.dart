import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getConversations();
});

final chatMessagesProvider = FutureProvider.family<List<Message>, String>((ref, conversationId) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessages(conversationId);
});
