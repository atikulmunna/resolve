import 'package:flutter/material.dart';

import '../../../core/milestones.dart';
import '../../../core/streak.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/milestone_dot.dart';

/// Milestone track card (Design Spec §3.1 / FR-4.1). Caption + days-to-go on
/// one line, the three milestone nodes in their own row, and a live-filling
/// 0→90-day progress bar on a separate line below - numbers and bar never
/// overlap.
class MilestoneTrack extends StatelessWidget {
  const MilestoneTrack({
    super.key,
    required this.startedAt,
    required this.clock,
    this.onPreview,
  });

  final DateTime startedAt;
  final Listenable clock;

  /// Tapping a node previews its celebration (FR-4.3).
  final ValueChanged<int>? onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.hairline),
      ),
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final s = Streak.since(startedAt);
          final days = s.days;
          final next = nextMilestone(days);
          final toGo = next == null ? 0 : next - days;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    next == null ? 'LEGEND STATUS' : 'NEXT: $next-DAY MARK',
                    style: AppType.oswaldStyle(
                      size: 10,
                      letterSpacing: 2,
                      color: AppColors.emerald400.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    next == null
                        ? 'All milestones cleared'
                        : '$toGo ${toGo == 1 ? "day" : "days"} to go',
                    style: AppType.groteskStyle(
                      size: 12,
                      color: AppColors.textMute,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final m in kMilestones)
                      _node(m, milestoneStateFor(m, days), toGo),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Live-filling bar on its own line.
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final f = (s.fractionalDays / 90).clamp(0.0, 1.0);
                      return Stack(
                        children: [
                          Container(color: Colors.white.withValues(alpha: 0.08)),
                          Container(
                            width: c.maxWidth * f,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.emerald600,
                                  AppColors.emerald400,
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _node(int value, MilestoneState state, int toGo) {
    final status = milestoneStatus(state, toGo);
    return GestureDetector(
      onTap: onPreview == null ? null : () => onPreview!(value),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MilestoneDot(value: value, state: state),
          const SizedBox(height: 8),
          Text(
            status.text,
            style: AppType.oswaldStyle(
              size: 8.5,
              letterSpacing: 1,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
