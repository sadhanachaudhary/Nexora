import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../../core/network/socket_service.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(const FlutterSecureStorage());
  service.connect();
  ref.onDispose(() => service.disconnect());
  return service;
});

class MessagesState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final Set<String> typingUsers;
  final bool hasMore;
  final bool isLoadingMore;

  MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.typingUsers = const {},
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  MessagesState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    Set<String>? typingUsers,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      typingUsers: typingUsers ?? this.typingUsers,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final messagesProvider =
    Provider.family<MessagesController, String>((ref, conversationId) {
  final controller = MessagesController(ref, conversationId);
  ref.onDispose(() => controller.dispose());
  return controller;
});

class MessagesController {
  final Ref _ref;
  final String _conversationId;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _reactionSubscription;
  StreamSubscription? _deleteSubscription;
  StreamSubscription? _readSubscription;
  Timer? _typingTimer;

  final state = ValueNotifier<MessagesState>(MessagesState(isLoading: true));

  MessagesController(this._ref, this._conversationId) {
    _init();
  }

  Future<void> _init() async {
    try {
      final repository = _ref.read(chatRepositoryProvider);
      final socketService = _ref.read(socketServiceProvider);

      // Fetch initial messages
      final fetchedMessages = await repository.getMessages(_conversationId);
      state.value = state.value.copyWith(
        messages: fetchedMessages,
        isLoading: false,
        hasMore: fetchedMessages.length == 50,
      );

      // Join socket room & mark room as read
      socketService.joinRoom(_conversationId);
      socketService.sendMarkRead(_conversationId);

      // Listen to incoming messages
      _messageSubscription = socketService.messageStream.listen((data) {
        if (data['conversationId'] == _conversationId) {
          final newMessage = Message.fromJson(data);
          state.value = state.value.copyWith(
            messages: [newMessage, ...state.value.messages],
          );
        }
      });

      // Listen to typing events
      _typingSubscription = socketService.typingStream.listen((data) {
        final userId = data['userId'] as String;
        final isTyping = data['isTyping'] as bool;

        final newTypingUsers = Set<String>.from(state.value.typingUsers);
        if (isTyping) {
          newTypingUsers.add(userId);
        } else {
          newTypingUsers.remove(userId);
        }
        state.value = state.value.copyWith(typingUsers: newTypingUsers);
      });

      // Listen to reactions
      _reactionSubscription = socketService.reactionStream.listen((data) {
        final messageId = data['messageId'] as String?;
        final userId = data['userId'] as String?;
        final emoji = data['emoji'] as String?;

        if (messageId != null && userId != null && emoji != null) {
          _handleReactionEvent(messageId, userId, emoji);
        }
      });

      // Listen to deleted messages
      _deleteSubscription = socketService.deleteStream.listen((data) {
        final messageId = data['messageId'] as String?;
        if (messageId != null) {
          _handleDeleteEvent(messageId);
        }
      });

      // Listen to read receipts
      _readSubscription = socketService.readStream.listen((data) {
        if (data['conversationId'] == _conversationId) {
          _handleReadEvent();
        }
      });
    } catch (e) {
      state.value = state.value.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void _handleReactionEvent(String messageId, String userId, String emoji) {
    final updated = state.value.messages.map((m) {
      if (m.id != messageId) return m;

      final reactions = Map<String, List<String>>.from(m.reactions);
      final currentUsers = List<String>.from(reactions[emoji] ?? []);

      if (currentUsers.contains(userId)) {
        currentUsers.remove(userId);
      } else {
        // Remove user from any other emoji reactions first
        reactions.forEach((k, v) => v.remove(userId));
        currentUsers.add(userId);
      }

      if (currentUsers.isEmpty) {
        reactions.remove(emoji);
      } else {
        reactions[emoji] = currentUsers;
      }

      return m.copyWith(reactions: reactions);
    }).toList();

    state.value = state.value.copyWith(messages: updated);
  }

  void _handleDeleteEvent(String messageId) {
    final updated = state.value.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(
          content: 'This message was deleted',
          deletedAt: DateTime.now(),
        );
      }
      return m;
    }).toList();

    state.value = state.value.copyWith(messages: updated);
  }

  void _handleReadEvent() {
    final updated = state.value.messages.map((m) {
      return m.copyWith(status: 'READ');
    }).toList();

    state.value = state.value.copyWith(messages: updated);
  }

  Future<void> loadMoreMessages() async {
    if (state.value.isLoadingMore ||
        !state.value.hasMore ||
        state.value.messages.isEmpty) {
      return;
    }

    state.value = state.value.copyWith(isLoadingMore: true);
    try {
      final repository = _ref.read(chatRepositoryProvider);
      final lastMessageId = state.value.messages.last.id;
      final moreMessages = await repository.getMessages(
        _conversationId,
        cursor: lastMessageId,
      );

      state.value = state.value.copyWith(
        messages: [...state.value.messages, ...moreMessages],
        isLoadingMore: false,
        hasMore: moreMessages.length == 50,
      );
    } catch (e) {
      state.value = state.value.copyWith(isLoadingMore: false);
    }
  }

  void updateTypingStatus() {
    final socketService = _ref.read(socketServiceProvider);
    socketService.sendTyping(_conversationId, true);

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      socketService.sendTyping(_conversationId, false);
    });
  }

  void sendMessage(String content, {String? replyToId}) {
    final socketService = _ref.read(socketServiceProvider);
    socketService.sendMessage(
      conversationId: _conversationId,
      content: content,
      replyToId: replyToId,
    );
  }

  void sendImageMessage(String attachmentUrl) {
    final socketService = _ref.read(socketServiceProvider);
    socketService.sendImageMessage(
      conversationId: _conversationId,
      attachmentUrl: attachmentUrl,
    );
  }

  void sendVoiceMessage(String audioUrl, int durationSeconds) {
    final socketService = _ref.read(socketServiceProvider);
    socketService.sendMessage(
      conversationId: _conversationId,
      content: '$durationSeconds',
      type: 'VOICE',
      attachmentUrl: audioUrl,
    );
  }

  void sendLocationMessage({
    required double latitude,
    required double longitude,
    String? locationName,
  }) {
    final socketService = _ref.read(socketServiceProvider);
    final locationData = {
      'lat': latitude,
      'lng': longitude,
      'name': locationName ?? 'Current Location',
    };
    socketService.sendMessage(
      conversationId: _conversationId,
      content: jsonEncode(locationData),
      type: 'LOCATION',
    );
  }

  void toggleReaction(String messageId, String emoji, String currentUserId) {
    final socketService = _ref.read(socketServiceProvider);
    socketService.sendReaction(
      conversationId: _conversationId,
      messageId: messageId,
      emoji: emoji,
    );
    // Optimistic local update
    _handleReactionEvent(messageId, currentUserId, emoji);
  }

  void deleteMessage(String messageId) {
    final socketService = _ref.read(socketServiceProvider);
    socketService.sendDeleteMessage(
      conversationId: _conversationId,
      messageId: messageId,
    );
    _handleDeleteEvent(messageId);
  }

  void dispose() {
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _reactionSubscription?.cancel();
    _deleteSubscription?.cancel();
    _readSubscription?.cancel();
    _typingTimer?.cancel();
    _ref.read(socketServiceProvider).leaveRoom(_conversationId);
    state.dispose();
  }
}
