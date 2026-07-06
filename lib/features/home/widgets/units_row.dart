import 'package:flutter/material.dart';

import '../../../core/streak.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// HOURS · MINUTES · SECONDS beneath the dial (Design Spec §3.1). 260px wide,
/// hairline dividers between, SECONDS tinted emerald. Rebuilds each frame off
/// the shared [clock]; values derive from `startedAt`.
class UnitsRow extends StatelessWidget {
  const UnitsRow({super.key, required this.startedAt, required this.clock});

  final DateTime startedAt;
  final Listenable clock;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final s = Streak.since(startedAt);
          // IntrinsicHeight bounds the Row's height so the stretch dividers can
          // size to the tallest unit (the Row lives in an unbounded ListView).
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _unit(Streak.two(s.hours), 'HOURS'),
                _divider(),
                _unit(Streak.two(s.minutes), 'MINUTES'),
                _divider(),
                _unit(Streak.two(s.seconds), 'SECONDS', accent: true),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _unit(String value, String label, {bool accent = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppType.groteskStyle(
              size: 24,
              weight: 600,
              color: accent ? AppColors.emerald400 : const Color(0xFFDFF7EE),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppType.oswaldStyle(
              size: 9,
              letterSpacing: 2,
              color: accent
                  ? AppColors.emerald400.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 4),
        color: Colors.white.withValues(alpha: 0.09),
      );
}
