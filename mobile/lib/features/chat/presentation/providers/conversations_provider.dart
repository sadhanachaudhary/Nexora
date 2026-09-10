import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/services/notification_service.dart';
import 'messages_provider.dart';

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  StreamSubscription? _notifSub;
  StreamSubscription? _msgSub;
  StreamSubscription? _readSub;

  @override
  Future<List<Conversation>> build() async {
    final repository = ref.watch(chatRepositoryProvider);
    final socketService = ref.watch(socketServiceProvider);

    _notifSub?.cancel();
    _msgSub?.cancel();
    _readSub?.cancel();

    _notifSub = socketService.notificationStream.listen(_handleIncomingData);
    _msgSub = socketService.messageStream.listen(_handleIncomingData);
    _readSub = socketService.readStream.listen((data) {
      final convId = data['conversationId'] as String?;
      if (convId != null) {
        markAsRead(convId);
      }
    });

    ref.onDispose(() {
      _notifSub?.cancel();
      _msgSub?.cancel();
      _readSub?.cancel();
    });

    return repository.getConversations();
  }

  void _handleIncomingData(Map<String, dynamic> data) {
    final currentList = state.value;
    if (currentList == null) return;

    try {
      final messageData = (data['message'] as Map<String, dynamic>?) ?? data;
      final convId = (data['conversationId'] as String?) ??
          (messageData['conversationId'] as String?);
      if (convId == null || convId.isEmpty) return;

      final message = Message.fromJson(messageData);
      final activeConvId = ref.read(activeConversationIdProvider);
      final isCurrentlyActive = activeConvId == convId;

      final existingIndex = currentList.indexWhere((c) => c.id == convId);

      List<Conversation> updatedList = List.from(currentList);
      if (existingIndex >= 0) {
        final existing = updatedList.removeAt(existingIndex);
        final updated = existing.copyWith(
          latestMessage: message,
          updatedAt: DateTime.now(),
          unreadCount: isCurrentlyActive ? 0 : existing.unreadCount + 1,
        );
        updatedList.insert(0, updated);
      } else {
        // If conversation is new, trigger a reload
        ref.invalidateSelf();
        return;
      }

      state = AsyncData(updatedList);
    } catch (_) {}
  }

  void markAsRead(String conversationId) {
    final currentList = state.value;
    if (currentList == null) return;

    final updated = currentList.map((c) {
      if (c.id == conversationId && c.unreadCount > 0) {
        return c.copyWith(unreadCount: 0);
      }
      return c;
    }).toList();

    state = AsyncData(updated);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(chatRepositoryProvider).getConversations());
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);
