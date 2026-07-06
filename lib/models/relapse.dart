import 'mood.dart';

/// A logged reset event (SRS §4). Records the streak length reached, the
/// moment it happened, the mood check-in, and an optional note/trigger.
///
/// Keyed by [habitId] even though v1 has one habit, so multi-habit is a data
/// change, not a rewrite (SRS §7). Timestamps are stored in UTC (NFR-3).
class Relapse {
  const Relapse({
    required this.id,
    required this.habitId,
    required this.at,
    required this.reachedMs,
    required this.mood,
    this.note,
  });

  final String id;
  final String habitId;

  /// When the relapse was logged (UTC).
  final DateTime at;

  /// Streak length reached at reset, in milliseconds.
  final int reachedMs;

  final Mood mood;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'habitId': habitId,
        'at': at.toUtc().toIso8601String(),
        'reachedMs': reachedMs,
        'mood': mood.key,
        'note': note,
      };

  factory Relapse.fromJson(Map<String, dynamic> json) => Relapse(
        id: json['id'] as String,
        habitId: json['habitId'] as String,
        at: DateTime.parse(json['at'] as String).toUtc(),
        reachedMs: json['reachedMs'] as int,
        mood: Mood.fromKey(json['mood'] as String),
        note: json['note'] as String?,
      );
}
