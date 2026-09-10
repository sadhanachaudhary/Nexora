import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_avatar.dart';

class CallScreen extends StatefulWidget {
  final String conversationId;
  final String name;
  final String? avatarUrl;
  final bool isVideo;

  const CallScreen({
    super.key,
    required this.conversationId,
    required this.name,
    this.avatarUrl,
    this.isVideo = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isSpeaker = false;
  late bool _isVideoOn;
  bool _isFrontCamera = true;
  bool _isConnected = false;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  Timer? _connectTimer;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _isVideoOn = widget.isVideo;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.16).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate connection after 2 seconds
    _connectTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
        _startCallTimer();
      }
    });
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _connectTimer?.cancel();
    _callTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _endCall() {
    _connectTimer?.cancel();
    _callTimer?.cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B18),
      body: Stack(
        children: [
          // ── Background & Video Preview Layer ────────────────────────
          if (_isVideoOn) ...[
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF0F0D1A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppAvatar(
                        avatarUrl: widget.avatarUrl,
                        name: widget.name,
                        size: 140,
                        fontSize: 54,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _isFrontCamera
                              ? '🎥 HD Camera Active'
                              : '📷 Rear Camera Active',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Self view picture-in-picture
            Positioned(
              top: 54,
              right: 20,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF221F35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      const Text(
                        'You',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.videocam_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Voice Call Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.2,
                    colors: [
                      Color(0xFF311042),
                      Color(0xFF0F0D1A),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ── Main Content Info Layer ─────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Top encryption status bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.lock_rounded, size: 13, color: Color(0xFF22C55E)),
                      SizedBox(width: 6),
                      Text(
                        'End-to-End Encrypted Call',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Center Avatar with pulsing rings (in Voice mode)
                if (!_isVideoOn) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ScaleTransition(
                            scale: _pulseAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF7C3AED)
                                    .withValues(alpha: 0.15),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.25),
                                ),
                                child: AppAvatar(
                                  avatarUrl: widget.avatarUrl,
                                  name: widget.name,
                                  size: 110,
                                  fontSize: 44,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isConnected
                                ? _formatDuration(_callDurationSeconds)
                                : 'Calling...',
                            style: TextStyle(
                              color: _isConnected
                                  ? const Color(0xFF22C55E)
                                  : Colors.white60,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Spacer(),
                  // In video mode, show name and duration at bottom
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isConnected
                              ? _formatDuration(_callDurationSeconds)
                              : 'Connecting video...',
                          style: TextStyle(
                            color: _isConnected
                                ? const Color(0xFF22C55E)
                                : Colors.white60,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Controls Bottom Bar ──────────────────────────────────
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Mute button
                      _CallActionButton(
                        icon: _isMuted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        isActive: _isMuted,
                        activeColor: Colors.white24,
                        onTap: () => setState(() => _isMuted = !_isMuted),
                      ),

                      // Video toggle button
                      _CallActionButton(
                        icon: _isVideoOn
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        isActive: _isVideoOn,
                        activeColor: const Color(0xFF7C3AED),
                        onTap: () => setState(() => _isVideoOn = !_isVideoOn),
                      ),

                      // Speaker button
                      _CallActionButton(
                        icon: _isSpeaker
                            ? Icons.volume_up_rounded
                            : Icons.volume_down_rounded,
                        isActive: _isSpeaker,
                        activeColor: const Color(0xFF7C3AED),
                        onTap: () => setState(() => _isSpeaker = !_isSpeaker),
                      ),

                      // Camera flip (if video is on)
                      if (_isVideoOn)
                        _CallActionButton(
                          icon: Icons.flip_camera_ios_rounded,
                          isActive: false,
                          onTap: () => setState(
                              () => _isFrontCamera = !_isFrontCamera),
                        ),

                      // End call button
                      _CallActionButton(
                        icon: Icons.call_end_rounded,
                        isDestructive: true,
                        onTap: _endCall,
                      ),
                    ],
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

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isDestructive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    this.isActive = false,
    this.isDestructive = false,
    this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color iconColor;

    if (isDestructive) {
      backgroundColor = const Color(0xFFEF4444);
      iconColor = Colors.white;
    } else if (isActive) {
      backgroundColor = activeColor ?? const Color(0xFF7C3AED);
      iconColor = Colors.white;
    } else {
      backgroundColor = Colors.white.withValues(alpha: 0.12);
      iconColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: 24),
        ),
      ),
    );
  }
}
