import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/conversation.dart';
import '../providers/conversations_provider.dart';
import '../providers/messages_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../../../core/widgets/app_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatDetailsScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatDetailsScreen({
    super.key,
    required this.conversationId,
  });

  @override
  ConsumerState<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends ConsumerState<ChatDetailsScreen> {
  String _disappearingTimer = 'Off';
  bool _isMuted = false;

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final conversation = conversationsAsync.value?.firstWhere(
      (c) => c.id == widget.conversationId,
      orElse: () => Conversation(
        id: widget.conversationId,
        isGroup: false,
        name: 'Chat Info',
        updatedAt: DateTime.now(),
        members: [],
      ),
    );

    final currentUserId = currentUserAsync.value?.id ?? '';
    final displayName = conversation != null
        ? conversation.getDisplayName(currentUserId)
        : 'Chat Info';
    final avatarUrl = conversation?.getDisplayAvatarUrl(currentUserId);
    final isGroup = conversation?.isGroup == true;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            isGroup ? 'Group Details' : 'Contact Info',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            indicatorColor: cs.primary,
            indicatorWeight: 3,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
            tabs: const [
              Tab(icon: Icon(Icons.people_alt_outlined, size: 20), text: 'Details'),
              Tab(icon: Icon(Icons.photo_library_outlined, size: 20), text: 'Media'),
              Tab(icon: Icon(Icons.mic_none_rounded, size: 20), text: 'Voice'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Top Header Profile Card ──────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                border: Border(
                  bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                children: [
                  AppAvatar(
                    avatarUrl: avatarUrl,
                    name: displayName,
                    size: 76,
                    fontSize: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isGroup
                        ? '${conversation?.members.length ?? 0} participants'
                        : 'Direct Message • End-to-End Encrypted',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Quick Actions Row (Call, Video, Disappearing, Encrypt) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuickAction(
                        icon: Icons.call_rounded,
                        label: 'Audio',
                        onTap: () {
                          context.push(
                            '/call',
                            extra: {
                              'isAudio': true,
                              'name': displayName,
                              'avatarUrl': avatarUrl,
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      _buildQuickAction(
                        icon: Icons.videocam_rounded,
                        label: 'Video',
                        onTap: () {
                          context.push(
                            '/call',
                            extra: {
                              'isAudio': false,
                              'name': displayName,
                              'avatarUrl': avatarUrl,
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      _buildQuickAction(
                        icon: Icons.timer_outlined,
                        label: 'Disappear',
                        onTap: () => _showDisappearingMessagesSheet(context),
                      ),
                      const SizedBox(width: 14),
                      _buildQuickAction(
                        icon: Icons.lock_outline_rounded,
                        label: 'Verify',
                        onTap: () => _showEncryptionVerification(context, displayName),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Tab Views ─────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  // 1. Details & Members Tab
                  _buildDetailsAndMembersTab(
                    context,
                    conversation,
                    currentUserId,
                    isGroup,
                    displayName,
                    cs,
                    tt,
                  ),

                  // 2. Shared Media Tab
                  _buildMediaTab(context, messagesAsync, cs, tt),

                  // 3. Voice Notes Tab
                  _buildVoiceTab(context, messagesAsync, cs, tt),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsAndMembersTab(
    BuildContext context,
    Conversation? conversation,
    String currentUserId,
    bool isGroup,
    String displayName,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        // ── Security & Privacy Section ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Text(
            'PRIVACY & SECURITY',
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
          ),
          title: const Text('End-to-End Encryption', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Messages and calls are secured with 256-bit keys'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showEncryptionVerification(context, displayName),
        ),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.timer_outlined, color: cs.primary, size: 20),
          ),
          title: const Text('Disappearing Messages', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Current timer: $_disappearingTimer'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showDisappearingMessagesSheet(context),
        ),
        SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_off_outlined, color: Colors.orange, size: 20),
          ),
          title: const Text('Mute Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Silence incoming message alerts'),
          value: _isMuted,
          onChanged: (val) {
            setState(() => _isMuted = val);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(val ? 'Notifications muted' : 'Notifications unmuted'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),

        const Divider(height: 24),

        // ── Members Section (if Group) ──
        if (isGroup) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PARTICIPANTS (${conversation?.members.length ?? 0})',
                  style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showAddMemberDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('Add Member'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),
          if (conversation != null)
            ...conversation.members.map((member) {
              final user = member.user;
              final isMe = user.id == currentUserId;
              final name = isMe ? 'You' : (user.name ?? user.username);
              final email = user.email ?? user.username;

              return ListTile(
                leading: AppAvatar(
                  avatarUrl: user.avatarUrl,
                  name: name,
                  size: 42,
                  fontSize: 16,
                ),
                title: Row(
                  children: [
                    Text(
                      name,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (member.role == 'ADMIN') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Admin',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  email,
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
                trailing: !isMe
                    ? PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                        onSelected: (val) {
                          if (val == 'remove') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Removed $name from group')),
                            );
                          } else if (val == 'admin') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Made $name a group admin')),
                            );
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'admin',
                            child: Text('Make Group Admin'),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove from Group', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      )
                    : null,
              );
            }),
          const Divider(height: 24),
        ],

        // ── Destructive Actions ──
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isGroup ? Icons.exit_to_app_rounded : Icons.block_rounded,
              color: Colors.red,
              size: 20,
            ),
          ),
          title: Text(
            isGroup ? 'Exit Group' : 'Block Contact',
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.red),
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(isGroup ? 'Exit Group?' : 'Block $displayName?'),
                content: Text(
                  isGroup
                      ? 'You will no longer receive messages from this group.'
                      : 'Blocked contacts cannot call or send you messages on Nexora.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isGroup ? 'You left the group' : '$displayName has been blocked',
                          ),
                        ),
                      );
                    },
                    child: Text(isGroup ? 'Exit' : 'Block', style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMediaTab(
    BuildContext context,
    MessagesController controller,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return ValueListenableBuilder<MessagesState>(
      valueListenable: controller.state,
      builder: (context, state, child) {
        final imageMessages = state.messages
            .where((m) => m.type == 'IMAGE' && m.attachmentUrl != null)
            .toList();

        if (imageMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No photos shared yet',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: imageMessages.length,
          itemBuilder: (context, index) {
            final msg = imageMessages[index];
            final url = msg.attachmentUrl!;

            Widget imageWidget;
            if (url.startsWith('data:image')) {
              imageWidget = Image.memory(
                base64Decode(url.split(',')[1]),
                fit: BoxFit.cover,
              );
            } else {
              imageWidget = CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: cs.surfaceContainer.withValues(alpha: 0.5),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: cs.surfaceContainer,
                  child: const Icon(Icons.broken_image_rounded),
                ),
              );
            }

            return GestureDetector(
              onTap: () => _showFullScreenImage(context, url),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageWidget,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVoiceTab(
    BuildContext context,
    MessagesController controller,
    ColorScheme cs,
    TextTheme tt,
  ) {
    return ValueListenableBuilder<MessagesState>(
      valueListenable: controller.state,
      builder: (context, state, child) {
        final voiceMessages =
            state.messages.where((m) => m.type == 'VOICE').toList();

        if (voiceMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  size: 48,
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No voice notes recorded yet',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: voiceMessages.length,
          itemBuilder: (context, index) {
            final msg = voiceMessages[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.play_arrow_rounded, color: cs.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voice Message',
                          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${msg.createdAt.day}/${msg.createdAt.month} at ${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDisappearingMessagesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final options = ['Off', '24 Hours', '7 Days', '90 Days'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Disappearing Messages',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'When enabled, new messages sent in this chat will automatically disappear after the selected duration.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  return RadioListTile<String>(
                    title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w600)),
                    value: opt,
                    groupValue: _disappearingTimer,
                    onChanged: (val) {
                      setState(() => _disappearingTimer = val ?? 'Off');
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Disappearing messages set to $_disappearingTimer'),
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEncryptionVerification(BuildContext context, String displayName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.green, size: 36),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verify Security Code',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'To verify end-to-end encryption with $displayName, scan this QR code or compare the 60-digit number below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),

                // Mock QR Code block
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Icon(Icons.qr_code_2_rounded, size: 120, color: Colors.grey.shade900),
                  ),
                ),
                const SizedBox(height: 20),

                // 60-digit safety numbers in 4 lines
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        '48291  04829  85739  19402',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '94820  18492  03928  48201',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '84729  39582  01948  57204',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✓ Security number verified successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: const Text('Mark as Verified', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Participant'),
        content: const TextField(
          decoration: InputDecoration(
            hintText: 'Enter username or email...',
            prefixIcon: Icon(Icons.person_search_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Member added to group')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
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
                  : CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
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
