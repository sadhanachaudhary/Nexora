import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../chat/data/repositories/user_repository.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/domain/models/user.dart';
import '../../../chat/presentation/providers/conversations_provider.dart';
import '../../../../core/widgets/app_avatar.dart';

final allContactsProvider = FutureProvider<List<User>>((ref) async {
  return ref.watch(userRepositoryProvider).searchUsers('');
});

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  final Map<String, User> _selectedUsers = {};
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleUser(User user) {
    setState(() {
      if (_selectedUserIds.contains(user.id)) {
        _selectedUserIds.remove(user.id);
        _selectedUsers.remove(user.id);
      } else {
        _selectedUserIds.add(user.id);
        _selectedUsers[user.id] = user;
      }
    });
  }

  void _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member to add'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final repository = ref.read(chatRepositoryProvider);
      final conversation = await repository.createGroupConversation(
        name,
        _selectedUserIds.toList(),
      );

      ref.invalidate(conversationsProvider);

      if (mounted) {
        context.pushReplacement(
          '/chat/${conversation.id}',
          extra: {'name': name},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        String err = e.toString();
        if (e is DioException && e.response?.data is Map) {
          err = e.response?.data['error'] ?? 'Could not create group';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final contactsAsync = ref.watch(allContactsProvider);
    final currentUserId = ref.watch(currentUserProvider).value?.id ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leadingWidth: 44,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('New Group'),
        actions: [
          if (_selectedUserIds.isNotEmpty)
            TextButton(
              onPressed: _isCreating ? null : _createGroup,
              child: _isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Create',
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline.withValues(alpha: 0.25)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group Name Input ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
                    ),
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      style: tt.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Group Name (e.g. Design Team)',
                        hintStyle: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.35),
                          fontSize: 15,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Selected Members Horizontal Scroll ───────────────
          if (_selectedUsers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'SELECTED MEMBERS (${_selectedUsers.length})',
                style: tt.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: cs.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _selectedUsers.values.map((u) {
                  final name = u.name ?? u.username;

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => _toggleUser(u),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              AppAvatar(
                                avatarUrl: u.avatarUrl,
                                name: name,
                                size: 44,
                                fontSize: 16,
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 48,
                                child: Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Search Field for Members ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(
                      Icons.search_rounded,
                      color: cs.onSurface.withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: tt.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search people to add...',
                        hintStyle: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.35),
                          fontSize: 14,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.cancel_rounded,
                        color: cs.onSurface.withValues(alpha: 0.35),
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),
          ),

          // Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
            child: Text(
              'SELECT CONTACTS',
              style: tt.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),

          // ── Contact Selection List ───────────────────────────
          Expanded(
            child: contactsAsync.when(
              data: (users) {
                // Filter out current logged in user & apply search query
                final filtered = users.where((u) {
                  if (u.id == currentUserId) return false;
                  if (_searchQuery.isEmpty) return true;
                  final q = _searchQuery.toLowerCase();
                  final nameMatch = u.name?.toLowerCase().contains(q) ?? false;
                  final usernameMatch = u.username.toLowerCase().contains(q);
                  final emailMatch = u.email?.toLowerCase().contains(q) ?? false;
                  return nameMatch || usernameMatch || emailMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No contacts available'
                          : 'No contacts matching "$_searchQuery"',
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final user = filtered[i];
                    final isSelected = _selectedUserIds.contains(user.id);
                    final displayName = user.name ?? user.username;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _toggleUser(user),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary.withValues(alpha: 0.1)
                                : cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? cs.primary.withValues(alpha: 0.5)
                                  : cs.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              AppAvatar(
                                avatarUrl: user.avatarUrl,
                                name: displayName,
                                size: 44,
                                fontSize: 16,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: tt.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '@${user.username}${user.email != null ? ' • ${user.email}' : ''}',
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? cs.primary
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? cs.primary
                                        : cs.outline.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedUserIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(
                  top: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createGroup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isCreating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Create Group (${_selectedUserIds.length} members)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
