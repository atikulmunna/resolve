import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Builds the two-lobe lung silhouette (plus a central airway) sized to [size].
/// Shared by the big filling lung on the craving screen and the small glyph on
/// the home panic button, so they read as the same organ.
Path buildLungPath(Size size, {bool includeAirway = true}) {
  final w = size.width, h = size.height;
  double px(double fx) => fx * w;
  double py(double fy) => fy * h;

  // Right lobe (viewer's right), as four cubic curves. Fractions of the box.
  final right = Path()
    ..moveTo(px(0.54), py(0.30)) // top-inner, by the carina
    ..cubicTo(px(0.60), py(0.21), px(0.84), py(0.23), px(0.84), py(0.38))
    ..cubicTo(px(0.93), py(0.48), px(0.90), py(0.79), px(0.77), py(0.90))
    ..cubicTo(px(0.70), py(0.95), px(0.60), py(0.95), px(0.56), py(0.87))
    ..cubicTo(px(0.53), py(0.69), px(0.57), py(0.47), px(0.54), py(0.30))
    ..close();

  // Left lobe: mirror of the right about the vertical centre.
  final left = Path()
    ..moveTo(px(0.46), py(0.30))
    ..cubicTo(px(0.40), py(0.21), px(0.16), py(0.23), px(0.16), py(0.38))
    ..cubicTo(px(0.07), py(0.48), px(0.10), py(0.79), px(0.23), py(0.90))
    ..cubicTo(px(0.30), py(0.95), px(0.40), py(0.95), px(0.44), py(0.87))
    ..cubicTo(px(0.47), py(0.69), px(0.43), py(0.47), px(0.46), py(0.30))
    ..close();

  final lung = Path()
    ..addPath(right, Offset.zero)
    ..addPath(left, Offset.zero);

  if (includeAirway) {
    // Trachea + carina: a vertical tube splitting into the two lobes.
    final airway = Path()
      ..moveTo(px(0.47), py(0.10))
      ..lineTo(px(0.53), py(0.10))
      ..lineTo(px(0.53), py(0.28))
      ..cubicTo(px(0.53), py(0.31), px(0.55), py(0.31), px(0.56), py(0.33))
      ..lineTo(px(0.545), py(0.35))
      ..cubicTo(px(0.52), py(0.31), px(0.50), py(0.31), px(0.50), py(0.29))
      ..cubicTo(px(0.50), py(0.31), px(0.48), py(0.31), px(0.455), py(0.35))
      ..lineTo(px(0.44), py(0.33))
      ..cubicTo(px(0.45), py(0.31), px(0.47), py(0.31), px(0.47), py(0.28))
      ..close();
    lung.addPath(airway, Offset.zero);
  }

  return lung;
}

/// The living lung on the craving screen: an emerald outline that fills with
/// glowing liquid on the inhale and drains on the exhale. [fill] is 0..1, [t]
/// seconds (drives the surface shimmer and rising bubbles).
class LungPainter extends CustomPainter {
  const LungPainter({required this.fill, required this.t});

  final double fill;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final lung = buildLungPath(size, includeAirway: true);

    // Empty-lung outline, always visible and faint, so the organ reads even at 0.
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.emerald400.withValues(alpha: 0.5);

    // Liquid, clipped to the lung.
    canvas.save();
    canvas.clipPath(lung);

    // Fill spans the lobes' vertical extent; a wavy, shimmering surface.
    final topY = size.height * 0.20;
    final botY = size.height * 0.96;
    final surfaceY = botY - fill.clamp(0.0, 1.0) * (botY - topY);

    if (fill > 0.001) {
      final waveAmp = 5.0 * (0.4 + 0.6 * fill);
      final surface = Path()..moveTo(0, size.height);
      surface.lineTo(0, surfaceY);
      for (double x = 0; x <= size.width; x += 6) {
        final y = surfaceY +
            math.sin(x * 0.05 + t * 2.2) * waveAmp +
            math.sin(x * 0.11 - t * 1.3) * waveAmp * 0.4;
        surface.lineTo(x, y);
      }
      surface
        ..lineTo(size.width, size.height)
        ..close();

      final liquid = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, surfaceY),
          Offset(0, botY),
          [
            AppColors.emerald300.withValues(alpha: 0.92),
            AppColors.emerald500.withValues(alpha: 0.95),
            AppColors.emerald600,
          ],
          const [0.0, 0.5, 1.0],
        );
      canvas.drawPath(surface, liquid);

      // Bright meniscus line riding the surface.
      final meniscus = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.mintNode.withValues(alpha: 0.85);
      final crest = Path();
      var started = false;
      for (double x = 0; x <= size.width; x += 6) {
        final y = surfaceY +
            math.sin(x * 0.05 + t * 2.2) * waveAmp +
            math.sin(x * 0.11 - t * 1.3) * waveAmp * 0.4;
        if (!started) {
          crest.moveTo(x, y);
          started = true;
        } else {
          crest.lineTo(x, y);
        }
      }
      canvas.drawPath(crest, meniscus);

      // Rising bubbles for life, only while there's liquid.
      final bubble = Paint()..color = AppColors.mintNode.withValues(alpha: 0.5);
      for (var i = 0; i < 7; i++) {
        final bx = size.width * (0.18 + 0.64 * ((i * 37) % 100) / 100);
        final speed = 0.35 + (i % 3) * 0.12;
        final phase = ((t * speed) + i * 0.6) % 1.0;
        final by = botY - phase * (botY - surfaceY);
        if (by <= surfaceY + 4) continue; // popped at the surface
        final r = 1.6 + (i % 3) * 0.9;
        canvas.drawCircle(
          Offset(bx, by),
          r,
          bubble..color = AppColors.mintNode.withValues(alpha: 0.45 * (1 - phase)),
        );
      }
    }
    canvas.restore();

    // Outline on top so the rim stays crisp over the liquid.
    canvas.drawPath(lung, outline);
  }

  @override
  bool shouldRepaint(LungPainter old) => old.fill != fill || old.t != t;
}

/// A small solid lung silhouette for the home panic button.
class LungGlyphPainter extends CustomPainter {
  const LungGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final lung = buildLungPath(size, includeAirway: true);
    canvas.drawPath(lung, Paint()..color = color);
  }

  @override
  bool shouldRepaint(LungGlyphPainter old) => old.color != color;
}
