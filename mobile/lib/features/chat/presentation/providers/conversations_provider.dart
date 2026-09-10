import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/conversation.dart';
import '../../data/repositories/chat_repository.dart';

final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getConversations();
});
