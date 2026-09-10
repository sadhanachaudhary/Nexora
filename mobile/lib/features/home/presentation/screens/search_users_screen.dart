import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../chat/data/repositories/user_repository.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/domain/models/user.dart';
import '../../../chat/presentation/providers/conversations_provider.dart';
import '../../../../core/widgets/app_avatar.dart';

final searchUsersProvider = FutureProvider.family<List<User>, String>((ref, query) async {
  return ref.watch(userRepositoryProvider).searchUsers(query.trim());
});

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _isConnecting = false;

  bool _isEmail(String text) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(text.trim());
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['error'] != null) {
        final err = data['error'].toString();
        if (err.toLowerCase().contains('prisma') ||
            err.toLowerCase().contains('invocation') ||
            err.toLowerCase().contains('syntax') ||
            err.length > 100) {
          return 'Unable to process request right now. Please try again.';
        }
        return err;
      }
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (e.response?.statusCode == 404) {
        return 'User or conversation not found.';
      }
      if (e.response?.statusCode == 500) {
        return 'The server encountered an issue. Please try again.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        return 'Unable to reach the server. Please verify your connection.';
      }
    }
    final raw = e.toString().replaceFirst('Exception: ', '');
    if (raw.toLowerCase().contains('prisma') ||
        raw.toLowerCase().contains('syntax') ||
        raw.length > 100) {
      return 'Unable to search users right now. Please try again.';
    }
    return raw;
  }

  void _showErrorFeedback(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'User Not Found',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 14.5,
            height: 1.4,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => ctx.pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _startConversationWithUser(User targetUser) async {
    setState(() => _isConnecting = true);
    try {
      final repository = ref.read(chatRepositoryProvider);
      final conversation = await repository.createDirectConversation(targetUser.id);
      ref.invalidate(conversationsProvider);
      if (mounted) {
        context.pushReplacement(
          '/chat/${conversation.id}',
          extra: {'name': targetUser.name ?? targetUser.username},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        _showErrorFeedback(_extractError(e));
      }
    }
  }

  void _startConversationByEmail(String email) async {
    setState(() => _isConnecting = true);
    try {
      final repository = ref.read(chatRepositoryProvider);
      final conversation = await repository.createDirectConversationByEmail(email);
      ref.invalidate(conversationsProvider);
      if (mounted) {
        context.pushReplacement(
          '/chat/${conversation.id}',
          extra: {'name': email},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        final rawErr = _extractError(e);
        final friendlyMsg = rawErr.toLowerCase().contains('no user found')
            ? 'No Nexora account is registered with "$email". Please check the address or ask them to register first.'
            : rawErr;
        _showErrorFeedback(friendlyMsg);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEmailQuery = _isEmail(_query);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leadingWidth: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add & Find People'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline.withValues(alpha: 0.25)),
        ),
      ),
      body: _isConnecting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: cs.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Opening conversation...',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Search bar ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Icon(
                            Icons.alternate_email_rounded,
                            color: cs.primary,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: tt.bodyLarge,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Search by email, name, or username...',
                              hintStyle: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.35),
                                fontSize: 14.5,
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (val) => setState(() => _query = val.trim()),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.cancel_rounded,
                              color: cs.onSurface.withValues(alpha: 0.35),
                              size: 20,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Create New Group Action ────────────────────
                if (_query.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      onTap: () => context.push('/create-group'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create New Group',
                                    style: tt.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Chat with multiple friends or teammates',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: cs.onSurface.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Direct Add by Email Card when email pattern detected ──
                if (isEmailQuery)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      onTap: () => _startConversationByEmail(_query),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF7C3AED).withValues(alpha: 0.15),
                              const Color(0xFF4F46E5).withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connect via Email ID',
                                    style: tt.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _query,
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurface.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Add & Chat',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: Text(
                    _query.isEmpty ? 'SUGGESTED CONTACTS' : 'RESULTS',
                    style: tt.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),

                // ── Search Results List ────────────────────────────
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final result = ref.watch(searchUsersProvider(_query));
                      return result.when(
                        data: (users) {
                          if (users.isEmpty) {
                            return _query.isEmpty
                                ? _SearchEmptyHint()
                                : _NoResultsState(query: _query);
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            itemCount: users.length,
                            itemBuilder: (ctx, i) => _UserCard(
                              user: users[i],
                              onTap: () => _startConversationWithUser(users[i]),
                            ),
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (err, _) => _SearchErrorState(
                          message: _extractError(err),
                          onRetry: () => ref.invalidate(searchUsersProvider(_query)),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;
  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final displayName = user.name ?? user.username;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              AppAvatar(
                avatarUrl: user.avatarUrl,
                name: displayName,
                size: 50,
                fontSize: 18,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '@${user.username}',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (user.email != null) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              user.email!,
                              style: tt.bodySmall?.copyWith(
                                color: cs.primary.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: cs.onSurface.withValues(alpha: 0.4), size: 18),
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val == 'block') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Blocked @${user.username}')),
                    );
                  } else if (val == 'audio_call') {
                    context.push('/call', extra: {'isAudio': true, 'name': displayName, 'avatarUrl': user.avatarUrl});
                  } else if (val == 'video_call') {
                    context.push('/call', extra: {'isAudio': false, 'name': displayName, 'avatarUrl': user.avatarUrl});
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'audio_call',
                    child: Row(
                      children: [
                        Icon(Icons.call_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Voice Call'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'video_call',
                    child: Row(
                      children: [
                        Icon(Icons.videocam_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Video Call'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Block User', style: TextStyle(color: Colors.red)),
                      ],
                    ),
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

// ── Search Error State ────────────────────────────────────────────────────────

class _SearchErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _SearchErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 14),
            Text(
              'Couldn\'t search users',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.5),
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty hint ────────────────────────────────────────────────────────────────

class _SearchEmptyHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 52,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Anyone by Email or Username',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter an email address, username, or name to connect and start chatting.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No results ────────────────────────────────────────────────────────────────

class _NoResultsState extends StatelessWidget {
  final String query;
  const _NoResultsState({required this.query});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: cs.onSurface.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found for "$query"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check the spelling or make sure this person has created an account on Nexora.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
