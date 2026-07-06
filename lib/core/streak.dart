/// Elapsed-time derivation. THE critical rule (SRS §6.1 / rule 1):
/// the streak is always `now() - startedAt`, computed on demand - never a
/// counter incremented in a loop. This makes the app immune to backgrounding,
/// dropped frames, process death, and reboot.
class Streak {
  /// [elapsed] is the live duration since the streak began.
  const Streak(this.elapsed);

  final Duration elapsed;

  /// Derive from an origin. Clamped at zero so a future [startedAt] (e.g. clock
  /// skew) never shows negative time.
  factory Streak.since(DateTime startedAt, {DateTime? now}) {
    final n = (now ?? DateTime.now()).toUtc();
    final diff = n.difference(startedAt.toUtc());
    return Streak(diff.isNegative ? Duration.zero : diff);
  }

  int get elapsedMs => elapsed.inMilliseconds;

  int get days => elapsed.inDays;
  int get hours => elapsed.inHours % 24;
  int get minutes => elapsed.inMinutes % 60;
  int get seconds => elapsed.inSeconds % 60;

  /// Fractional day count (for the milestone progress bar).
  double get fractionalDays => elapsedMs / Duration.millisecondsPerDay;

  /// The 60-second ring fill, 0..1 (SRS §6.2):
  /// `p = (elapsedMs % 60000) / 60000`.
  double get ringProgress =>
      (elapsedMs % Duration.millisecondsPerMinute) /
      Duration.millisecondsPerMinute;

  static String two(int n) => n.toString().padLeft(2, '0');
}
