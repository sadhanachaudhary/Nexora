import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/in_app_notification.dart';
import '../network/socket_service.dart';
import '../../features/chat/presentation/providers/messages_provider.dart';
import '../../features/chat/data/repositories/user_repository.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Notifier to track which conversation is currently active on screen
class ActiveConversationNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setActive(String? conversationId) {
    state = conversationId;
  }
}

final activeConversationIdProvider =
    NotifierProvider<ActiveConversationNotifier, String?>(
  ActiveConversationNotifier.new,
);

/// Notifier for in-app floating banner queue
class InAppNotificationNotifier extends Notifier<InAppNotificationItem?> {
  StreamSubscription? _sub1;
  StreamSubscription? _sub2;

  @override
  InAppNotificationItem? build() {
    final socketService = ref.watch(socketServiceProvider);
    final authState = ref.watch(authProvider);

    _sub1?.cancel();
    _sub2?.cancel();

    if (authState.isAuthenticated) {
      _sub1 = socketService.notificationStream.listen(_handleData);
      _sub2 = socketService.messageStream.listen(_handleData);
    }

    ref.onDispose(() {
      _sub1?.cancel();
      _sub2?.cancel();
    });

    return null;
  }

  void _handleData(Map<String, dynamic> data) {
    try {
      final notification = InAppNotificationItem.fromSocketData(data);
      final activeConvId = ref.read(activeConversationIdProvider);
      final currentUserAsync = ref.read(currentUserProvider);
      final currentUserId = currentUserAsync.when(
        data: (u) => u.id,
        loading: () => null,
        error: (_, __) => null,
      );

      final messageData = (data['message'] as Map<String, dynamic>?) ?? data;
      final senderId = (messageData['senderId'] as String?) ??
          (messageData['sender']?['id'] as String?);

      // Do not notify if:
      // 1. Sent by self
      if (senderId != null && currentUserId != null && senderId == currentUserId) {
        return;
      }

      // 2. Currently actively viewing this conversation
      if (activeConvId != null &&
          activeConvId.isNotEmpty &&
          activeConvId == notification.conversationId) {
        return;
      }

      state = notification;
    } catch (_) {
      // Ignore malformed payloads
    }
  }

  void clear() {
    state = null;
  }
}

final inAppNotificationProvider =
    NotifierProvider<InAppNotificationNotifier, InAppNotificationItem?>(
  InAppNotificationNotifier.new,
);

/// Notifier for incoming audio/video call alerts
class IncomingCallNotifier extends Notifier<Map<String, dynamic>?> {
  StreamSubscription? _callSub;

  @override
  Map<String, dynamic>? build() {
    final socketService = ref.watch(socketServiceProvider);
    final authState = ref.watch(authProvider);

    _callSub?.cancel();

    if (authState.isAuthenticated) {
      _callSub = socketService.callStream.listen((data) {
        final event = data['event'] as String?;
        if (event == 'incomingCall') {
          state = data;
        } else if (event == 'callEnded') {
          state = null;
        }
      });
    }

    ref.onDispose(() {
      _callSub?.cancel();
    });

    return null;
  }

  void clear() {
    state = null;
  }
}

final incomingCallProvider =
    NotifierProvider<IncomingCallNotifier, Map<String, dynamic>?>(
  IncomingCallNotifier.new,
);


