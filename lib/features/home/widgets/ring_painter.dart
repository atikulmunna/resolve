import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// The 60-second circular progress ring (Design Spec §2.6 / SRS §6.2).
///
/// `p = (elapsedMs % 60000)/60000`; the arc sweeps from -90° (top) clockwise,
/// a glowing mint node rides the leading edge. Gradient 6ee7b7->2dd4bf->10b981
/// (a whisper of teal in the mid stop), round cap, soft emerald glow.
class RingPainter extends CustomPainter {
  const RingPainter({required this.progress});

  /// 0..1 fill of the current minute.
  final double progress;

  static const double _radius = 110;
  static const double _stroke = 7;
  static const double _start = -math.pi / 2; // 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: _radius);
    final sweep = (2 * math.pi) * progress.clamp(0.0, 1.0);

    // Borderless: no full-circle track. Only the glowing progress arc + node.
    if (sweep <= 0) return;

    // Emerald drop-shadow glow beneath the arc (drop-shadow 0 0 6px .9).
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.emerald500.withValues(alpha: 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(rect, _start, sweep, false, glow);

    // Progress arc with the emerald gradient along its sweep.
    final gradient = SweepGradient(
      startAngle: _start,
      endAngle: _start + 2 * math.pi,
      colors: const [
        AppColors.emerald300,
        AppColors.teal400,
        AppColors.emerald500,
      ],
      stops: const [0.0, 0.55, 1.0],
      transform: GradientRotation(_start),
    );
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..shader = gradient.createShader(rect);
    canvas.drawArc(rect, _start, sweep, false, arc);

    // Leading node - mint circle r=6 with a bright glow.
    final angle = _start + sweep;
    final node = center + Offset(math.cos(angle), math.sin(angle)) * _radius;
    canvas.drawCircle(
      node,
      6,
      Paint()
        ..color = AppColors.emerald400
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(node, 6, Paint()..color = AppColors.mintNode);
  }

  @override
  bool shouldRepaint(RingPainter old) => old.progress != progress;
}
