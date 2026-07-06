import 'package:flutter/material.dart';

import '../core/milestones.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// The 34px milestone node circle, shared by the Home track (§3.1) and the
/// Journey badges (§3.5): reached = emerald gradient + glow · next =
/// translucent emerald ring · locked = dark.
class MilestoneDot extends StatelessWidget {
  const MilestoneDot({super.key, required this.value, required this.state});

  final int value;
  final MilestoneState state;

  @override
  Widget build(BuildContext context) {
    final (Color border, Gradient? grad, Color fill, Color textColor,
        List<BoxShadow> glow) = switch (state) {
      MilestoneState.reached => (
          AppColors.emerald400,
          const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.emerald300, AppColors.emerald600],
          ),
          Colors.transparent,
          const Color(0xFF04140E),
          [
            BoxShadow(
              color: AppColors.emerald500.withValues(alpha: 0.65),
              blurRadius: 16,
            )
          ],
        ),
      MilestoneState.next => (
          AppColors.emerald400.withValues(alpha: 0.55),
          null,
          AppColors.emerald400.withValues(alpha: 0.12),
          AppColors.emerald400,
          [
            BoxShadow(
              color: AppColors.emerald500.withValues(alpha: 0.3),
              blurRadius: 12,
            )
          ],
        ),
      MilestoneState.locked => (
          Colors.white.withValues(alpha: 0.14),
          null,
          const Color(0xFF0A0F0D),
          Colors.white.withValues(alpha: 0.42),
          const <BoxShadow>[],
        ),
    };

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: grad == null ? fill : null,
        gradient: grad,
        border: Border.all(color: border, width: 1),
        boxShadow: glow,
      ),
      child: Text(
        '$value',
        style: AppType.groteskStyle(size: 13, weight: 700, color: textColor),
      ),
    );
  }
}

/// Status caption for a milestone: "✓ REACHED" / "Nd LEFT" / "LOCKED", with its
/// color. Shared so Home and Journey read identically.
({String text, Color color}) milestoneStatus(MilestoneState state, int toGo) {
  return switch (state) {
    MilestoneState.reached => (text: '✓ REACHED', color: AppColors.emerald400),
    MilestoneState.next => (
        text: '${toGo}D LEFT',
        color: AppColors.emerald400.withValues(alpha: 0.75),
      ),
    MilestoneState.locked => (
        text: 'LOCKED',
        color: Colors.white.withValues(alpha: 0.35),
      ),
  };
}
