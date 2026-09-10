import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../chat/presentation/providers/conversations_provider.dart';
import '../../../chat/data/repositories/user_repository.dart';
import '../../../chat/domain/models/conversation.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _selectedConversationId;
  String? _selectedConversationName;

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 850;
    final conversationsAsync = ref.watch(conversationsProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget leftPane = Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Pinned header ────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: tt.headlineMedium?.copyWith(letterSpacing: -0.5),
                ),
                Text(
                  currentUserAsync.when(
                    data: (u) => 'Hey, ${u.name ?? u.username} 👋',
                    loading: () => '',
                    error: (_, __) => '',
                  ),
                  style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_outline_rounded, size: 20, color: cs.primary),
                ),
                onPressed: () => context.push('/profile'),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
            ),
          ),

          // ── Body ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: conversationsAsync.when(
              data: (conversations) {
                if (conversations.isEmpty) {
                  return _EmptyState();
                }
                final currentUserId = currentUserAsync.value?.id ?? '';
                return Column(
                  children: List.generate(conversations.length, (i) {
                    final conv = conversations[i];
                    final name = conv.getDisplayName(currentUserId);
                    final isSelected = isWideScreen && conv.id == _selectedConversationId;

                    return _ConversationTile(
                      conversation: conv,
                      currentUserId: currentUserId,
                      isSelected: isSelected,
                      isLast: i == conversations.length - 1,
                      onTap: () {
                        if (isWideScreen) {
                          setState(() {
                            _selectedConversationId = conv.id;
                            _selectedConversationName = name;
                          });
                        } else {
                          context.push(
                            '/chat/${conv.id}',
                            extra: {'name': name},
                          );
                        }
                      },
                    );
                  }),
                );
              },
              loading: () => _SkeletonList(),
              error: (e, st) => _ErrorState(onRetry: () => ref.invalidate(conversationsProvider)),
            ),
          ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewChatMenu(context, ref),
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text('New Chat', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );

    if (!isWideScreen) {
      return leftPane;
    }

    // Wide screen Dual-Pane layout
    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar Conversation List
          SizedBox(
            width: 380,
            child: leftPane,
          ),
          // Vertical divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: cs.outline.withValues(alpha: 0.2),
          ),
          // Right Chat Area
          Expanded(
            child: _selectedConversationId != null
                ? ChatScreen(
                    key: ValueKey(_selectedConversationId),
                    conversationId: _selectedConversationId!,
                    conversationName: _selectedConversationName ?? 'Chat',
                  )
                : _SplitEmptyChatPlaceholder(),
          ),
        ],
      ),
    );
  }

  void _showNewChatMenu(BuildContext context, WidgetRef ref) {
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
                'Start a Conversation',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
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
                  child: Icon(Icons.person_add_rounded, color: cs.primary, size: 22),
                ),
                title: Text('New Direct Chat', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('Search contacts or invite via email', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.4)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.push('/search');
                  ref.invalidate(conversationsProvider);
                },
              ),
              const SizedBox(height: 12),
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
                  child: const Icon(Icons.group_add_rounded, color: Color(0xFF10B981), size: 22),
                ),
                title: Text('New Group Chat', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                subtitle: Text('Add multiple friends into a team room', style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
                trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurface.withValues(alpha: 0.4)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await context.push('/create-group');
                  ref.invalidate(conversationsProvider);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.15),
                    cs.primary.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  size: 44, color: cs.primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text('No conversations yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface.withValues(alpha: 0.5))),
            const SizedBox(height: 6),
            Text('Tap + to start a new chat',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.35))),
          ],
        ),
      ),
    );
  }
}

// ── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Could not load conversations',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loading ─────────────────────────────────────────────────────────

class _SkeletonList extends StatefulWidget {
  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Column(
        children: List.generate(6, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cs.surfaceContainer.withValues(alpha: _anim.value),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 14,
                        width: 120 + (i * 10.0),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer.withValues(alpha: _anim.value),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 180 + (i * 5.0),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer.withValues(alpha: _anim.value * 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Conversation tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
    this.isSelected = false,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = conversation.getDisplayName(currentUserId);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Last message preview
    final lastMsg = conversation.latestMessage;
    String subtitle = 'Tap to chat';
    if (lastMsg != null) {
      subtitle = lastMsg.type == 'IMAGE' ? '📷 Photo' : (lastMsg.content ?? 'Tap to chat');
    }

    // Time display
    final now = DateTime.now();
    final diff = now.difference(conversation.updatedAt);
    String timeStr;
    if (diff.inMinutes < 1) {
      timeStr = 'now';
    } else if (diff.inHours < 1) {
      timeStr = '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      timeStr = '${diff.inHours}h';
    } else if (diff.inDays < 7) {
      timeStr = '${diff.inDays}d';
    } else {
      timeStr = '${conversation.updatedAt.day}/${conversation.updatedAt.month}';
    }

    final avatarGradient = AppTheme.avatarGradient(displayName.codeUnitAt(0));

    return Container(
      color: isSelected ? cs.primary.withValues(alpha: 0.12) : null,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Avatar with online ring
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: avatarGradient,
                        boxShadow: [
                          BoxShadow(
                            color: avatarGradient.colors.first.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    // Online indicator
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF22C55E),
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Name + preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Timestamp pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    timeStr,
                    style: tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              indent: 90,
              endIndent: 20,
              color: cs.outline.withValues(alpha: 0.2),
            ),
        ],
      ),
    );
  }
}

// ── Split screen empty placeholder ─────────────────────────────────────────────

class _SplitEmptyChatPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.2),
                  const Color(0xFF4F46E5).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nexora Desktop',
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a conversation on the left to start chatting,\nor tap + to start a new chat or create a group room.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

