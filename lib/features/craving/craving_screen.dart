import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../data/habit_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../relapse/relapse_sheet.dart';
import 'lung.dart';

/// Present the craving / panic tool (Tier-1 feature): a calm full-screen
/// breathing guide for the moment of temptation. Fades in (not a slide-up) so
/// it feels like a place to land, not another sheet.
Future<void> showCraving(BuildContext context, HabitStore store) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, _, _) => CravingScreen(store: store),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}

/// A guided 4-7-8 breathing screen. One repeating clock drives an emerald orb
/// that inhales (4s) · holds (7s) · exhales (8s); the user's own "why" sits
/// below it, with a reassurance that the craving passes. Two calm exits: return
/// to the timer, or a quiet path to log a slip if it happened.
class CravingScreen extends StatefulWidget {
  const CravingScreen({super.key, required this.store});

  final HabitStore store;

  @override
  State<CravingScreen> createState() => _CravingScreenState();
}

class _CravingScreenState extends State<CravingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // One master clock, mirroring Home: a per-frame repaint signal whose value is
  // derived from wall time, and which pauses when the app is backgrounded.
  late final AnimationController _clock;
  final DateTime _openedAt = DateTime.now();

  // 4-7-8, in seconds.
  static const double _inhale = 4;
  static const double _hold = 7;
  static const double _exhale = 8;
  static const double _cycle = _inhale + _hold + _exhale; // 19s

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  double get _elapsed =>
      DateTime.now().difference(_openedAt).inMilliseconds / 1000;

  /// The current breath: a 0..1 lung fill and a label, from seconds-in-cycle.
  /// Fills on the inhale, holds full, drains on the exhale (the 4-7-8 rhythm).
  ({double fill, String label}) _breath() {
    final s = _elapsed % _cycle;
    if (s < _inhale) {
      final t = Curves.easeInOut.transform(s / _inhale);
      return (fill: t, label: 'Breathe in');
    }
    if (s < _inhale + _hold) {
      return (fill: 1.0, label: 'Hold');
    }
    final t = Curves.easeInOut.transform((s - _inhale - _hold) / _exhale);
    return (fill: 1.0 - t, label: 'Breathe out');
  }

  void _logSlip() {
    Navigator.of(context).pop(); // leave the craving screen first
    showRelapseSheet(context, widget.store);
  }

  @override
  Widget build(BuildContext context) {
    final why = widget.store.habit.why;
    final hasWhy = why != null && why.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.32),
            radius: 1.1,
            colors: [Color(0xFF0C2119), Color(0xFF040F0B), Color(0xFF000000)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 12, 30, 24),
            child: Column(
              children: [
                // Close (x): top-left, calm.
                Align(
                  alignment: Alignment.centerLeft,
                  child: _iconButton(
                    Icons.close,
                    () => Navigator.of(context).pop(),
                  ),
                ),
                const Spacer(),
                _lung(),
                const SizedBox(height: 34),
                Text(
                  'THIS WILL PASS',
                  textAlign: TextAlign.center,
                  style: AppType.oswaldStyle(
                    size: 12,
                    letterSpacing: 4,
                    color: AppColors.emerald400.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    hasWhy
                        ? '“${why.trim()}”'
                        : 'The urge peaks and fades. Ride it out, and '
                            'you stay who you decided to be.',
                    textAlign: TextAlign.center,
                    style: AppType.groteskStyle(
                      size: hasWhy ? 17 : 15,
                      color: AppColors.textHi.withValues(alpha: 0.92),
                      height: 1.55,
                    ),
                  ),
                ),
                if (hasWhy) ...[
                  const SizedBox(height: 14),
                  Text(
                    'This is why. Cravings pass in minutes, but this stays.',
                    textAlign: TextAlign.center,
                    style: AppType.groteskStyle(
                      size: 13,
                      color: AppColors.textMute,
                      height: 1.5,
                    ),
                  ),
                ],
                const Spacer(),
                _primaryButton("I'M OK NOW", () => Navigator.of(context).pop()),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: _logSlip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMute,
                  ),
                  child: Text(
                    'I slipped, log it',
                    style: AppType.oswaldStyle(
                      size: 11,
                      letterSpacing: 1.5,
                      color: AppColors.textMute,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _lung() {
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final b = _breath();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Halo behind the lung, brightens as it fills with breath.
                  Opacity(
                    opacity: 0.22 + 0.5 * b.fill,
                    child: Transform.scale(
                      scale: 0.85 + 0.2 * b.fill,
                      child: ImageFiltered(
                        imageFilter:
                            ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          width: 190,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.emerald500.withValues(alpha: 0.6),
                                AppColors.emerald500.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.72],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(210, 234),
                    painter: LungPainter(fill: b.fill, t: _elapsed),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text(
              b.label.toUpperCase(),
              style: AppType.oswaldStyle(
                size: 15,
                letterSpacing: 4,
                color: AppColors.textMint,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 22,
            color: AppColors.textHi.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald400, AppColors.emerald600],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald500.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              label,
              style: AppType.oswaldStyle(
                size: 14,
                weight: 600,
                letterSpacing: 2,
                color: const Color(0xFF04140E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
