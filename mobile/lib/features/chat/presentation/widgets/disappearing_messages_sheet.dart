import 'package:flutter/material.dart';

class DisappearingMessagesSheet extends StatelessWidget {
  final String currentTimer;
  final ValueChanged<String> onSelected;

  const DisappearingMessagesSheet({
    super.key,
    required this.currentTimer,
    required this.onSelected,
  });

  static void show(
    BuildContext context, {
    required String currentTimer,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DisappearingMessagesSheet(
        currentTimer: currentTimer,
        onSelected: (val) {
          Navigator.pop(ctx);
          onSelected(val);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                    color: cs.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    color: cs.primary,
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
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              return RadioListTile<String>(
                title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w600)),
                value: opt,
                groupValue: currentTimer,
                onChanged: (val) {
                  if (val != null) {
                    onSelected(val);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
