import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// A floating-glass surface (Design Spec §3.1 "floating-glass"): live blur +
/// translucent gradient fill + hairline border + inner top highlight + a drop
/// shadow so it lifts off the AMOLED black. Use for chips, menu pieces, and
/// glass buttons.
class FloatingGlass extends StatelessWidget {
  const FloatingGlass({
    super.key,
    required this.child,
    this.radius = 16,
    this.blur = 14,
    this.padding = EdgeInsets.zero,
    this.shadow = _defaultShadow,
  });

  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final List<BoxShadow> shadow;

  static const List<BoxShadow> _defaultShadow = [
    BoxShadow(color: Color(0x8C000000), blurRadius: 30, offset: Offset(0, 14)),
  ];

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    // Outer box carries the drop shadow (outside the clip); inner clip carries
    // the blur, gradient, and border highlight.
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: shadow),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.09),
                  Colors.white.withValues(alpha: 0.018),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

