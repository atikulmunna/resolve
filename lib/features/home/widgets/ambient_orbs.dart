import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../core/phase.dart';
import '../../../theme/app_colors.dart';

/// Two drifting, blurred emerald orbs behind the Home content (Design Spec
/// §3.1): a bright one top-center (`floatOrb` 12s) and a dim one bottom-right
/// (`floatOrb2` 15s). Motion derives from the shared [clock].
class AmbientOrbs extends StatelessWidget {
  const AmbientOrbs({super.key, required this.clock});

  final Listenable clock;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final t1 = Phase.pingPong(const Duration(seconds: 12));
          final t2 = Phase.pingPong(const Duration(seconds: 15));
          return Stack(
            children: [
              Positioned(
                top: -30 - 22 * t1,
                left: 0,
                right: 0,
                child: Center(
                  child: _orb(
                    300,
                    AppColors.emerald500.withValues(alpha: 0.30),
                    32,
                  ),
                ),
              ),
              Positioned(
                bottom: 60 + 16 * t2,
                right: -50 - 18 * t2,
                child: _orb(
                  240,
                  const Color(0xFF10785C).withValues(alpha: 0.24),
                  36,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orb(double size, Color color, double blur) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
            stops: const [0.0, 0.68],
          ),
        ),
      ),
    );
  }
}
