import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Three floating-glass stat chips (Design Spec §3.1): Best Streak · Relapses
/// (red) · Success. The gradient + blur + `0 16px 32px` shadow lift them off
/// the black.
class StatChips extends StatelessWidget {
  const StatChips({
    super.key,
    required this.bestStreak,
    required this.relapses,
    required this.successRate,
  });

  final String bestStreak;
  final int relapses;
  final int successRate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(bestStreak, 'BEST STREAK', AppColors.textHi, AppColors.textFaint),
        const SizedBox(width: 11),
        _chip(
          '$relapses',
          'RELAPSES',
          AppColors.danger400,
          AppColors.danger400.withValues(alpha: 0.55),
        ),
        const SizedBox(width: 11),
        _chip(
          '$successRate%',
          'SUCCESS',
          AppColors.emerald400,
          AppColors.emerald400.withValues(alpha: 0.6),
        ),
      ],
    );
  }

  Widget _chip(String value, String label, Color valueColor, Color labelColor) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.015),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppType.groteskStyle(
                    size: 19,
                    weight: 600,
                    color: valueColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppType.oswaldStyle(
                    size: 8.5,
                    letterSpacing: 1.5,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
