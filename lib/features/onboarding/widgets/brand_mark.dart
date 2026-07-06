import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../core/phase.dart';
import '../../../theme/app_colors.dart';
import '../../home/widgets/ring_painter.dart';

/// The Resolve brand mark used on the onboarding screens: a breathing emerald
/// halo, a translucent glass disc, a sweeping 60-second-style ring, and the
/// app's up-chevron at the center - a still, logo-like echo of the hero dial.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.clock, this.size = 160});

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
          final breathe = Phase.pingPong(const Duration(milliseconds: 4200));
          // Slow sweep so the ring feels alive, like the running timer.
          final sweep = Phase.loop(const Duration(seconds: 6));
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Breathing halo.
              Opacity(
                opacity: 0.45 + 0.45 * breathe,
                child: Transform.scale(
                  scale: 1.0 + 0.12 * breathe,
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.emerald500.withValues(alpha: 0.5),
                            AppColors.emerald500.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.66],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Glass disc.
              Container(
                width: size * 0.82,
                height: size * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.56),
                    radius: 0.95,
                    colors: [
                      AppColors.emerald400.withValues(alpha: 0.18),
                      AppColors.emerald500.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.42),
                    ],
                    stops: const [0.0, 0.46, 1.0],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
              ),
              // Sweeping ring.
              Positioned.fill(
                child: CustomPaint(painter: RingPainter(progress: sweep)),
              ),
              // Up-chevron mark (mint over emerald, like the app icon).
              _chevrons(size * 0.3),
            ],
          );
        },
      ),
    );
  }

  Widget _chevrons(double s) {
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 0,
            child: Icon(Icons.keyboard_arrow_up_rounded,
                size: s, color: AppColors.emerald500),
          ),
          Positioned(
            bottom: s * 0.26,
            child: Icon(Icons.keyboard_arrow_up_rounded,
                size: s, color: AppColors.mintNode),
          ),
        ],
      ),
    );
  }
}
