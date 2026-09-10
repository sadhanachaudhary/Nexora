import 'package:flutter/material.dart';
import '../../../../core/widgets/app_avatar.dart';

class EmptyChatState extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const EmptyChatState({
    super.key,
    required this.name,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppAvatar(
            avatarUrl: avatarUrl,
            name: name,
            size: 72,
            fontSize: 28,
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
