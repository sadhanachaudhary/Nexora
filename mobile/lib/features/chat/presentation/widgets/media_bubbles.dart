import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/models/message.dart';

// ── Image Bubble Widget ────────────────────────────────────────────────────────

class ImageBubbleWidget extends StatelessWidget {
  final String imageUrl;
  final bool isMe;

  const ImageBubbleWidget({
    super.key,
    required this.imageUrl,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageUrl.startsWith('data:image')) {
      imageWidget = Image.memory(
        base64Decode(imageUrl.split(',')[1]),
        fit: BoxFit.cover,
        width: 220,
        height: 180,
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 220,
        height: 180,
        placeholder: (_, __) => Container(
          width: 220,
          height: 180,
          color: Colors.grey.withValues(alpha: 0.15),
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 220,
          height: 140,
          color: Colors.grey.withValues(alpha: 0.2),
          child: const Center(child: Icon(Icons.broken_image_rounded)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GestureDetector(
        onTap: () => _openZoomDialog(context, imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: imageWidget,
        ),
      ),
    );
  }

  void _openZoomDialog(BuildContext context, String url) {
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

// ── Voice Bubble Widget ────────────────────────────────────────────────────────

class VoiceBubbleWidget extends StatefulWidget {
  final Message message;
  final bool isMe;

  const VoiceBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<VoiceBubbleWidget> createState() => _VoiceBubbleWidgetState();
}

class _VoiceBubbleWidgetState extends State<VoiceBubbleWidget>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _animCtrl.repeat();
      // Auto stop simulation after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _isPlaying = false);
          _animCtrl.stop();
        }
      });
    } else {
      _animCtrl.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final durationSecs = int.tryParse(widget.message.content ?? '5') ?? 5;
    final mins = (durationSecs ~/ 60).toString().padLeft(2, '0');
    final secs = (durationSecs % 60).toString().padLeft(2, '0');

    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withValues(alpha: 0.25)
                    : cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: widget.isMe ? Colors.white : cs.primary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Animated waveform bars
          Expanded(
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(12, (i) {
                  final wave = _isPlaying
                      ? (sin((_animCtrl.value * 6.28) + i * 0.5).abs() * 14.0 + 4.0)
                      : ((i % 3 + 1) * 4.0 + 3.0);
                  return Container(
                    width: 3,
                    height: wave,
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? Colors.white.withValues(alpha: 0.85)
                          : cs.primary.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Duration label
          Text(
            '$mins:$secs',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.isMe
                  ? Colors.white.withValues(alpha: 0.8)
                  : cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Location Bubble Widget ─────────────────────────────────────────────────────

class LocationBubbleWidget extends StatelessWidget {
  final String content;
  final bool isMe;

  const LocationBubbleWidget({
    super.key,
    required this.content,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String name = 'Shared Location';
    double lat = 37.7749;
    double lng = -122.4194;

    try {
      final data = jsonDecode(content);
      if (data is Map) {
        name = data['name'] ?? 'Shared Location';
        lat = (data['lat'] as num?)?.toDouble() ?? 37.7749;
        lng = (data['lng'] as num?)?.toDouble() ?? -122.4194;
      }
    } catch (_) {}

    return Container(
      width: 220,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.15)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? Colors.white.withValues(alpha: 0.2)
              : cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Graphic Map card header
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E293B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Grid lines pattern
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: isMe ? Colors.white : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lat.toStringAsFixed(4)}°, ${lng.toStringAsFixed(4)}°',
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += 20) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Document Bubble Widget ───────────────────────────────────────────────────

class DocumentBubbleWidget extends StatelessWidget {
  final String content;
  final bool isMe;

  const DocumentBubbleWidget({
    super.key,
    required this.content,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    String fileName = 'Document.pdf';
    String fileSize = '1.2 MB';
    try {
      final data = jsonDecode(content);
      if (data is Map) {
        fileName = data['name'] ?? 'Document.pdf';
        fileSize = data['size'] ?? '1.2 MB';
      }
    } catch (_) {
      fileName = content;
    }

    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.15)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.2)
                  : cs.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.description_rounded,
              color: isMe ? Colors.white : cs.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    color: isMe ? Colors.white : cs.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  fileSize,
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              Icons.download_rounded,
              color: isMe ? Colors.white70 : cs.primary,
              size: 20,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading $fileName...')),
              );
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
