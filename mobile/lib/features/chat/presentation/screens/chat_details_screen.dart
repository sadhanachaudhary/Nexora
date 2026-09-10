import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/conversation.dart';
import '../../domain/models/message.dart';
import '../providers/conversations_provider.dart';
import '../providers/messages_provider.dart';
import '../../data/repositories/user_repository.dart';
import '../../../../core/theme/app_theme.dart';

class ChatDetailsScreen extends ConsumerWidget {
  final String conversationId;

  const ChatDetailsScreen({
    super.key,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final messagesAsync = ref.watch(messagesProvider(conversationId));
    final currentUserAsync = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final conversation = conversationsAsync.value?.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => Conversation(
        id: conversationId,
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

    final avatarGradient = AppTheme.avatarGradient(
      displayName.isNotEmpty ? displayName.codeUnitAt(0) : 0,
    );

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
            conversation?.isGroup == true ? 'Group Details' : 'Contact Info',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          bottom: TabBar(
            indicatorColor: cs.primary,
            indicatorWeight: 3,
            labelColor: cs.primary,
            unselectedLabelColor: cs.onSurface.withValues(alpha: 0.5),
            tabs: const [
              Tab(icon: Icon(Icons.people_alt_outlined, size: 20), text: 'Members'),
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
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.backgroundColor,
                border: Border(
                  bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: avatarGradient,
                      boxShadow: [
                        BoxShadow(
                          color: avatarGradient.colors.first.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation?.isGroup == true
                        ? '${conversation?.members.length ?? 0} participants'
                        : 'Direct Message',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Views ─────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  // 1. Members Tab
                  _buildMembersTab(context, conversation, currentUserId, cs, tt),

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

  Widget _buildMembersTab(
    BuildContext context,
    Conversation? conversation,
    String currentUserId,
    ColorScheme cs,
    TextTheme tt,
  ) {
    if (conversation == null || conversation.members.isEmpty) {
      return Center(
        child: Text(
          'No members found',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: conversation.members.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 68,
        color: cs.outline.withValues(alpha: 0.2),
      ),
      itemBuilder: (context, index) {
        final member = conversation.members[index];
        final user = member.user;
        final isMe = user.id == currentUserId;
        final name = isMe ? 'You' : (user.name ?? user.username);
        final email = user.email ?? user.username;
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final gradient = AppTheme.avatarGradient(name.codeUnitAt(0));

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Text(
                name,
                style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (member.role == 'ADMIN') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
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
        );
      },
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
              imageWidget = Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
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
