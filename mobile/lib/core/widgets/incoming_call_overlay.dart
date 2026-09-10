import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../../features/chat/presentation/providers/messages_provider.dart';
import 'app_avatar.dart';

class IncomingCallData {
  final String callerId;
  final String callerName;
  final String? callerAvatar;
  final String conversationId;
  final bool isVideo;

  IncomingCallData({
    required this.callerId,
    required this.callerName,
    this.callerAvatar,
    required this.conversationId,
    this.isVideo = false,
  });

  factory IncomingCallData.fromJson(Map<String, dynamic> json) {
    return IncomingCallData(
      callerId: json['callerId'] as String? ?? '',
      callerName: json['callerName'] as String? ?? 'Contact',
      callerAvatar: json['callerAvatar'] as String?,
      conversationId: json['conversationId'] as String? ?? '',
      isVideo: json['isVideo'] as bool? ?? false,
    );
  }
}

class IncomingCallOverlay extends ConsumerStatefulWidget {
  final IncomingCallData callData;
  final VoidCallback onDismiss;

  const IncomingCallOverlay({
    super.key,
    required this.callData,
    required this.onDismiss,
  });

  @override
  ConsumerState<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends ConsumerState<IncomingCallOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _ringTimeoutTimer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Auto dismiss after 30 seconds if unanswered
    _ringTimeoutTimer = Timer(const Duration(seconds: 30), () {
      _declineCall();
    });
  }

  void _declineCall() {
    _ringTimeoutTimer?.cancel();
    final socketService = ref.read(socketServiceProvider);
    socketService.sendEndCall(
      conversationId: widget.callData.conversationId,
      targetUserId: widget.callData.callerId,
    );
    widget.onDismiss();
  }

  void _acceptCall() {
    _ringTimeoutTimer?.cancel();
    widget.onDismiss();
    context.push(
      '/call',
      extra: {
        'conversationId': widget.callData.conversationId,
        'name': widget.callData.callerName,
        'avatarUrl': widget.callData.callerAvatar,
        'isVideo': widget.callData.isVideo,
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 12,
      right: 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.surfaceDark.withValues(alpha: 0.98)
                : Colors.white.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.primaryLight.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryLight.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              // Pulsing Avatar
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: EdgeInsets.all(3 + (_pulseController.value * 3)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLight
                          .withValues(alpha: 0.15 * _pulseController.value),
                    ),
                    child: AppAvatar(
                      avatarUrl: widget.callData.callerAvatar,
                      name: widget.callData.callerName,
                      size: 48,
                      fontSize: 18,
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),

              // Caller Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.callData.callerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: isDark
                            ? AppTheme.textPrimDark
                            : AppTheme.textPrimLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          widget.callData.isVideo
                              ? Icons.videocam_rounded
                              : Icons.call_rounded,
                          size: 14,
                          color: AppTheme.secondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.callData.isVideo
                              ? 'Incoming Video Call...'
                              : 'Incoming Audio Call...',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action Buttons: Decline (Red) & Accept (Green)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decline
                  IconButton.filled(
                    onPressed: _declineCall,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(42, 42),
                    ),
                    icon: const Icon(Icons.call_end_rounded, size: 20),
                    tooltip: 'Decline',
                  ),
                  const SizedBox(width: 8),
                  // Accept
                  IconButton.filled(
                    onPressed: _acceptCall,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(42, 42),
                    ),
                    icon: Icon(
                      widget.callData.isVideo
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      size: 20,
                    ),
                    tooltip: 'Accept',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
