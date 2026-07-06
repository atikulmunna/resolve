import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/milestones.dart';
import '../../core/streak.dart';
import '../../data/habit_store.dart';
import '../../models/mood.dart';
import '../../models/relapse.dart';
import '../celebration/celebration_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/milestone_dot.dart';
import '../../widgets/overlay_scaffold.dart';

/// Journey (stats) - slide-up overlay (Design Spec §3.5). Seamless: no boxed
/// cards. A live hero streak, a hairline-divided 2×2 stat grid, plain milestone
/// badges, and a borderless relapse-history timeline.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key, required this.store});

  final HabitStore store;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  static const Color _hair = Color(0x14FFFFFF); // rgba(255,255,255,.08)

  @override
  Widget build(BuildContext context) {
    return OverlayScaffold(
      title: 'YOUR JOURNEY',
      onBack: () => Navigator.of(context).pop(),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          final habit = widget.store.habit;
          final relapses = widget.store.relapses;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            physics: const BouncingScrollPhysics(),
            children: [
              _hero(habit.startedAt),
              _statGrid(
                habit.name,
                habit.bestStreakMs,
                habit.successRate,
                relapses.length,
              ),
              _sectionLabel('WHAT TRIGGERS YOU', top: 26, bottom: 14),
              _insights(relapses),
              _sectionLabel('MILESTONES', top: 26, bottom: 14),
              _milestones(habit.startedAt),
              _sectionLabel('RELAPSE HISTORY', top: 26, bottom: 4),
              for (final r in relapses) _historyRow(r),
              const SizedBox(height: 20),
              _footer(),
            ],
          );
        },
      ),
    );
  }

  // Hero - live streak with a soft emerald radial glow behind it.
  Widget _hero(DateTime startedAt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 22, 0, 26),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                width: 200,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  gradient: RadialGradient(
                    colors: [
                      AppColors.emerald500.withValues(alpha: 0.28),
                      AppColors.emerald500.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'RUNNING NOW',
                style: AppType.oswaldStyle(
                  size: 10,
                  letterSpacing: 3,
                  color: AppColors.emerald400.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _clock,
                builder: (context, _) {
                  final elapsed = Streak.since(startedAt).elapsed;
                  return Text(
                    Fmt.dhm(elapsed),
                    style:
                        AppType.groteskStyle(
                          size: 42,
                          weight: 700,
                          letterSpacing: -1,
                          color: AppColors.textHi,
                        ).copyWith(
                          shadows: [
                            Shadow(
                              color: AppColors.emerald500.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2×2 grid divided only by hairlines - no fills.
  Widget _statGrid(String name, int bestMs, int success, int relapses) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _hair)),
      ),
      child: IntrinsicHeight(
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                children: [
                  _statCell(
                    Fmt.dh(bestMs),
                    'BEST STREAK',
                    AppColors.textHi,
                    right: true,
                    bottom: true,
                  ),
                  _statCell(
                    '$success%',
                    'SUCCESS RATE',
                    AppColors.emerald400,
                    bottom: true,
                  ),
                ],
              ),
            ),
            IntrinsicHeight(
              child: Row(
                children: [
                  _statCell(
                    '$relapses',
                    'TOTAL RELAPSES',
                    AppColors.danger400,
                    right: true,
                    valueSize: 26,
                    labelColor: AppColors.danger400.withValues(alpha: 0.55),
                  ),
                  _statCell(name, 'TRACKING', AppColors.textHi, valueSize: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCell(
    String value,
    String label,
    Color valueColor, {
    bool right = false,
    bool bottom = false,
    double valueSize = 26,
    Color? labelColor,
  }) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            right: right ? const BorderSide(color: _hair) : BorderSide.none,
            bottom: bottom ? const BorderSide(color: _hair) : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                textAlign: TextAlign.center,
                style: AppType.groteskStyle(
                  size: valueSize,
                  weight: 700,
                  color: valueColor,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppType.oswaldStyle(
                  size: 9,
                  letterSpacing: 2,
                  color: labelColor ?? Colors.white.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Relapse insights (Tier-2): mood breakdown + time-of-day pattern, derived
  // purely from the logged relapse history. Needs a little data to be
  // meaningful, so under two relapses it just says so.
  Widget _insights(List<Relapse> relapses) {
    if (relapses.length < 2) {
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 4),
        child: Text(
          relapses.isEmpty
              ? 'No relapses logged. Nothing to learn from yet. Keep going.'
              : 'Not enough history yet. Patterns appear as the log grows.',
          style: AppType.groteskStyle(
            size: 13,
            color: Colors.white.withValues(alpha: 0.4),
            height: 1.5,
          ),
        ),
      );
    }

    // Tally moods and time-of-day buckets in one pass.
    final moodCounts = <Mood, int>{};
    final buckets = List<int>.filled(4, 0); // night/morning/afternoon/evening
    for (final r in relapses) {
      moodCounts.update(r.mood, (v) => v + 1, ifAbsent: () => 1);
      buckets[(r.at.toLocal().hour ~/ 6).clamp(0, 3)]++;
    }
    final dominant = moodCounts.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );
    final peak = _peakBucketLabel(buckets);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moodBar(relapses.length, moodCounts),
        const SizedBox(height: 10),
        _insightCaption('Most often felt ', dominant.key.label, dominant.key.color),
        const SizedBox(height: 22),
        _timeOfDay(buckets),
        const SizedBox(height: 10),
        _insightCaption('Most vulnerable ', peak, AppColors.danger400),
      ],
    );
  }

  // A single hairline-thin stacked bar of moods, each segment its mood colour.
  Widget _moodBar(int total, Map<Mood, int> counts) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            for (final m in Mood.values)
              if ((counts[m] ?? 0) > 0)
                Expanded(
                  flex: counts[m]!,
                  child: Container(
                    color: m.color.withValues(alpha: 0.85),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // Four vertical bars: when relapses happen across the day. Relapse data, so
  // coral-tinted; the peak bucket burns brightest. The bar flexes to fill the
  // space between the count and the label, so the column can never overflow
  // (even under large system font scaling).
  Widget _timeOfDay(List<int> buckets) {
    const labels = ['NIGHT', 'MORNING', 'AFTERNOON', 'EVENING'];
    final maxCount = buckets.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 84,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${buckets[i]}',
                    maxLines: 1,
                    style: AppType.groteskStyle(
                      size: 12,
                      weight: 600,
                      color: buckets[i] == 0
                          ? Colors.white.withValues(alpha: 0.25)
                          : AppColors.danger400.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        widthFactor: 0.56,
                        heightFactor: maxCount == 0
                            ? 0.08
                            : (0.14 + 0.86 * buckets[i] / maxCount),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: AppColors.danger400.withValues(
                              alpha: buckets[i] == maxCount && maxCount > 0
                                  ? 0.7
                                  : 0.28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: AppType.oswaldStyle(
                      size: 7.5,
                      letterSpacing: 0.4,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _insightCaption(String lead, String highlight, Color color) {
    return RichText(
      text: TextSpan(
        style: AppType.groteskStyle(
          size: 13,
          color: Colors.white.withValues(alpha: 0.55),
        ),
        children: [
          TextSpan(text: lead),
          TextSpan(
            text: highlight,
            style: AppType.groteskStyle(size: 13, weight: 600, color: color),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  String _peakBucketLabel(List<int> buckets) {
    const names = ['at night', 'in the morning', 'in the afternoon', 'in the evening'];
    var peak = 0;
    for (var i = 1; i < 4; i++) {
      if (buckets[i] > buckets[peak]) peak = i;
    }
    return names[peak];
  }

  static const Map<int, String> _titles = {
    30: 'One Month',
    60: 'Two Months',
    90: 'Three Months',
  };

  Widget _milestones(DateTime startedAt) {
    final days = Streak.since(startedAt).days;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final m in kMilestones)
          // Pass this milestone's own days-to-go: identical to next-days for the
          // active one (so the caption is unchanged), and drives the locked toast.
          _milestoneBadge(m, milestoneStateFor(m, days), m - days),
      ],
    );
  }

  Widget _milestoneBadge(int value, MilestoneState state, int toGo) {
    final status = milestoneStatus(state, toGo);
    // Only a reached milestone reveals its celebration; the rest stay locked
    // with a semi-transparent padlock, and a tap just says how far off it is.
    final reached = state == MilestoneState.reached;
    return GestureDetector(
      onTap: reached
          ? () => showCelebration(context, value)
          : () => _lockedTap(value, state, toGo),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              MilestoneDot(value: value, state: state),
              if (!reached)
                Icon(
                  Icons.lock_rounded,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.5),
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.7),
                      blurRadius: 4,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            _titles[value] ?? '',
            style: AppType.oswaldStyle(
              size: 11,
              weight: 500,
              letterSpacing: 1,
              color: const Color(0xFFDFF7EE),
            ),
          ),
          const SizedBox(height: 4),
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

  // Tapping a locked milestone doesn't spoil its celebration; it just tells
  // you, stoically, how much further there is to go.
  void _lockedTap(int value, MilestoneState state, int toGo) {
    final days = toGo < 1 ? 1 : toGo;
    final msg = state == MilestoneState.next
        ? '$value days, $days to go. Keep the clock running.'
        : '$value days is still locked. $days days to go.';
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0A1512),
        duration: const Duration(seconds: 2),
        content: Text(
          msg,
          style: AppType.groteskStyle(
            size: 13,
            color: AppColors.textHi,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _historyRow(Relapse r) {
    final color = r.mood.color;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color, blurRadius: 10)],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        'Reached ${Fmt.dh(r.reachedMs)}',
                        style: AppType.groteskStyle(
                          size: 15,
                          weight: 600,
                          color: AppColors.textHi,
                        ),
                      ),
                    ),
                    Text(
                      Fmt.ago(r.at),
                      style: AppType.groteskStyle(
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
                if (r.note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.note!,
                    style: AppType.groteskStyle(
                      size: 12.5,
                      color: Colors.white.withValues(alpha: 0.5),
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                _moodChip(r, color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _moodChip(Relapse r, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.27)),
      ),
      child: Text(
        r.mood.label.toUpperCase(),
        style: AppType.oswaldStyle(size: 9, letterSpacing: 1.5, color: color),
      ),
    );
  }

  Widget _sectionLabel(
    String text, {
    required double top,
    required double bottom,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Text(
        text,
        style: AppType.oswaldStyle(
          size: 11,
          letterSpacing: 2.5,
          color: Colors.white.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _footer() {
    return Center(
      child: Text(
        'Every reset is data, not defeat.\n'
        "The clock keeps its memory so you don't have to.",
        textAlign: TextAlign.center,
        style: AppType.groteskStyle(
          size: 12,
          color: Colors.white.withValues(alpha: 0.32),
          height: 1.5,
        ),
      ),
    );
  }
}
