import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';
import '../models/relapse.dart';

/// Local, offline-only persistence (FR-7). Serializes the habit and relapse log
/// to shared_preferences as JSON. No data leaves the device (FR-7.2). The live
/// timer is reconstructed from the stored UTC `startedAt`, so it is correct
/// after force-quit or reboot (NFR-3).
class StreakStorage {
  StreakStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _kHabit = 'resolve.habit.v1';
  static const _kRelapses = 'resolve.relapses.v1';

  static Future<StreakStorage> open() async =>
      StreakStorage(await SharedPreferences.getInstance());

  /// Returns the persisted state, or null on first run / if unreadable.
  ({Habit habit, List<Relapse> relapses})? load() {
    final raw = _prefs.getString(_kHabit);
    if (raw == null) return null;
    try {
      final habit = Habit.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final relapses = (_prefs.getStringList(_kRelapses) ?? [])
          .map((s) => Relapse.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      return (habit: habit, relapses: relapses);
    } catch (_) {
      // Corrupt data - treat as first run rather than crashing.
      return null;
    }
  }

  /// Persist the full state. Called after every mutation; on a relapse this is
  /// the transactional write that must never lose the log (NFR-6).
  Future<void> save(Habit habit, List<Relapse> relapses) async {
    await _prefs.setString(_kHabit, jsonEncode(habit.toJson()));
    await _prefs.setStringList(
      _kRelapses,
      relapses.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }
}
