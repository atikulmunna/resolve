import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'core/notifications.dart';
import 'core/widget_bridge.dart';
import 'data/habit_store.dart';
import 'data/streak_storage.dart';
import 'features/craving/craving_screen.dart';
import 'models/habit.dart';
import 'models/mood.dart';
import 'models/relapse.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted state before first paint so the timer is correct
  // immediately on launch (FR-7 / NFR-3).
  final storage = await StreakStorage.open();
  final store = await HabitStore.load(storage);

  // Demo/marketing build: seed a streak 10s shy of 30 days (so the milestone
  // celebration auto-fires) plus mock relapses for the pulse + Journey. Enabled
  // only with `--dart-define=SEED_DEMO=true`; a no-op in normal builds.
  if (const bool.fromEnvironment('SEED_DEMO')) {
    _seedDemo(store);
  }

  // Milestone notifications (Tier-1): init the local scheduler and reconcile
  // against the loaded streak so pending 30/60/90-day alerts are armed.
  await NotificationService.instance.init();
  if (store.isConfigured) {
    unawaited(NotificationService.instance.syncMilestones(store.habit));
    // Refresh the home-screen widget with the current streak on launch.
    unawaited(WidgetBridge.save(store.habit));
  }

  // Portrait only (SRS §2.3).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // AMOLED-black system bars, light icons.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // The home-screen widget's PANIC pill deep-links here (resolve://panic).
  // Open the breathing tool for both a cold launch and a running-app tap.
  void handlePanic(Uri? uri) {
    if (uri?.host != 'panic' || !store.isConfigured) return;
    // Defer to after the frame so the navigator/Home is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) showCraving(ctx, store);
    });
  }

  HomeWidget.widgetClicked.listen(handlePanic);
  unawaited(HomeWidget.initiallyLaunchedFromHomeWidget().then(handlePanic));

  runApp(ResolveApp(store: store));
}

/// Overwrite the store with a demo streak + mock relapse history for screenshots.
/// Re-seeds on every launch so the near-milestone crossing can be re-captured.
void _seedDemo(HabitStore store) {
  final now = DateTime.now().toUtc();
  final start =
      now.subtract(const Duration(days: 29, hours: 23, minutes: 59, seconds: 50));

  // A relapse at a given days-ago and local hour, so Journey's time-of-day
  // insight has spread.
  DateTime at(int daysAgo, int hour) {
    final d = DateTime.now().subtract(Duration(days: daysAgo));
    return DateTime(d.year, d.month, d.day, hour, 30).toUtc();
  }

  const habitId = 'demo-habit';
  final habit = Habit(
    id: habitId,
    name: 'No Social Media',
    why: 'Reclaim my attention and my evenings.',
    startedAt: start,
    bestStreakMs: const Duration(days: 31, hours: 6).inMilliseconds,
    successRate: 88,
    celebratedMilestones: const {},
  );

  Relapse r(String id, DateTime when, Duration reached, Mood mood, String note) =>
      Relapse(
        id: id,
        habitId: habitId,
        at: when,
        reachedMs: reached.inMilliseconds,
        mood: mood,
        note: note,
      );

  // Most-recent first; all within the 91-day pulse window, before the current
  // streak began.
  final relapses = <Relapse>[
    r('d1', at(30, 23), const Duration(days: 17), Mood.tempted,
        'Late-night boredom scroll after everyone went to bed.'),
    r('d2', at(47, 15), const Duration(days: 9), Mood.crushed,
        'Rough day at work, wanted to numb out.'),
    r('d3', at(68, 8), const Duration(days: 12), Mood.okay,
        'Opened the app on autopilot before I noticed.'),
    r('d4', at(85, 21), const Duration(days: 6), Mood.tempted,
        'Reflex reach while waiting in a queue.'),
  ];

  store.restore(habit, relapses);
}
