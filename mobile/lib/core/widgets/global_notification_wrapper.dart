import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/in_app_notification.dart';
import '../services/notification_service.dart';
import 'in_app_notification_overlay.dart';
import 'incoming_call_overlay.dart';

class GlobalNotificationWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalNotificationWrapper({super.key, required this.child});

  @override
  ConsumerState<GlobalNotificationWrapper> createState() =>
      _GlobalNotificationWrapperState();
}

class _GlobalNotificationWrapperState
    extends ConsumerState<GlobalNotificationWrapper> {
  InAppNotificationItem? _currentNotification;
  IncomingCallData? _currentCall;

  @override
  Widget build(BuildContext context) {
    // Listen to incoming notifications
    ref.listen<InAppNotificationItem?>(
      inAppNotificationProvider,
      (previous, next) {
        if (next != null) {
          setState(() {
            _currentNotification = next;
          });
        }
      },
    );

    // Listen to incoming calls
    ref.listen<Map<String, dynamic>?>(
      incomingCallProvider,
      (previous, next) {
        setState(() {
          _currentCall = next != null ? IncomingCallData.fromJson(next) : null;
        });
      },
    );

    return Stack(
      children: [
        widget.child,
        if (_currentCall != null)
          IncomingCallOverlay(
            key: ValueKey('${_currentCall!.callerId}_${_currentCall!.conversationId}'),
            callData: _currentCall!,
            onDismiss: () {
              if (mounted) {
                ref.read(incomingCallProvider.notifier).clear();
                setState(() {
                  _currentCall = null;
                });
              }
            },
          )
        else if (_currentNotification != null)
          InAppNotificationBanner(
            key: ValueKey(_currentNotification!.id),
            notification: _currentNotification!,
            onDismiss: () {
              if (mounted) {
                ref.read(inAppNotificationProvider.notifier).clear();
                setState(() {
                  _currentNotification = null;
                });
              }
            },
          ),
      ],
    );
  }
}

