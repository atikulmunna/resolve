import 'dart:math' as math;

/// Wall-clock-driven animation phases.
///
/// Every looping animation in the app (breathing halo, rotating sheen, EKG
/// scroll, the ALIVE dot, ambient orbs) derives its value from `now()` instead
/// of holding its own controller. That keeps a single master clock: one
/// [AnimationController] triggers a repaint each frame, and these helpers turn
/// the current time into each animation's phase. Pausing the master clock
/// pauses everything; on resume, phases recompute from `now()` and stay in sync
/// with the ticking timer.
abstract final class Phase {
  /// Position within a loop of [period], in `[0, 1)`.
  static double loop(Duration period, {DateTime? now}) {
    final ms = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final p = period.inMilliseconds;
    return (ms % p) / p;
  }

  /// Smooth 0→1→0 triangle-ish wave over [period] using a cosine, so eases at
  /// the ends (matches CSS `ease-in-out` keyframes like `breathe`).
  static double pingPong(Duration period, {DateTime? now}) {
    final t = loop(period, now: now);
    return (1 - math.cos(t * 2 * math.pi)) / 2;
  }
}
