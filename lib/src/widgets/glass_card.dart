// lib/src/widgets/glass_card.dart
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppTheme().buildGlass(child, borderRadius: radius);

    if (onTap == null) return card;

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}

class PressableGlassCard extends StatefulWidget {
  final Widget child;
  final double radius;
  final VoidCallback? onTap;

  const PressableGlassCard({
    super.key,
    required this.child,
    this.radius = 20,
    this.onTap,
  });

  @override
  State<PressableGlassCard> createState() => _PressableGlassCardState();
}

class _PressableGlassCardState extends State<PressableGlassCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.995 : 1.0;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        duration: AppTheme.motionMedium,
        scale: scale,
        child: AppTheme().buildGlass(widget.child, borderRadius: widget.radius),
      ),
    );
  }
}