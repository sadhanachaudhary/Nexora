import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final bool showOnline;
  final bool isOnline;
  final double fontSize;

  const AppAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 48,
    this.showOnline = false,
    this.isOnline = true,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isNotEmpty ? name.trim() : '?';
    final initial = displayName[0].toUpperCase();
    final gradient = AppTheme.avatarGradient(displayName.codeUnitAt(0));

    Widget avatarContent;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatarContent = Image.network(
        avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildGradientFallback(gradient, initial),
      );
    } else {
      avatarContent = _buildGradientFallback(gradient, initial);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withValues(alpha: 0.25),
                blurRadius: size * 0.2,
                offset: Offset(0, size * 0.08),
              ),
            ],
          ),
          child: ClipOval(
            child: avatarContent,
          ),
        ),
        if (showOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: (size * 0.28).clamp(10.0, 16.0),
              height: (size * 0.28).clamp(10.0, 16.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? const Color(0xFF22C55E) : Colors.grey,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGradientFallback(LinearGradient gradient, String initial) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}
