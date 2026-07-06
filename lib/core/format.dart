/// Shared duration/time formatting used across screens.
abstract final class Fmt {
  static String _two(int n) => n.toString().padLeft(2, '0');

  /// "Xd Yh" - compact streak length (stat chips, relapse history).
  static String dh(int ms) {
    final d = ms ~/ Duration.millisecondsPerDay;
    final h = (ms ~/ Duration.millisecondsPerHour) % 24;
    return '${d}d ${h}h';
  }

  /// "Xd HHh MMm" - the Journey hero streak (padded hours/minutes).
  static String dhm(Duration elapsed) {
    final d = elapsed.inDays;
    final h = elapsed.inHours % 24;
    final m = elapsed.inMinutes % 60;
    return '${d}d ${_two(h)}h ${_two(m)}m';
  }

  /// Relative age: "today" or "Nd ago".
  static String ago(DateTime at, {DateTime? now}) {
    final d = (now ?? DateTime.now()).difference(at).inDays;
    return d <= 0 ? 'today' : '${d}d ago';
  }
}
