import 'package:flutter/material.dart';

class AttachmentActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const AttachmentActionItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class AttachmentSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onDocument;
  final VoidCallback onLocation;
  final VoidCallback onContact;

  const AttachmentSheet({
    super.key,
    required this.onCamera,
    required this.onGallery,
    required this.onDocument,
    required this.onLocation,
    required this.onContact,
  });

  static void show(
    BuildContext context, {
    required VoidCallback onCamera,
    required VoidCallback onGallery,
    required VoidCallback onDocument,
    required VoidCallback onLocation,
    required VoidCallback onContact,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AttachmentSheet(
        onCamera: () {
          Navigator.pop(ctx);
          onCamera();
        },
        onGallery: () {
          Navigator.pop(ctx);
          onGallery();
        },
        onDocument: () {
          Navigator.pop(ctx);
          onDocument();
        },
        onLocation: () {
          Navigator.pop(ctx);
          onLocation();
        },
        onContact: () {
          Navigator.pop(ctx);
          onContact();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: cs.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              AttachmentActionItem(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                color: const Color(0xFFEF4444),
                onTap: onCamera,
              ),
              AttachmentActionItem(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                color: const Color(0xFF8B5CF6),
                onTap: onGallery,
              ),
              AttachmentActionItem(
                icon: Icons.insert_drive_file_rounded,
                label: 'Document',
                color: const Color(0xFF3B82F6),
                onTap: onDocument,
              ),
              AttachmentActionItem(
                icon: Icons.location_on_rounded,
                label: 'Location',
                color: const Color(0xFF10B981),
                onTap: onLocation,
              ),
              AttachmentActionItem(
                icon: Icons.person_rounded,
                label: 'Contact',
                color: const Color(0xFFF59E0B),
                onTap: onContact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
