import 'package:flutter/material.dart';

class VoiceRecordingBar extends StatelessWidget {
  final int recordDuration;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  const VoiceRecordingBar({
    super.key,
    required this.recordDuration,
    required this.onCancel,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mins = (recordDuration ~/ 60).toString().padLeft(2, '0');
    final secs = (recordDuration % 60).toString().padLeft(2, '0');

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
                    final h = ((i % 4 + 1) * 5.0) + (recordDuration % 2 == 0 ? 4 : 0);
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
              onPressed: onCancel,
            ),
            const SizedBox(width: 6),
            // Send Voice Note button
            GestureDetector(
              onTap: onSend,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
