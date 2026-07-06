import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/milestones.dart';
import '../../core/streak.dart';
import '../../core/transitions.dart';
import '../../core/widget_bridge.dart';
import '../../data/backup.dart';
import '../../data/habit_store.dart';
import '../../models/habit.dart';
import '../../models/relapse.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../celebration/celebration_screen.dart';
import '../craving/craving_screen.dart';
import '../create/create_screen.dart';
import '../journey/journey_screen.dart';
import '../relapse/relapse_sheet.dart';
import 'widgets/ambient_orbs.dart';
import 'widgets/craving_button.dart';
import 'widgets/glass_dial.dart';
import 'widgets/header_menu.dart';
import 'widgets/home_header.dart';
import 'widgets/milestone_track.dart';
import 'widgets/relapse_pill.dart';
import 'widgets/stat_chips.dart';
import 'widgets/streak_pulse.dart';
import 'widgets/tab_bar.dart';
import 'widgets/units_row.dart';

/// Home / Timer screen (Design Spec §3.1). Owns the single master animation
/// clock: one repeating [AnimationController] that triggers a repaint each
/// frame. Every animated child reads `now()` off it, so the timer, ring, and
/// pulse are always `now() - startedAt` - never a counter - and stay correct
/// after backgrounding (NFR-1..3). The clock is paused when the app leaves the
/// foreground to save battery (NFR-2 / FR-8.6).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final HabitStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;

  /// Guards against re-presenting while a celebration route is already up.
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Duration is irrelevant - the controller is only a per-frame repaint
    // signal; all values are computed from wall-clock time on each tick.
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    // The same clock detects milestone crossings (FR-4.2).
    _clock.addListener(_maybeCelebrate);
  }

  /// Auto-present the celebration the first time the live streak crosses a
  /// milestone this streak. `markCelebrated` persists the fire so it never
  /// repeats; a relapse clears the set and re-arms them (FR-4.4).
  void _maybeCelebrate() {
    if (_celebrating || !mounted) return;
    final habit = widget.store.habit;
    final days = Streak.since(habit.startedAt).days;
    for (final m in kMilestones) {
      if (days >= m && !habit.celebratedMilestones.contains(m)) {
        _celebrating = true;
        widget.store.markCelebrated(m);
        showCelebration(context, m)
            .whenComplete(() => _celebrating = false);
        break;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
      // Leaving the foreground: refresh the widget so its day count is current
      // next time the user looks at the home screen.
      WidgetBridge.save(widget.store.habit);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  void _openCreate() {
    Navigator.of(context).push(
      SlideUpRoute(child: CreateScreen(store: widget.store)),
    );
  }

  void _openEdit() {
    final habit = widget.store.habit;
    Navigator.of(context).push(
      SlideUpRoute(
        child: CreateScreen(
          store: widget.store,
          edit: true,
          initialName: habit.name,
          initialWhy: habit.why,
        ),
      ),
    );
  }

  void _openMenu() {
    showHeaderMenu(
      context,
      why: widget.store.habit.why,
      onEdit: _openEdit,
      onReset: _openRelapse,
      onExport: _exportBackup,
      onImport: _importBackup,
    );
  }

  Future<void> _exportBackup() async {
    try {
      await Backup.share(widget.store.habit, widget.store.relapses);
    } catch (_) {
      _toast("Couldn't export the backup.");
    }
  }

  Future<void> _importBackup() async {
    final ({Habit habit, List<Relapse> relapses})? data;
    try {
      data = await Backup.pickAndDecode();
    } on FormatException catch (e) {
      _toast(e.message);
      return;
    } catch (_) {
      _toast("Couldn't read that file.");
      return;
    }
    if (data == null || !mounted) return; // cancelled

    final confirmed = await _confirmImport();
    if (confirmed != true || !mounted) return;

    widget.store.restore(data.habit, data.relapses);
    _toast('Backup restored.');
  }

  /// Destructive-action confirm: importing replaces the current streak + log.
  Future<bool?> _confirmImport() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0C1512),
        title: Text(
          'Restore this backup?',
          style: AppType.oswaldStyle(size: 16, letterSpacing: 1),
        ),
        content: Text(
          'This replaces your current streak and entire relapse history. '
          'It cannot be undone.',
          style: AppType.groteskStyle(
            size: 13.5,
            color: AppColors.textMute,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'CANCEL',
              style: AppType.oswaldStyle(
                size: 12,
                letterSpacing: 1,
                color: AppColors.textMute,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'RESTORE',
              style: AppType.oswaldStyle(
                size: 12,
                letterSpacing: 1,
                color: AppColors.danger300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0C1512),
          content: Text(
            message,
            style: AppType.groteskStyle(size: 13, color: AppColors.textHi),
          ),
        ),
      );
  }

  void _openRelapse() => showRelapseSheet(context, widget.store);

  void _openCraving() => showCraving(context, widget.store);

  void _openJourney() {
    Navigator.of(context).push(
      SlideUpRoute(child: JourneyScreen(store: widget.store)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      backgroundColor: AppColors.black,
      body: DecoratedBox(
        // Home ambient gradient (radial, top-center).
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.2,
            colors: AppColors.ambient,
            stops: [0.0, 0.44, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: store,
                  builder: (context, _) {
                    final habit = store.habit;
                    return Stack(
                      children: [
                        AmbientOrbs(clock: _clock),
                        ListView(
                          padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            const SizedBox(height: 4),
                            HomeHeader(name: habit.name, onMenu: _openMenu),
                            const SizedBox(height: 14),
                            Center(
                              child: GlassDial(
                                startedAt: habit.startedAt,
                                clock: _clock,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: UnitsRow(
                                startedAt: habit.startedAt,
                                clock: _clock,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: CravingButton(
                                clock: _clock,
                                onTap: _openCraving,
                              ),
                            ),
                            const SizedBox(height: 10),
                            StreakPulse(
                              clock: _clock,
                              relapses: store.relapses,
                            ),
                            const SizedBox(height: 14),
                            MilestoneTrack(
                              startedAt: habit.startedAt,
                              clock: _clock,
                              onPreview: (m) => showCelebration(context, m),
                            ),
                            const SizedBox(height: 22),
                            _quote(),
                            const SizedBox(height: 26),
                            StatChips(
                              bestStreak: Fmt.dh(habit.bestStreakMs),
                              relapses: store.relapseCount,
                              successRate: habit.successRate,
                            ),
                            const SizedBox(height: 18),
                            RelapsePill(onTap: _openRelapse),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              GlassTabBar(onNew: _openCreate, onJourney: _openJourney),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quote() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 296),
        child: Text(
          '“Discipline is choosing between what you want now '
          'and what you want most.”',
          textAlign: TextAlign.center,
          style: AppType.groteskStyle(
            size: 13.5,
            color: AppColors.textMute,
            height: 1.55,
          ),
        ),
      ),
    );
  }
}
