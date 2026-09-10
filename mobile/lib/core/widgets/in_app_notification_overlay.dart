import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/in_app_notification.dart';
import '../theme/app_theme.dart';
import '../../features/chat/presentation/providers/messages_provider.dart';
import 'app_avatar.dart';

class InAppNotificationBanner extends ConsumerStatefulWidget {
  final InAppNotificationItem notification;
  final VoidCallback onDismiss;

  const InAppNotificationBanner({
    super.key,
    required this.notification,
    required this.onDismiss,
  });

  @override
  ConsumerState<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState
    extends ConsumerState<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  bool _isReplying = false;
  final _replyTextCtrl = TextEditingController();
  final _replyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Tactile haptic feedback
    HapticFeedback.mediumImpact();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 250),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    _startAutoDismissTimer();
  }

  void _startAutoDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(milliseconds: 4800), () {
      if (!_isReplying) {
        _dismissWithAnimation();
      }
    });
  }

  void _dismissWithAnimation() {
    if (!mounted) return;
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  void _sendQuickReply() {
    final text = _replyTextCtrl.text.trim();
    if (text.isEmpty) return;

    final socketService = ref.read(socketServiceProvider);
    socketService.sendMessage(
      conversationId: widget.notification.conversationId,
      content: text,
    );

    HapticFeedback.lightImpact();
    _dismissWithAnimation();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    _replyTextCtrl.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Dismissible(
            key: ValueKey(widget.notification.id),
            direction: DismissDirection.up,
            onDismissed: (_) {
              _dismissTimer?.cancel();
              widget.onDismiss();
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.surfaceDark.withValues(alpha: 0.96)
                      : Colors.white.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark
                        ? AppTheme.primaryLight.withValues(alpha: 0.35)
                        : AppTheme.primaryLight.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : AppTheme.primaryLight)
                          .withValues(alpha: 0.2),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        if (!_isReplying) {
                          _dismissTimer?.cancel();
                          _controller.reverse().then((_) {
                            widget.onDismiss();
                            if (context.mounted &&
                                widget.notification.conversationId.isNotEmpty) {
                              context.push(
                                '/chat/${widget.notification.conversationId}',
                                extra: {
                                  'name': widget.notification.conversationName
                                },
                              );
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(22),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // Sender Avatar
                            AppAvatar(
                              avatarUrl: widget.notification.senderAvatar,
                              name: widget.notification.senderName,
                              size: 42,
                              fontSize: 16,
                            ),
                            const SizedBox(width: 12),

                            // Content Preview
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.notification.senderName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                            color: isDark
                                                ? AppTheme.textPrimDark
                                                : AppTheme.textPrimLight,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        'Just now',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? AppTheme.textSecDark
                                              : AppTheme.textSecLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.notification.previewText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppTheme.textSecDark
                                          : AppTheme.textSecLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Reply Button
                            if (!_isReplying)
                              IconButton(
                                icon: const Icon(Icons.reply_rounded, size: 20),
                                color: AppTheme.primaryLight,
                                tooltip: 'Quick Reply',
                                onPressed: () {
                                  setState(() {
                                    _isReplying = true;
                                    _dismissTimer?.cancel();
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _replyFocusNode.requestFocus();
                                  });
                                },
                              ),

                            // Close Icon
                            GestureDetector(
                              onTap: _dismissWithAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 15,
                                  color: isDark
                                      ? AppTheme.textSecDark
                                      : AppTheme.textSecLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Quick Reply Inline Field
                    if (_isReplying)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 14, right: 14, bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.surfaceDark2
                                      : AppTheme.surfaceLight2,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.primaryLight
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: TextField(
                                  controller: _replyTextCtrl,
                                  focusNode: _replyFocusNode,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Reply to ${widget.notification.senderName}...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? AppTheme.textSecDark
                                          : AppTheme.textSecLight,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark
                                        ? AppTheme.textPrimDark
                                        : AppTheme.textPrimLight,
                                  ),
                                  onSubmitted: (_) => _sendQuickReply(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              icon: const Icon(Icons.send_rounded, size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor: AppTheme.primaryLight,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _sendQuickReply,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
