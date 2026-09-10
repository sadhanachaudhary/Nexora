import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/messages_provider.dart';
import '../../data/repositories/chat_repository.dart';
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

  // Voice recording state
  bool _isRecordingVoice = false;
  int _recordDuration = 0;
  Timer? _recordTimer;

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
    _recordTimer?.cancel();
    super.dispose();
  }

  void _startVoiceRecording() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRecordingVoice = true;
      _recordDuration = 0;
    });
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _recordDuration++);
      }
    });
  }

  void _stopAndSendVoiceRecording() {
    HapticFeedback.mediumImpact();
    final duration = _recordDuration;
    _cancelVoiceRecording();

    if (duration >= 1) {
      // Send simulated / uploaded voice note audio payload with duration
      final dummyAudioUrl = 'https://actions.google.com/sounds/v1/water/rain_heavy.ogg';
      ref.read(messagesProvider(widget.conversationId)).sendVoiceMessage(dummyAudioUrl, duration);
    }
  }

  void _cancelVoiceRecording() {
    _recordTimer?.cancel();
    setState(() {
      _isRecordingVoice = false;
      _recordDuration = 0;
    });
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
        title: InkWell(
          onTap: () => context.push('/chat/${widget.conversationId}/details'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
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
          ),
        ),
        actions: [
          _AppBarAction(icon: Icons.videocam_outlined, onPressed: () {}),
          _AppBarAction(icon: Icons.call_outlined, onPressed: () {}),
          _AppBarAction(
            icon: Icons.info_outline_rounded,
            onPressed: () => context.push('/chat/${widget.conversationId}/details'),
          ),
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

  void _showAttachmentMenu(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Share Attachment',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AttachmentActionItem(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: const Color(0xFFEF4444),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.camera);
                    },
                  ),
                  _AttachmentActionItem(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                  _AttachmentActionItem(
                    icon: Icons.location_on_rounded,
                    label: 'Location',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showLocationPicker(context);
                    },
                  ),
                  _AttachmentActionItem(
                    icon: Icons.mic_rounded,
                    label: 'Voice Note',
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.pop(ctx);
                      _startVoiceRecording();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        try {
          // Attempt multipart upload to backend
          final repo = ref.read(chatRepositoryProvider);
          final uploadedUrl = await repo.uploadFileBytes(bytes, image.name);
          ref.read(messagesProvider(widget.conversationId)).sendImageMessage(uploadedUrl);
        } catch (_) {
          // Fallback to base64 encoding if upload endpoint is offline
          final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          ref.read(messagesProvider(widget.conversationId)).sendImageMessage(base64Image);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not attach image: $e')),
        );
      }
    }
  }

  void _showLocationPicker(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Send Location',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: cs.surfaceContainer,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 22),
                ),
                title: Text('Current GPS Location', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('37.7749° N, 122.4194° W', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                trailing: const Icon(Icons.send_rounded, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(messagesProvider(widget.conversationId)).sendLocationMessage(
                    latitude: 37.7749,
                    longitude: -122.4194,
                    locationName: 'Current Location (San Francisco)',
                  );
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: cs.surfaceContainer,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.business_rounded, color: cs.primary, size: 22),
                ),
                title: Text('Nexora Headquarters', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('Innovation District, Tech City', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                trailing: const Icon(Icons.send_rounded, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(messagesProvider(widget.conversationId)).sendLocationMessage(
                    latitude: 28.6139,
                    longitude: 77.2090,
                    locationName: 'Nexora Headquarters',
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_isRecordingVoice) {
      final mins = (_recordDuration ~/ 60).toString().padLeft(2, '0');
      final secs = (_recordDuration % 60).toString().padLeft(2, '0');

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
          border: Border(
            top: BorderSide(color: cs.outline.withValues(alpha: 0.2), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              // Red recording pulse indicator
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$mins:$secs',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 14),
              // Animated soundwaves
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(16, (i) {
                      final h = ((i % 4 + 1) * 5.0) + (_recordDuration % 2 == 0 ? 4 : 0);
                      return Container(
                        width: 3,
                        height: h,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Cancel button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 24),
                onPressed: _cancelVoiceRecording,
              ),
              const SizedBox(width: 6),
              // Send Voice Note button
              GestureDetector(
                onTap: _stopAndSendVoiceRecording,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
            // Plus / Attachment Button
            _InputIconButton(
              icon: Icons.add_rounded,
              onPressed: () => _showAttachmentMenu(context),
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

            // Send or Mic button
            GestureDetector(
              onTap: _hasText ? _sendMessage : _startVoiceRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _hasText ? Icons.send_rounded : Icons.mic_rounded,
                  size: 20,
                  color: Colors.white,
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
                      if (message.type == 'IMAGE' && message.attachmentUrl != null)
                        _ImageBubbleWidget(
                          imageUrl: message.attachmentUrl!,
                          isMe: isMe,
                        ),

                      // ── Voice Note Attachment ────────────────
                      if (message.type == 'VOICE')
                        _VoiceBubbleWidget(
                          message: message,
                          isMe: isMe,
                        ),

                      // ── Location Attachment ──────────────────
                      if (message.type == 'LOCATION' && message.content != null)
                        _LocationBubbleWidget(
                          content: message.content!,
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

// ── Attachment Action Item ─────────────────────────────────────────────────────

class _AttachmentActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image Bubble Widget ────────────────────────────────────────────────────────

class _ImageBubbleWidget extends StatelessWidget {
  final String imageUrl;
  final bool isMe;

  const _ImageBubbleWidget({
    required this.imageUrl,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageUrl.startsWith('data:image')) {
      imageWidget = Image.memory(
        base64Decode(imageUrl.split(',')[1]),
        fit: BoxFit.cover,
        width: 220,
        height: 180,
      );
    } else {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 220,
        height: 180,
        errorBuilder: (_, __, ___) => Container(
          width: 220,
          height: 140,
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Center(child: Icon(Icons.broken_image_rounded)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => _openZoomDialog(context, imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: imageWidget,
        ),
      ),
    );
  }

  void _openZoomDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: url.startsWith('data:image')
                  ? Image.memory(base64Decode(url.split(',')[1]))
                  : Image.network(url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Voice Bubble Widget ────────────────────────────────────────────────────────

class _VoiceBubbleWidget extends StatefulWidget {
  final Message message;
  final bool isMe;

  const _VoiceBubbleWidget({
    required this.message,
    required this.isMe,
  });

  @override
  State<_VoiceBubbleWidget> createState() => _VoiceBubbleWidgetState();
}

class _VoiceBubbleWidgetState extends State<_VoiceBubbleWidget>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _animCtrl.repeat();
      // Auto stop simulation after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _isPlaying = false);
          _animCtrl.stop();
        }
      });
    } else {
      _animCtrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final durationSecs = int.tryParse(widget.message.content ?? '5') ?? 5;
    final mins = (durationSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (durationSecs % 60).toString().padLeft(2, '0');

    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.25)
                    : cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMe ? Colors.white : cs.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Animated waveform bars
          Expanded(
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(12, (i) {
                  final wave = _isPlaying
                      ? (sin((_animCtrl.value * 6.28) + i * 0.5).abs() * 14.0 + 4.0)
                      : ((i % 3 + 1) * 4.0 + 3.0);
                  return Container(
                    width: 3,
                    height: wave,
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? Colors.white.withValues(alpha: 0.85)
                          : cs.primary.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Duration label
          Text(
            '$mins:$secs',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.isMe
                  ? Colors.white.withValues(alpha: 0.8)
                  : cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Location Bubble Widget ─────────────────────────────────────────────────────

class _LocationBubbleWidget extends StatelessWidget {
  final String content;
  final bool isMe;

  const _LocationBubbleWidget({
    required this.content,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String name = 'Shared Location';
    double lat = 37.7749;
    double lng = -122.4194;

    try {
      final data = jsonDecode(content);
      if (data is Map) {
        name = data['name'] ?? 'Shared Location';
        lat = (data['lat'] as num?)?.toDouble() ?? 37.7749;
        lng = (data['lng'] as num?)?.toDouble() ?? -122.4194;
      }
    } catch (_) {}

    return Container(
      width: 220,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.15)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? Colors.white.withValues(alpha: 0.2)
              : cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic Map card header
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF0F172A),
                  const Color(0xFF1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Grid lines pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isMe ? Colors.white : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 20) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

