/// The single tracked habit (SRS §4).
///
/// [startedAt] is the current streak origin, stored in UTC to survive
/// timezone/DST changes (NFR-3). The live streak is always derived as
/// `now() - startedAt` - never a running counter (SRS §6.1). See [Streak].
class Habit {
  const Habit({
    required this.id,
    required this.name,
    this.why,
    required this.startedAt,
    this.bestStreakMs = 0,
    this.successRate = 100,
    this.celebratedMilestones = const {},
  });

  final String id;
  final String name;
  final String? why;

  /// Current streak origin (UTC, millisecond precision).
  final DateTime startedAt;

  /// Longest streak ever reached across attempts, in milliseconds.
  final int bestStreakMs;

  /// Rolling 0-100 consistency score (SRS §4.6).
  final int successRate;

  /// Which day thresholds have already celebrated for the *current* streak.
  /// Cleared on relapse.
  final Set<int> celebratedMilestones;

  Habit copyWith({
    String? name,
    String? why,
    DateTime? startedAt,
    int? bestStreakMs,
    int? successRate,
    Set<int>? celebratedMilestones,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      why: why ?? this.why,
      startedAt: startedAt ?? this.startedAt,
      bestStreakMs: bestStreakMs ?? this.bestStreakMs,
      successRate: successRate ?? this.successRate,
      celebratedMilestones: celebratedMilestones ?? this.celebratedMilestones,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'why': why,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'bestStreakMs': bestStreakMs,
        'successRate': successRate,
        'celebratedMilestones': celebratedMilestones.toList(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        why: json['why'] as String?,
        startedAt: DateTime.parse(json['startedAt'] as String).toUtc(),
        bestStreakMs: json['bestStreakMs'] as int? ?? 0,
        successRate: json['successRate'] as int? ?? 100,
        celebratedMilestones: {
          for (final m in (json['celebratedMilestones'] as List? ?? []))
            m as int,
        },
      );
}
