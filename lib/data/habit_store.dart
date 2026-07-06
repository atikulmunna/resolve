import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/milestones.dart';
import '../core/notifications.dart';
import '../core/widget_bridge.dart';
import '../models/habit.dart';
import '../models/mood.dart';
import '../models/relapse.dart';
import 'streak_storage.dart';

/// Source of truth for the single habit and its relapse log.
///
/// Backed by [StreakStorage]: every mutation persists immediately so the state
/// survives restarts (FR-7). The live streak is always derived from the stored
/// UTC `startedAt`, never a counter, so it is correct after force-quit/reboot.
/// Everything is keyed by habitId so multi-habit is a data change, not a
/// rewrite (SRS §7).
class HabitStore extends ChangeNotifier {
  HabitStore._(this._storage, this._habit, this._relapses);

  final StreakStorage? _storage;
  Habit? _habit;
  List<Relapse> _relapses;

  /// Whether a habit has been created yet. False on first launch → the app
  /// shows onboarding instead of Home.
  bool get isConfigured => _habit != null;

  /// The active habit. Only valid once [isConfigured]; the UI that reads this
  /// is gated behind onboarding.
  Habit get habit => _habit!;

  /// Most-recent first.
  List<Relapse> get relapses => List.unmodifiable(_relapses);

  int get relapseCount => _relapses.length;

  /// Load persisted state. On first run there is no habit yet - returns an
  /// unconfigured store so the app can present the welcome flow.
  static Future<HabitStore> load(StreakStorage storage) async {
    final saved = storage.load();
    if (saved != null) {
      return HabitStore._(storage, saved.habit, saved.relapses);
    }
    return HabitStore._(storage, null, <Relapse>[]);
  }

  /// In-memory store seeded with sample data - for tests / previews only
  /// (no persistence).
  factory HabitStore.sample() {
    final seed = _seed();
    return HabitStore._(null, seed.habit, seed.relapses);
  }

  // Persist the full state. Fire-and-forget: shared_preferences serializes
  // writes internally, and every mutation calls this right after updating state
  // so the write is enqueued before any subsequent kill (NFR-6).
  void _persist() {
    final storage = _storage;
    final habit = _habit;
    if (storage == null || habit == null) return;
    unawaited(storage.save(habit, _relapses));
  }

  // Reconcile scheduled milestone notifications with current state. Gated to
  // the persisted store so sample/preview instances never touch platform
  // channels. Fire-and-forget, like [_persist].
  void _syncNotifications() {
    final habit = _habit;
    if (_storage == null || habit == null) return;
    unawaited(NotificationService.instance.syncMilestones(habit));
  }

  // Push the current habit to the home-screen widget. Gated + fire-and-forget,
  // same as [_syncNotifications].
  void _pushWidget() {
    final habit = _habit;
    if (_storage == null || habit == null) return;
    unawaited(WidgetBridge.save(habit));
  }

  /// Create (or replace) the habit and start its clock now (FR-1.2/1.3).
  /// A fresh habit resets stats: best streak 0, relapses cleared, success 100,
  /// no celebrated milestones. Keeps the same habitId so downstream data stays
  /// keyed consistently (SRS §7).
  void createHabit({required String name, String? why}) {
    _habit = Habit(
      id: _habit?.id ?? 'habit-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      why: (why != null && why.trim().isEmpty) ? null : why?.trim(),
      startedAt: DateTime.now().toUtc(),
      bestStreakMs: 0,
      successRate: 100,
      celebratedMilestones: const {},
    );
    _relapses = [];
    _persist();
    _syncNotifications();
    _pushWidget();
    notifyListeners();
  }

  /// Edit the habit's name/reason without touching the streak (FR-9.2). The
  /// clock, best streak, relapses, success rate, and celebrated milestones are
  /// all preserved - editing never costs progress.
  void editHabit({required String name, String? why}) {
    final current = _habit;
    if (current == null) return;
    final w = why?.trim();
    _habit = Habit(
      id: current.id,
      name: name.trim(),
      why: (w == null || w.isEmpty) ? null : w,
      startedAt: current.startedAt,
      bestStreakMs: current.bestStreakMs,
      successRate: current.successRate,
      celebratedMilestones: current.celebratedMilestones,
    );
    _persist();
    _syncNotifications();
    _pushWidget();
    notifyListeners();
  }

  /// Record that a milestone's celebration has fired for the current streak so
  /// it never fires twice (FR-4.2). Cleared on relapse.
  void markCelebrated(int milestone) {
    final current = _habit;
    if (current == null || current.celebratedMilestones.contains(milestone)) {
      return;
    }
    _habit = current.copyWith(
      celebratedMilestones: {...current.celebratedMilestones, milestone},
    );
    _persist();
    notifyListeners();
  }

  /// Log a relapse (FR-3.3): record the streak reached, update best streak if
  /// beaten, reset the clock to now, drop the success rate, and re-lock all
  /// milestones for the new streak (FR-4.4).
  void logRelapse({required Mood mood, String? note}) {
    final current = _habit;
    if (current == null) return;
    final now = DateTime.now().toUtc();
    final reachedMs =
        now.difference(current.startedAt).inMilliseconds.clamp(0, 1 << 62);
    final best =
        reachedMs > current.bestStreakMs ? reachedMs : current.bestStreakMs;
    final trimmed = note?.trim();

    _relapses = [
      Relapse(
        id: 'r${now.microsecondsSinceEpoch}',
        habitId: current.id,
        at: now,
        reachedMs: reachedMs,
        mood: mood,
        note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      ),
      ..._relapses,
    ];
    _habit = current.copyWith(
      startedAt: now,
      bestStreakMs: best,
      successRate: successRateAfterRelapse(current.successRate),
      celebratedMilestones: const {},
    );
    _persist();
    _syncNotifications();
    _pushWidget();
    notifyListeners();
  }

  /// Replace all state from an imported backup (Tier-3). Overwrites the habit
  /// and the full relapse log wholesale, persists, and re-arms notifications.
  void restore(Habit habit, List<Relapse> relapses) {
    _habit = habit;
    _relapses = List.of(relapses);
    _persist();
    _syncNotifications();
    _pushWidget();
    notifyListeners();
  }

  /// Seed matching `prototype/Resolve.dc.html`: a 12d 4h 37m streak on
  /// "No Social Media" with three historical relapses.
  static ({Habit habit, List<Relapse> relapses}) _seed() {
    final now = DateTime.now().toUtc();
    const day = Duration(milliseconds: Duration.millisecondsPerDay);
    const habitId = 'sample-habit';

    final habit = Habit(
      id: habitId,
      name: 'No Social Media',
      why: 'Reclaim my attention and my evenings.',
      startedAt: now.subtract(const Duration(days: 12, hours: 4, minutes: 37)),
      bestStreakMs: (const Duration(days: 18, hours: 5)).inMilliseconds,
      successRate: 93,
    );

    final relapses = <Relapse>[
      Relapse(
        id: 'r1',
        habitId: habitId,
        at: now.subtract(day * 6),
        reachedMs: (const Duration(days: 6, hours: 3)).inMilliseconds,
        mood: Mood.tempted,
        note: 'Late-night boredom scroll after everyone went to bed.',
      ),
      Relapse(
        id: 'r2',
        habitId: habitId,
        at: now.subtract(day * 22),
        reachedMs: (const Duration(days: 9)).inMilliseconds,
        mood: Mood.crushed,
        note: 'Rough day at work, wanted to numb out.',
      ),
      Relapse(
        id: 'r3',
        habitId: habitId,
        at: now.subtract(day * 41),
        reachedMs: (const Duration(days: 18, hours: 5)).inMilliseconds,
        mood: Mood.okay,
        note: 'Opened the app on autopilot before I noticed.',
      ),
    ];

    return (habit: habit, relapses: relapses);
  }
}
