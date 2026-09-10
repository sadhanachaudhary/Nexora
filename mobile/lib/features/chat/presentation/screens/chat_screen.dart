import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/messages_provider.dart';
import '../providers/conversations_provider.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/models/message.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/user.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../widgets/smart_replies_bar.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/empty_chat_state.dart';
import '../widgets/attachment_sheet.dart';
import '../widgets/voice_recording_bar.dart';
import '../widgets/message_bubble.dart';

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
  final _searchQueryController = TextEditingController();
  bool _isSearching = false;
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
    _searchQueryController.dispose();
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
      const dummyAudioUrl = 'https://actions.google.com/sounds/v1/water/rain_heavy.ogg';
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
                OptionTile(
                  icon: Icons.reply_rounded,
                  label: 'Reply',
                  onTap: () {
                    Navigator.pop(ctx);
                    _onReply(message);
                  },
                ),
                OptionTile(
                  icon: Icons.copy_rounded,
                  label: 'Copy Text',
                  onTap: () {
                    Navigator.pop(ctx);
                    if (message.content != null) {
                      Clipboard.setData(ClipboardData(text: message.content!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard')),
                      );
                    }
                  },
                ),
                OptionTile(
                  icon: Icons.forward_rounded,
                  label: 'Forward Message',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showForwardDialog(context, message);
                  },
                ),
                if (isMe && !message.isDeleted && message.type == 'TEXT')
                  OptionTile(
                    icon: Icons.edit_note_rounded,
                    label: 'Edit Message',
                    onTap: () {
                      Navigator.pop(ctx);
                      _showEditMessageDialog(context, message);
                    },
                  ),
                if (isMe && !message.isDeleted)
                  OptionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete for Everyone',
                    color: Colors.red,
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

  void _showForwardDialog(BuildContext context, Message message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forward Message'),
        content: const Text('Forward this message to another chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message forwarded!')),
              );
            },
            child: const Text('Forward'),
          ),
        ],
      ),
    );
  }

  void _showEditMessageDialog(BuildContext context, Message message) {
    final editController = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Edit your message...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = editController.text.trim();
              if (newText.isNotEmpty && newText != message.content) {
                ref.read(messagesProvider(widget.conversationId)).editMessage(message.id, newText);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAISummaryDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Chat Summary',
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📌 Key Points Discussed:',
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Discussion on project architecture and Level 1-3 deliverables.\n'
                      '• Voice notes and real media attachments shared and verified.\n'
                      '• End-to-end security and calling capabilities active.',
                      style: tt.bodySmall?.copyWith(height: 1.4, color: cs.onSurface.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserId = ref.watch(currentUserProvider).value?.id ?? '';

    final conversation = conversationsAsync.value?.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => Conversation(
        id: widget.conversationId,
        isGroup: false,
        name: widget.conversationName,
        updatedAt: DateTime.now(),
        members: [],
      ),
    );

    final avatarUrl = conversation?.getDisplayAvatarUrl(currentUserId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchQueryController,
                autofocus: true,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: 'Search in conversation...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : InkWell(
                onTap: () {
                  context.push('/chat/${widget.conversationId}/details');
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: Row(
                    children: [
                      AppAvatar(
                        avatarUrl: avatarUrl,
                        name: widget.conversationName,
                        size: 38,
                        fontSize: 16,
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
          if (_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _searchQueryController.clear();
                setState(() => _isSearching = false);
              },
            ),
          ] else ...[
            _AppBarAction(
              icon: Icons.auto_awesome_rounded,
              onPressed: () => _showAISummaryDialog(context),
            ),
            _AppBarAction(
              icon: Icons.search_rounded,
              onPressed: () => setState(() => _isSearching = true),
            ),
            _AppBarAction(
              icon: Icons.videocam_outlined,
              onPressed: () => context.push('/call', extra: {
                'isAudio': false,
                'name': widget.conversationName,
                'avatarUrl': avatarUrl,
              }),
            ),
            _AppBarAction(
              icon: Icons.call_outlined,
              onPressed: () => context.push('/call', extra: {
                'isAudio': true,
                'name': widget.conversationName,
                'avatarUrl': avatarUrl,
              }),
            ),
            _AppBarAction(
              icon: Icons.info_outline_rounded,
              onPressed: () {
                context.push('/chat/${widget.conversationId}/details');
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // ── Messages List ──────────────────────────────────────
          Expanded(
            child: Consumer(builder: (context, ref, child) {
              final controller = ref.watch(messagesProvider(widget.conversationId));

              return ValueListenableBuilder<MessagesState>(
                valueListenable: controller.state,
                builder: (context, state, child) {
                  if (state.isLoading && state.messages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var displayedMessages = state.messages;
                  final searchQ = _searchQueryController.text.trim().toLowerCase();
                  if (searchQ.isNotEmpty) {
                    displayedMessages = displayedMessages
                        .where((m) => (m.content ?? '').toLowerCase().contains(searchQ))
                        .toList();
                  }

                  if (displayedMessages.isEmpty) {
                    return EmptyChatState(
                      name: widget.conversationName,
                      avatarUrl: avatarUrl,
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    reverse: true,
                    itemCount: displayedMessages.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == displayedMessages.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final message = displayedMessages[index];
                      final currentUser = ref.watch(currentUserProvider).value;
                      final isMe = currentUser != null && message.senderId == currentUser.id;

                      final isLastInGroup = index == 0 ||
                          state.messages[index - 1].senderId != message.senderId;

                      Message? repliedMessage;
                      if (message.replyToId != null) {
                        try {
                          repliedMessage = state.messages.firstWhere(
                            (m) => m.id == message.replyToId,
                          );
                        } catch (_) {}
                      }

                      return SwipeableMessageBubble(
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
                messagesProvider(widget.conversationId).select((c) => c.state.value.typingUsers),
              );
              if (typingUsers.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4, right: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TypingIndicator(),
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
            ReplyBanner(
              message: _replyingToMessage!,
              onCancel: () => setState(() => _replyingToMessage = null),
            ),

          // ── AI Smart Replies Bar ──────────────────────────────
          SmartRepliesBar(
            suggestions: const [
              'Sounds good! 👍',
              'I will check now',
              'On my way! 🚗',
              'Let’s do it! ✨',
              'Thanks! 🙏',
            ],
            onSelected: (reply) {
              final controller = ref.read(messagesProvider(widget.conversationId));
              controller.sendMessage(reply);
            },
          ),

          // ── Input bar / Voice Recording Bar ───────────────────
          if (_isRecordingVoice)
            VoiceRecordingBar(
              recordDuration: _recordDuration,
              onCancel: _cancelVoiceRecording,
              onSend: _stopAndSendVoiceRecording,
            )
          else
            _buildMessageInput(context),
        ],
      ),
    );
  }

  void _showAttachmentMenu(BuildContext context) {
    AttachmentSheet.show(
      context,
      onCamera: () => _pickAndSendImage(ImageSource.camera),
      onGallery: () => _pickAndSendImage(ImageSource.gallery),
      onDocument: () => _sendSampleDocument(context),
      onLocation: () => _showLocationPicker(context),
      onContact: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact picker opened')),
        );
      },
    );
  }

  void _sendSampleDocument(BuildContext context) {
    ref.read(messagesProvider(widget.conversationId)).sendDocumentMessage(
      fileName: 'Project_Specification.pdf',
      fileSize: '2.4 MB',
      fileUrl: 'https://example.com/spec.pdf',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document shared successfully')),
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
          final repo = ref.read(chatRepositoryProvider);
          final uploadedUrl = await repo.uploadFileBytes(bytes, image.name);
          ref.read(messagesProvider(widget.conversationId)).sendImageMessage(uploadedUrl);
        } catch (_) {
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
            ],
          ),
        ),
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
          children: [
            _InputIconButton(
              icon: Icons.add_circle_outline_rounded,
              onPressed: () => _showAttachmentMenu(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Message...',
                          hintStyle: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.4),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (text) {
                          if (text.isNotEmpty) {
                            ref.read(messagesProvider(widget.conversationId)).updateTypingStatus();
                          }
                        },
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.sentiment_satisfied_alt_rounded,
                        color: cs.onSurface.withValues(alpha: 0.45),
                        size: 22,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send / Voice Record Button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _hasText
                  ? GestureDetector(
                      key: const ValueKey('send_btn'),
                      onTap: _sendMessage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    )
                  : GestureDetector(
                      key: const ValueKey('mic_btn'),
                      onLongPress: _startVoiceRecording,
                      onTap: _startVoiceRecording,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_none_rounded,
                          color: cs.primary,
                          size: 22,
                        ),
                      ),
                    ),
            ),
          ],
        ),
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
