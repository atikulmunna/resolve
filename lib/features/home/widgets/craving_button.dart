import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../core/phase.dart';
import '../../../theme/app_colors.dart';
import '../../craving/lung.dart';

/// The craving control (Tier-1): an icon-only, borderless liquid-glass disc that
/// opens the breathing tool. It *breathes*: a continuous lung-like inflate /
/// exhale of the glass, its halo, and its glow, synced to the master clock, so
/// it reads as alive and invites you to tap and breathe in a weak moment. No
/// text: the pulsing orb is the affordance.
class CravingButton extends StatelessWidget {
  const CravingButton({super.key, required this.clock, this.onTap});

  final Listenable clock;
  final VoidCallback? onTap;

  static const double _disc = 78; // glass diameter
  static const double _box = 132; // tap target + room for the halo

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Breathe through a craving',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _box,
          height: _box,
          child: AnimatedBuilder(
            animation: clock,
            builder: (context, _) {
              // One slow breath cycle (~4.4s): 0 = fully exhaled, 1 = inhaled.
              final breath = Phase.pingPong(const Duration(milliseconds: 4400));
              return _body(breath);
            },
          ),
        ),
      ),
    );
  }

  Widget _body(double breath) {
    final discScale = 0.94 + 0.09 * breath; // the lung inflating / deflating
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Breathing halo, blooms outward on the inhale.
        Transform.scale(
          scale: 0.9 + 0.4 * breath,
          child: Opacity(
            opacity: 0.30 + 0.45 * breath,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: _disc,
                height: _disc,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.emerald500.withValues(alpha: 0.55),
                      AppColors.emerald500.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.72],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Expanding breath ring, a second lung cue that fades as it grows.
        Transform.scale(
          scale: 0.8 + 0.6 * breath,
          child: Container(
            width: _disc,
            height: _disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.mintNode.withValues(
                  alpha: 0.28 * (1 - breath),
                ),
                width: 1.2,
              ),
            ),
          ),
        ),
        // The liquid-glass disc itself, blurs the ambient behind it, borderless,
        // with a soft emerald fill and a pulsing outer glow. Scales with breath.
        Transform.scale(
          scale: discScale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald500.withValues(
                    alpha: 0.22 + 0.28 * breath,
                  ),
                  blurRadius: 22 + 16 * breath,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: _disc,
                  height: _disc,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.25),
                      radius: 1.0,
                      colors: [
                        AppColors.mintNode.withValues(
                          alpha: 0.22 + 0.12 * breath,
                        ),
                        AppColors.emerald500.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.28),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                  child: CustomPaint(
                    size: const Size(32, 34),
                    painter: LungGlyphPainter(
                      color: AppColors.mintNode.withValues(
                        alpha: 0.82 + 0.18 * breath,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
