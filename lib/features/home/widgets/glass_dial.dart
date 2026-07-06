import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../core/phase.dart';
import '../../../core/streak.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'ring_painter.dart';
import 'wave_field.dart';

/// The frosted-glass hero dial (Design Spec §2). Layers back→front:
/// breathing halo · glass body (backdrop blur + translucent radial fill + inner
/// bottom shadow + rotating conic sheen + 3D wave-flow field) · content (DAYS
/// number + labels) · the 60-second ring on top. Borderless: no rim stroke, no
/// specular highlight.
///
/// All motion derives from `now()` via [Phase]/[Streak] on each frame of the
/// shared [clock], so nothing here holds its own counter.
class GlassDial extends StatelessWidget {
  const GlassDial({super.key, required this.startedAt, required this.clock});

  final DateTime startedAt;
  final Listenable clock;

  static const double _box = 262;
  static const double _inset = 16; // glass disc inset

  // Wall-clock epoch for the terrain field. Elapsed stays small (seconds since
  // first build) so the sine phases keep full float precision and never wrap.
  // Only advances while the shared clock repaints, so it freezes on background.
  static final DateTime _epoch = DateTime.now();
  static double get _terrainT =>
      DateTime.now().difference(_epoch).inMicroseconds / 1e6;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _box,
      height: _box,
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final streak = Streak.since(startedAt);
          final breathe = Phase.pingPong(const Duration(milliseconds: 4200));
          final sheenTurns = Phase.loop(const Duration(seconds: 9));

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              _halo(breathe),
              Positioned.fill(
                left: _inset,
                top: _inset,
                right: _inset,
                bottom: _inset,
                child: _glassBody(streak, sheenTurns),
              ),
              // Ring sits on top, geometry centered on the full box (r=110).
              Positioned.fill(
                child: CustomPaint(
                  painter: RingPainter(progress: streak.ringProgress),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Layer 1 - breathing emerald halo, extending 12px past the box.
  Widget _halo(double breathe) {
    final scale = 1.0 + 0.14 * breathe;
    final opacity = 0.5 + 0.42 * breathe;
    return Positioned(
      left: -12,
      top: -12,
      right: -12,
      bottom: -12,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.emerald500.withValues(alpha: 0.45),
                      AppColors.emerald500.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.66],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Layer 2-5 - the glass disc.
  Widget _glassBody(Streak streak, double sheenTurns) {
    return DecoratedBox(
      // Outer drop shadow that lifts the disc off the black.
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 70,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live blur of whatever sits behind (ambient orb + black).
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: const SizedBox.expand(),
            ),
            // Translucent emerald radial fill.
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(0, -0.08), // centered glow, no corner
                  radius: 1.05,
                  colors: [
                    AppColors.emerald400.withValues(alpha: 0.16),
                    AppColors.emerald500.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.42),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Inner bottom shadow (fakes `inset 0 -34px 60px black`).
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            // Layer 3 - rotating conic sheen (screen-ish via low-opacity white).
            Transform.rotate(
              angle: sheenTurns * 2 * math.pi,
              child: const _Sheen(),
            ),
            // Layer 4 - the 3D wave field: a dense particle surface seen in
            // perspective, flowing toward the viewer. Lightly softened so it
            // sits like glass; the numeral on top stays crisp.
            Positioned.fill(
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                  child: CustomPaint(painter: WaveFieldPainter(_terrainT)),
                ),
              ),
            ),
            // Layer 5 - content.
            _content(streak),
          ],
        ),
      ),
    );
  }

  Widget _content(Streak streak) {
    final dayLabel = streak.days == 1 ? 'DAY' : 'DAYS';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${streak.days}',
            style: AppType.groteskStyle(
              size: 80,
              weight: 700,
              letterSpacing: -2,
              color: AppColors.textHi,
              height: 0.88,
            ).copyWith(
              shadows: [
                Shadow(
                  color: AppColors.emerald500.withValues(alpha: 0.45),
                  blurRadius: 26,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Text(
            dayLabel,
            style: AppType.oswaldStyle(
              size: 13,
              letterSpacing: 6,
              color: AppColors.textMint,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'STAYING CLEAN',
            style: AppType.oswaldStyle(
              size: 9.5,
              letterSpacing: 3,
              color: AppColors.textMint,
            ).copyWith(
              shadows: [
                const Shadow(color: Colors.black, blurRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _Sheen extends StatelessWidget {
  const _Sheen();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.13),
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.12, 0.27, 1.0],
          ),
        ),
      ),
    );
  }
}
