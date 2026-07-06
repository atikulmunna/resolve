import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/celebration/milestone_copy.dart';
import '../models/habit.dart';
import 'milestones.dart';

/// Local milestone notifications (Tier-1). Fires an OS notification the moment
/// the streak crosses 30/60/90 days (even with the app closed) so the win
/// lands even when Resolve isn't open.
///
/// No backend: every notification is scheduled locally at an absolute instant
/// (`startedAt + threshold days`). Because that instant is timezone-independent
/// (it's just N×24h of elapsed time, the same rule as the live streak), we
/// schedule against `tz.UTC` and never need to detect the device timezone.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const String _channelId = 'resolve.milestones';
  static const String _channelName = 'Milestones';

  /// Initialize the plugin + timezone database and request the Android 13+
  /// POST_NOTIFICATIONS permission. Safe to call more than once.
  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    _ready = true;
  }

  /// Reconcile scheduled notifications with the current habit: cancel all, then
  /// re-schedule every future, not-yet-celebrated milestone. Called after any
  /// mutation that moves `startedAt` (create / relapse) or clears milestones.
  Future<void> syncMilestones(Habit habit) async {
    if (!_ready) await init();
    await _plugin.cancelAll();

    final startedAt = habit.startedAt.toUtc();
    final now = DateTime.now().toUtc();

    for (final m in kMilestones) {
      if (habit.celebratedMilestones.contains(m)) continue;
      final fireAt = startedAt.add(Duration(days: m));
      if (!fireAt.isAfter(now)) continue; // threshold already passed

      final copy = kMilestoneCopy[m];
      await _plugin.zonedSchedule(
        m, // notification id == day threshold (stable, de-dupes)
        copy?.title ?? '$m Days',
        copy?.message ?? "You've reached $m days.",
        tz.TZDateTime.from(fireAt, tz.UTC),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Streak milestone celebrations',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        // Day-granularity target → no exact-alarm permission needed (dodges the
        // Android 14 SCHEDULE_EXACT_ALARM restriction).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Drop every scheduled notification (e.g. on a full data wipe).
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }
}
