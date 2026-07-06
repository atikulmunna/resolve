import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/phase.dart';
import '../../../theme/app_colors.dart';

/// The send-off mark for the "start the clock" step. Unlike the logo-like
/// [BrandMark], this is a moment: a core that pumps like a heartbeat (lub-dub,
/// once per second) with rings igniting outward from it - the streak coming
/// alive, echoing Home's "ALIVE" pulse. Beat is synced to the 1s [clock].
class IgnitionMark extends StatelessWidget {
  const IgnitionMark({super.key, required this.clock, this.size = 150});

  final Listenable clock;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final beat = Phase.loop(const Duration(seconds: 1)); // one beat / sec
          final breathe = Phase.pingPong(const Duration(milliseconds: 3200));
          return CustomPaint(
            painter: _IgnitionPainter(beat: beat, breathe: breathe),
          );
        },
      ),
    );
  }
}

class _IgnitionPainter extends CustomPainter {
  _IgnitionPainter({required this.beat, required this.breathe});

  final double beat; // 0..1, loops every second
  final double breathe; // 0..1 ping-pong

  // Twin-bump ("lub-dub") heartbeat envelope over the beat.
  double _pump(double t) {
    double bump(double at, double w, double h) =>
        h * math.exp(-math.pow((t - at) / w, 2));
    return bump(0.10, 0.05, 1.0) + bump(0.27, 0.07, 0.55);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;
    final pump = _pump(beat);

    // Breathing ambient halo.
    final haloR = maxR * (0.72 + 0.06 * breathe);
    canvas.drawCircle(
      c,
      haloR,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.emerald500.withValues(alpha: 0.16 + 0.10 * breathe),
            AppColors.emerald500.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: haloR)),
    );

    // Rings igniting outward - three, staggered a third of a beat apart.
    for (var i = 0; i < 3; i++) {
      final phase = (beat + i / 3) % 1.0;
      final r = maxR * (0.15 + phase * 0.82);
      final opacity = (1 - phase) * 0.5;
      final color = i == 2 ? AppColors.aqua400 : AppColors.emerald400;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * (1 - phase) + 0.6
          ..color = color.withValues(alpha: opacity),
      );
    }

    // Pumping core: soft glow + mint body + white-hot center.
    final coreR = maxR * (0.11 + 0.055 * pump);
    canvas.drawCircle(
      c,
      coreR * 2.4,
      Paint()
        ..color = AppColors.emerald400.withValues(alpha: 0.28 + 0.42 * pump)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, coreR * 1.1),
    );
    canvas.drawCircle(c, coreR, Paint()..color = AppColors.mintNode);
    canvas.drawCircle(c, coreR * 0.5, Paint()..color = AppColors.textHi);
  }

  @override
  bool shouldRepaint(_IgnitionPainter old) =>
      old.beat != beat || old.breathe != breathe;
}
