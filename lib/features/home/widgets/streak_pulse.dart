import 'package:flutter/material.dart';

import '../../../core/phase.dart';
import '../../../models/relapse.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Streak pulse - the live EKG heart monitor (Design Spec §3.1 / FR-8).
///
/// A tiled beat pattern scrolls right→left at exactly one beat per second,
/// synced to the ticking timer (8 beats over 8s). The tile is drawn twice so
/// the loop is seamless. A bright write-head at the right edge is "now"; the
/// left edge fades; relapses are pinned red scars on the baseline. No count,
/// no legend - the meaning is self-evident.
class StreakPulse extends StatelessWidget {
  const StreakPulse({
    super.key,
    required this.clock,
    required this.relapses,
  });

  final Listenable clock;
  final List<Relapse> relapses;

  static const int _beats = 8; // one tile == 8 beats == 8 seconds

  /// Relapse scar positions in viewBox x (0..[_viewW]), pinned to a 91-day
  /// window ending today, matching the prototype.
  List<double> _scarX() {
    const dayMs = Duration.millisecondsPerDay;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    const n = 91;
    final windowStart =
        todayStart.subtract(const Duration(days: n - 1)).millisecondsSinceEpoch;
    final span = (todayStart.millisecondsSinceEpoch + dayMs) - windowStart;
    final out = <double>[];
    for (final r in relapses) {
      final at = r.at.toLocal().millisecondsSinceEpoch;
      if (at < windowStart) continue;
      final x = (at - windowStart) / span * PulsePainter.viewW;
      out.add(x.clamp(8.0, PulsePainter.viewW - 8));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scars = _scarX();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: AnimatedBuilder(
              animation: clock,
              builder: (context, _) {
                // 0→1 over 8s → one tile per 8s → one beat per second.
                final phase = Phase.loop(const Duration(seconds: _beats));
                return CustomPaint(
                  size: const Size(double.infinity, 72),
                  painter: PulsePainter(scrollPhase: phase, scarX: scars),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'STREAK PULSE',
          style: AppType.oswaldStyle(
            size: 10,
            letterSpacing: 2,
            color: AppColors.emerald400.withValues(alpha: 0.85),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: clock,
              builder: (context, _) {
                final b = Phase.pingPong(const Duration(milliseconds: 1600));
                return Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.emerald400
                        .withValues(alpha: 0.5 + 0.5 * b),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emerald400.withValues(alpha: 0.7 * b),
                        blurRadius: 8,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            Text(
              'ALIVE',
              style: AppType.oswaldStyle(
                size: 10,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Paints the scrolling EKG trace, left fade, pinned scars, and write-head.
class PulsePainter extends CustomPainter {
  const PulsePainter({required this.scrollPhase, required this.scarX});

  /// 0..1 position within one 8-second tile loop.
  final double scrollPhase;

  /// Relapse scar x positions in viewBox coords.
  final List<double> scarX;

  static const double viewW = 340;
  static const double mid = 36;
  static const int beats = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / viewW; // horizontal scale; y stays in view units
    double px(double x) => x * sx;

    // Older (left) signal fades out. Applied as a gradient on each stroke's own
    // paint - no ShaderMask/overlay, so there is no layer boundary to show as a
    // rectangle. Transparent at the left edge, full by ~30% across.
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    Shader leftFade(Color c) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [c.withValues(alpha: 0), c],
          stops: const [0.0, 0.30],
        ).createShader(fullRect);

    // Baseline.
    canvas.drawLine(
      Offset(0, mid),
      Offset(size.width, mid),
      Paint()
        ..shader = leftFade(Colors.white.withValues(alpha: 0.06))
        ..strokeWidth = 1,
    );

    // Scrolling trace - tile drawn twice, offset by one tile width.
    final offset = -scrollPhase * viewW;
    // Blur-free glow: a wider, dim stroke under the crisp line. MaskFilter.blur
    // renders a rectangular box artifact under Impeller, so we avoid it entirely
    // here and fake glow with layered translucent draws.
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = leftFade(AppColors.emerald500.withValues(alpha: 0.18));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = leftFade(AppColors.emerald500);

    for (final base in [offset, offset + viewW]) {
      final path = _beatTile(base, px);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, line);
    }

    // (Older-signal fade is applied by a ShaderMask on the widget, not here,
    // so it dissolves the trace pixels instead of overlaying a box.)

    // Pinned relapse scars: dashed tick + a soft (blur-free) red dot.
    for (final x in scarX) {
      _dashedLine(canvas, px(x), 10, 62,
          Paint()
            ..color = AppColors.relapseScar.withValues(alpha: 0.3)
            ..strokeWidth = 1);
      canvas.drawCircle(Offset(px(x), mid), 7,
          Paint()..color = AppColors.relapseScar.withValues(alpha: 0.28));
      canvas.drawCircle(
          Offset(px(x), mid), 3.4, Paint()..color = AppColors.relapseScar);
    }

    // Write-head at x≈337 - "now". Blur-free: wide dim line under a crisp one.
    final headX = px(337);
    canvas.drawLine(
      Offset(headX, 6),
      Offset(headX, 66),
      Paint()
        ..color = AppColors.mintNode.withValues(alpha: 0.35)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(headX, 6),
      Offset(headX, 66),
      Paint()
        ..color = AppColors.mintNode
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(headX, mid), 7,
        Paint()..color = AppColors.textHi.withValues(alpha: 0.3));
    canvas.drawCircle(Offset(headX, mid), 3.4, Paint()..color = AppColors.textHi);
  }

  /// One tile of 8 heartbeat glyphs, translated by [base] view-units.
  Path _beatTile(double base, double Function(double) px) {
    const seg = viewW / beats;
    final path = Path()..moveTo(px(base), mid);
    for (var i = 0; i < beats; i++) {
      final x = base + i * seg;
      path
        ..lineTo(px(x + seg * 0.30), mid)
        ..lineTo(px(x + seg * 0.38), mid - 4)
        ..lineTo(px(x + seg * 0.46), mid)
        ..lineTo(px(x + seg * 0.52), mid + 6)
        ..lineTo(px(x + seg * 0.57), mid - 26) // R spike
        ..lineTo(px(x + seg * 0.62), mid + 10)
        ..lineTo(px(x + seg * 0.69), mid)
        ..lineTo(px(x + seg), mid);
    }
    return path;
  }

  void _dashedLine(Canvas canvas, double x, double y1, double y2, Paint paint) {
    const dash = 2.0, gap = 3.0;
    var y = y1;
    while (y < y2) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + dash).clamp(y1, y2)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(PulsePainter old) =>
      old.scrollPhase != scrollPhase || old.scarX != scarX;
}
