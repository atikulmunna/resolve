import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Glass bottom tab bar (Design Spec §3.2): Timer · New · Journey. Only Timer
/// exists in this build; New/Journey are later screens, so those items are
/// present but inert. The New button is elevated - it lifts above the bar's
/// top hairline.
class GlassTabBar extends StatelessWidget {
  const GlassTabBar({super.key, this.onNew, this.onJourney});

  final VoidCallback? onNew;
  final VoidCallback? onJourney;

  static const double _height = 78;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glass background with top hairline.
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 34, right: 34, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tab(
                  icon: Icons.timer_outlined,
                  label: 'TIMER',
                  color: AppColors.emerald400,
                ),
                _newTab(),
                GestureDetector(
                  onTap: onJourney,
                  behavior: HitTestBehavior.opaque,
                  child: _tab(
                    icon: Icons.bar_chart_rounded,
                    label: 'JOURNEY',
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppType.oswaldStyle(size: 9, letterSpacing: 1.5, color: color),
          ),
        ],
      ),
    );
  }

  Widget _newTab() {
    // Natural height (~66px) exceeds the row band; anchor it to the bottom and
    // let it overflow upward so the button reads as "elevated".
    return SizedBox(
      width: 56,
      child: OverflowBox(
        minHeight: 0,
        maxHeight: double.infinity,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: onNew,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.emerald400, AppColors.emerald600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald500.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, size: 22, color: Color(0xFF04140E)),
              ),
              const SizedBox(height: 6),
              Text(
                'NEW',
                style: AppType.oswaldStyle(
                  size: 9,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
