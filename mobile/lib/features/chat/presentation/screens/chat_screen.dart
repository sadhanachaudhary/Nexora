import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/messages_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/message.dart';
import '../../domain/models/user.dart';
import '../../../../core/theme/app_theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String conversationName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.conversationName = 'Chat',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;
  Message? _replyingToMessage;
  late final AnimationController _sendBtnCtrl;

  @override
  void initState() {
    super.initState();
    _sendBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _messageController.addListener(() {
      final has = _messageController.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() => _hasText = has);
        has ? _sendBtnCtrl.forward() : _sendBtnCtrl.reverse();
      }
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        ref.read(messagesProvider(widget.conversationId)).loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _sendBtnCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(messagesProvider(widget.conversationId)).sendMessage(
            text,
            replyToId: _replyingToMessage?.id,
          );
      _messageController.clear();
      setState(() => _replyingToMessage = null);
    }
  }

  void _onReply(Message message) {
    HapticFeedback.lightImpact();
    setState(() => _replyingToMessage = message);
  }

  void _showMessageOptions(
    BuildContext context,
    Message message,
    bool isMe,
    User? currentUser,
  ) {
    HapticFeedback.mediumImpact();
    final cs = Theme.of(context).colorScheme;
    final controller = ref.read(messagesProvider(widget.conversationId));
    final myId = currentUser?.id ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Quick Emojis ──────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['❤️', '👍', '😂', '🔥', '😮', '👏'].map((emoji) {
                      final hasReacted =
                          message.reactions[emoji]?.contains(myId) ?? false;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          controller.toggleReaction(message.id, emoji, myId);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: hasReacted
                                ? cs.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Options List ──────────────────────────────
                _OptionTile(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  onTap: () {
                    Navigator.pop(ctx);
                    _onReply(message);
                  },
                ),
                if (message.content != null && message.content!.isNotEmpty)
                  _OptionTile(
                    icon: Icons.copy_rounded,
                    label: 'Copy Text',
                    onTap: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(ClipboardData(text: message.content!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                if (isMe && !message.isDeleted)
                  _OptionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete for Everyone',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(ctx);
                      controller.deleteMessage(message.id);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatarGradient =
        AppTheme.avatarGradient(widget.conversationName.codeUnitAt(0));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Gradient avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: avatarGradient,
              ),
              child: Center(
                child: Text(
                  widget.conversationName.isNotEmpty
                      ? widget.conversationName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversationName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          _AppBarAction(icon: Icons.videocam_outlined, onPressed: () {}),
          _AppBarAction(icon: Icons.call_outlined, onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Message list ───────────────────────────────────────
          Expanded(
            child: Builder(builder: (context) {
              final controller =
                  ref.watch(messagesProvider(widget.conversationId));

              return ValueListenableBuilder<MessagesState>(
                valueListenable: controller.state,
                builder: (context, state, child) {
                  if (state.isLoading) {
                    return Center(
                      child: CircularProgressIndicator(color: cs.primary),
                    );
                  }
                  if (state.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Could not load messages',
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    );
                  }
                  if (state.messages.isEmpty) {
                    return _EmptyChatState(name: widget.conversationName);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    reverse: true,
                    itemCount:
                        state.messages.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final message = state.messages[index];
                      final currentUser =
                          ref.watch(currentUserProvider).value;
                      final isMe = currentUser != null &&
                          message.senderId == currentUser.id;

                      // Tail grouping: show tail for the last message in a group
                      final isLastInGroup = index == 0 ||
                          state.messages[index - 1].senderId !=
                              message.senderId;

                      // Find replied message if replyToId exists
                      Message? repliedMessage;
                      if (message.replyToId != null) {
                        try {
                          repliedMessage = state.messages.firstWhere(
                            (m) => m.id == message.replyToId,
                          );
                        } catch (_) {}
                      }

                      return _SwipeableMessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        repliedMessage: repliedMessage,
                        isMe: isMe,
                        currentUserId: currentUser?.id ?? '',
                        isLastInGroup: isLastInGroup,
                        onReply: () => _onReply(message),
                        onLongPress: () => _showMessageOptions(
                          context,
                          message,
                          isMe,
                          currentUser,
                        ),
                        onReactionTap: (emoji) {
                          controller.toggleReaction(
                            message.id,
                            emoji,
                            currentUser?.id ?? '',
                          );
                        },
                      );
                    },
                  );
                },
              );
            }),
          ),

          // ── Typing indicator ───────────────────────────────────
          Consumer(
            builder: (context, ref, child) {
              final typingUsers = ref.watch(
                messagesProvider(widget.conversationId)
                    .select((c) => c.state.value.typingUsers),
              );
              if (typingUsers.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4, right: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TypingIndicator(),
                      const SizedBox(width: 8),
                      Text(
                        'typing...',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Reply Banner (if active) ───────────────────────────
          if (_replyingToMessage != null)
            _ReplyBanner(
              message: _replyingToMessage!,
              onCancel: () => setState(() => _replyingToMessage = null),
            ),

          // ── Input bar ──────────────────────────────────────────
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.2), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image picker
            _InputIconButton(
              icon: Icons.image_outlined,
              onPressed: () async {
                final picker = ImagePicker();
                final image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  final base64Image =
                      'data:image/jpeg;base64,${base64Encode(bytes)}';
                  ref
                      .read(messagesProvider(widget.conversationId))
                      .sendImageMessage(base64Image);
                }
              },
            ),
            const SizedBox(width: 8),

            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: cs.outline.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _messageController,
                  onChanged: (_) {
                    ref
                        .read(messagesProvider(widget.conversationId))
                        .updateTypingStatus();
                  },
                  decoration: InputDecoration(
                    hintText: _replyingToMessage != null
                        ? 'Type your reply...'
                        : 'Message...',
                    hintStyle: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            GestureDetector(
              onTap: _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: _hasText
                      ? const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _hasText ? null : cs.surfaceContainer,
                  shape: BoxShape.circle,
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF7C3AED).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 20,
                  color: _hasText
                      ? Colors.white
                      : cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Swipeable Message Bubble ──────────────────────────────────────────────────

class _SwipeableMessageBubble extends StatelessWidget {
  final Message message;
  final Message? repliedMessage;
  final bool isMe;
  final String currentUserId;
  final bool isLastInGroup;
  final VoidCallback onReply;
  final VoidCallback onLongPress;
  final ValueChanged<String> onReactionTap;

  const _SwipeableMessageBubble({
    super.key,
    required this.message,
    this.repliedMessage,
    required this.isMe,
    required this.currentUserId,
    required this.isLastInGroup,
    required this.onReply,
    required this.onLongPress,
    required this.onReactionTap,
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
                        ? (message.isDeleted
                            ? cs.surfaceContainer
                            : null)
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
                        _QuotedSnippet(
                          repliedMessage: repliedMessage,
                          isMe: isMe,
                        ),

                      // ── Image Attachment ────────────────────
                      if (message.type == 'IMAGE' &&
                          message.attachmentUrl != null &&
                          message.attachmentUrl!.startsWith('data:image'))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(
                                  message.attachmentUrl!.split(',')[1]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      // ── Message Content ─────────────────────
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
                      else if (message.content != null &&
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
                                  ? const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.25)
                                  : cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isMyReaction
                                    ? const Color(0xFF7C3AED)
                                        .withValues(alpha: 0.5)
                                    : cs.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji,
                                    style: const TextStyle(fontSize: 13)),
                                if (count > 1) ...[
                                  const SizedBox(width: 3),
                                  Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isMyReaction
                                          ? cs.primary
                                          : cs.onSurface
                                              .withValues(alpha: 0.7),
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
                        if (isMe && !message.isDeleted) ...[
                          const SizedBox(width: 4),
                          _StatusTicks(status: message.status),
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

class _QuotedSnippet extends StatelessWidget {
  final Message? repliedMessage;
  final bool isMe;

  const _QuotedSnippet({this.repliedMessage, required this.isMe});

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

class _ReplyBanner extends StatelessWidget {
  final Message message;
  final VoidCallback onCancel;

  const _ReplyBanner({required this.message, required this.onCancel});

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
                    color: cs.primary,
                    fontSize: 12.5,
                  ),
                ),
                Text(
                  content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
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
          ),
        ],
      ),
    );
  }
}

// ── Status Ticks ──────────────────────────────────────────────────────────────

class _StatusTicks extends StatelessWidget {
  final String status;
  const _StatusTicks({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'READ') {
      return const Icon(
        Icons.done_all_rounded,
        size: 14,
        color: Color(0xFF818CF8), // Purple/blue read double tick
      );
    } else if (status == 'DELIVERED') {
      return Icon(
        Icons.done_all_rounded,
        size: 14,
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

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _OptionTile({
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

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final t = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
              final bounce = (t < 0.5 ? t * 2 : (1 - t) * 2);
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 7,
                height: 7,
                transform: Matrix4.translationValues(0, -bounce * 5, 0),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.5 + bounce * 0.5),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

// ── Empty chat state ──────────────────────────────────────────────────────────

class _EmptyChatState extends StatelessWidget {
  final String name;
  const _EmptyChatState({required this.name});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatarGradient = AppTheme.avatarGradient(name.codeUnitAt(0));
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: avatarGradient,
              boxShadow: [
                BoxShadow(
                  color: avatarGradient.colors.first.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Say hello! 👋',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _AppBarAction({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: cs.primary),
      ),
      onPressed: onPressed,
    );
  }
}

class _InputIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _InputIconButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: cs.primary, size: 20),
      ),
    );
  }
}
