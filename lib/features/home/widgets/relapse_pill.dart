import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Slim, auto-width, centered relapse control (Design Spec §3.1 / FR-3.1) -
/// NOT a full-width button. The relapse sheet is a later screen; the pill is
/// present but inert for now.
class RelapsePill extends StatelessWidget {
  const RelapsePill({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.danger400.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.danger400.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh,
                  size: 14,
                  color: AppColors.danger300.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Text(
                  'I RELAPSED',
                  style: AppType.oswaldStyle(
                    size: 11,
                    letterSpacing: 1.5,
                    color: AppColors.danger300.withValues(alpha: 0.9),
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
