import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// A 3D wave-flow field: a dense grid of points riding an undulating height
/// surface, rendered in perspective from a low camera angle so ridges stream
/// toward the viewer and recede into the distance (à la Trapcode Form). Points
/// are bucketed into a few depth tiers and drawn batched via [drawRawPoints]
/// (a handful of GPU calls, not thousands), then clipped to the disc. Drives
/// the home dial's living glass.
class WaveFieldPainter extends CustomPainter {
  const WaveFieldPainter(this.t, {this.clipToDisc = true});

  /// Elapsed seconds; drives the wave motion.
  final double t;

  /// The dial clips to its circle; the widget image fills a rounded rect.
  final bool clipToDisc;

  static const int _cols = 80; // left-right resolution
  static const int _rows = 56; // depth resolution
  static const int _tiers = 4; // depth/brightness buckets

  // Camera.
  static const double _camY = 0.72; // height above the surface
  static const double _pitch = 0.42; // downward tilt (radians)
  static const double _zNear = 0.55;
  static const double _zFar = 4.2;
  static const double _halfWidth = 2.4; // surface half-extent (x)
  static const double _amp = 0.34; // wave height

  // Flowing height field from summed sines (cheap, seamless, no wrap).
  double _height(double x, double z) =>
      _amp *
      (0.55 * math.sin(x * 1.2 + t * 0.85) +
          0.45 * math.sin(z * 0.85 - t * 0.6) +
          0.35 * math.sin((x + z) * 0.9 + t * 0.7) +
          0.28 * math.sin((x - z) * 1.6 - t * 0.5));

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2, cy = h / 2;
    final radius = w / 2;
    final focal = w * 0.92;
    final cosP = math.cos(_pitch), sinP = math.sin(_pitch);

    // One growing point-buffer per depth tier; tiers get brighter/larger.
    final buffers = List.generate(_tiers, (_) => <double>[]);

    for (var j = 0; j < _rows; j++) {
      final v = j / (_rows - 1); // 0 far .. 1 near
      final z = _zFar + (_zNear - _zFar) * v; // world depth
      for (var i = 0; i < _cols; i++) {
        final u = -1 + 2 * i / (_cols - 1);
        final x = u * _halfWidth;
        final y = _height(x, z); // surface height

        // Camera space: tilt about X, translate by camera height.
        final yc = (y - _camY) * cosP + z * sinP;
        final zc = z * cosP - (y - _camY) * sinP;
        if (zc < 0.05) continue; // behind camera

        final px = cx + focal * x / zc;
        final py = cy - focal * yc / zc;

        if (clipToDisc) {
          final dx = px - cx, dy = py - cy;
          if (dx * dx + dy * dy >= radius * radius) continue; // clip to disc
        }

        // Nearer points (small zc) -> higher tier.
        final depth01 = ((zc - _zNear) / (_zFar - _zNear)).clamp(0.0, 1.0);
        var tier = ((1 - depth01) * _tiers).floor();
        if (tier >= _tiers) tier = _tiers - 1;
        buffers[tier]
          ..add(px)
          ..add(py);
      }
    }

    for (var tier = 0; tier < _tiers; tier++) {
      final pts = buffers[tier];
      if (pts.isEmpty) continue;
      final near = tier / (_tiers - 1); // 0 far .. 1 near
      final color = Color.lerp(AppColors.emerald600, AppColors.mintNode, near)!;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.0 + 1.6 * near
        ..color = color.withValues(alpha: 0.28 + 0.5 * near);
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.fromList(pts),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveFieldPainter old) =>
      old.t != t || old.clipToDisc != clipToDisc;
}
