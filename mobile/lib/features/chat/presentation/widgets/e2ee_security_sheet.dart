import 'package:flutter/material.dart';

class E2EESecuritySheet extends StatelessWidget {
  final String displayName;

  const E2EESecuritySheet({
    super.key,
    required this.displayName,
  });

  static void show(BuildContext context, String displayName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => E2EESecuritySheet(displayName: displayName),
    );
  }

  @override
  Widget build(BuildContext context) {
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

            // 60-digit safety numbers in 3 rows
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
                  Navigator.pop(context);
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
  }
}
