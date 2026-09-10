import 'package:flutter/material.dart';
import '../../domain/models/message.dart';
import 'media_bubbles.dart';
import 'enterprise_bubbles.dart';

class SwipeableMessageBubble extends StatelessWidget {
  final Message message;
  final Message? repliedMessage;
  final bool isMe;
  final String currentUserId;
  final bool isLastInGroup;
  final VoidCallback onReply;
  final VoidCallback onLongPress;
  final ValueChanged<String> onReactionTap;
  final VoidCallback? onPayInvoice;
  final VoidCallback? onToggleTask;
  final Function(int optionIndex)? onVotePoll;

  const SwipeableMessageBubble({
    super.key,
    required this.message,
    this.repliedMessage,
    required this.isMe,
    required this.currentUserId,
    required this.isLastInGroup,
    required this.onReply,
    required this.onLongPress,
    required this.onReactionTap,
    this.onPayInvoice,
    this.onToggleTask,
    this.onVotePoll,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMe ? 20 : (isLastInGroup ? 4 : 20)),
      bottomRight: Radius.circular(isMe ? (isLastInGroup ? 4 : 20) : 20),
    );

    return Dismissible(
      key: ValueKey('dismiss_${message.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onReply();
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.reply_rounded, color: cs.primary, size: 20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: isLastInGroup ? 10 : 3,
          left: isMe ? 55 : 0,
          right: isMe ? 0 : 55,
        ),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: isMe && !message.isDeleted
                        ? const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe
                        ? (message.isDeleted ? cs.surfaceContainer : null)
                        : cs.surfaceContainer,
                    borderRadius: radius,
                    boxShadow: [
                      BoxShadow(
                        color: isMe && !message.isDeleted
                            ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // ── Quoted / Replying preview ───────────
                      if (repliedMessage != null || message.replyToId != null)
                        QuotedSnippet(
                          repliedMessage: repliedMessage,
                          isMe: isMe,
                        ),

                      // ── Image Attachment ────────────────────
                      if (message.type == 'IMAGE' && message.attachmentUrl != null)
                        ImageBubbleWidget(
                          imageUrl: message.attachmentUrl!,
                          isMe: isMe,
                        ),

                      // ── Voice Note Attachment ────────────────
                      if (message.type == 'VOICE')
                        VoiceBubbleWidget(
                          message: message,
                          isMe: isMe,
                        ),

                      // ── Location Attachment ──────────────────
                      if (message.type == 'LOCATION' && message.content != null)
                        LocationBubbleWidget(
                          content: message.content!,
                          isMe: isMe,
                        ),

                      // ── Document Attachment ──────────────────
                      if (message.type == 'DOCUMENT' && message.content != null)
                        DocumentBubbleWidget(
                          content: message.content!,
                          isMe: isMe,
                        ),

                      // ── In-Thread Payment / Invoice ──────────
                      if (message.type == 'PAYMENT')
                        PaymentBubbleWidget(
                          message: message,
                          isMe: isMe,
                          onPaid: onPayInvoice,
                        ),

                      // ── In-Chat Task ────────────────────────
                      if (message.type == 'TASK')
                        TaskBubbleWidget(
                          message: message,
                          isMe: isMe,
                          onToggle: onToggleTask,
                        ),

                      // ── Interactive Poll ─────────────────────
                      if (message.type == 'POLL')
                        PollBubbleWidget(
                          message: message,
                          isMe: isMe,
                          currentUserId: currentUserId,
                          onVote: onVotePoll,
                        ),

                      // ── Incoming Webhook Alert ───────────────
                      if (message.type == 'WEBHOOK')
                        WebhookBubbleWidget(
                          message: message,
                          isMe: isMe,
                        ),

                      // ── Live Location Streaming Beacon ───────
                      if (message.type == 'LIVE_LOCATION')
                        LiveLocationBubbleWidget(
                          message: message,
                          isMe: isMe,
                        ),

                      // ── Text / Deleted Message Content ───────
                      if (message.isDeleted)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.block_rounded,
                              size: 15,
                              color: cs.onSurface.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'This message was deleted',
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.45),
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                      else if (message.type == 'TEXT' &&
                          message.content != null &&
                          message.content!.isNotEmpty)
                        Text(
                          message.content!,
                          style: TextStyle(
                            color: isMe ? Colors.white : cs.onSurface,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Reactions Pill ────────────────────────────
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Wrap(
                      spacing: 4,
                      children: message.reactions.entries.map((entry) {
                        final emoji = entry.key;
                        final count = entry.value.length;
                        final isMyReaction = entry.value.contains(currentUserId);
                        return GestureDetector(
                          onTap: () => onReactionTap(emoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: isMyReaction
                                  ? const Color(0xFF7C3AED).withValues(alpha: 0.25)
                                  : cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isMyReaction
                                    ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                                    : cs.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 13)),
                                if (count > 1) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isMyReaction
                                          ? cs.primary
                                          : cs.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // ── Time & Status Ticks ───────────────────────
                if (isLastInGroup)
                  Padding(
                    padding: const EdgeInsets.only(top: 3, left: 6, right: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withValues(alpha: 0.35),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: cs.onSurface.withValues(alpha: 0.35),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (isMe && !message.isDeleted) ...[
                          const SizedBox(width: 4),
                          StatusTicks(status: message.status),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Quoted Snippet inside Message Bubble ──────────────────────────────────────

class QuotedSnippet extends StatelessWidget {
  final Message? repliedMessage;
  final bool isMe;

  const QuotedSnippet({super.key, this.repliedMessage, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final senderName = repliedMessage?.sender?.name ??
        repliedMessage?.sender?.username ??
        'Reply';
    final content = repliedMessage?.content ??
        (repliedMessage?.type == 'IMAGE' ? '📷 Photo' : 'Original message');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.black.withValues(alpha: 0.15)
            : cs.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMe ? Colors.white70 : cs.primary,
            width: 3.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: isMe ? Colors.white : cs.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: isMe
                  ? Colors.white.withValues(alpha: 0.8)
                  : cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reply Banner above Text Field ─────────────────────────────────────────────

class ReplyBanner extends StatelessWidget {
  final Message message;
  final VoidCallback onCancel;

  const ReplyBanner({super.key, required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final senderName =
        message.sender?.name ?? message.sender?.username ?? 'Message';
    final content = message.content ??
        (message.type == 'IMAGE' ? '📷 Photo' : 'Attachment');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
          left: BorderSide(color: cs.primary, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply_rounded, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderName',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: cs.primary,
                  ),
                ),
                Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Status Ticks ──────────────────────────────────────────────────────────────

class StatusTicks extends StatelessWidget {
  final String status;

  const StatusTicks({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'READ') {
      return const Icon(
        Icons.done_all_rounded,
        size: 13,
        color: Color(0xFF38BDF8),
      );
    } else if (status == 'DELIVERED') {
      return Icon(
        Icons.done_all_rounded,
        size: 13,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      );
    } else {
      return Icon(
        Icons.done_rounded,
        size: 13,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
      );
    }
  }
}

// ── Option Tile in Bottom Sheet ───────────────────────────────────────────────

class OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const OptionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final itemColor = color ?? cs.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: itemColor, size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: itemColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
