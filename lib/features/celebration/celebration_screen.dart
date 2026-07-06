import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'milestone_copy.dart';

/// Present the full-screen milestone celebration (Design Spec §3.6). Used both
/// for the auto-fire on first crossing (FR-4.2) and node-tap previews (FR-4.3).
Future<void> showCelebration(BuildContext context, int milestone) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => CelebrationScreen(milestone: milestone),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class CelebrationScreen extends StatefulWidget {
  const CelebrationScreen({super.key, required this.milestone});

  final int milestone;

  @override
  State<CelebrationScreen> createState() => _CelebrationScreenState();
}

class _CelebrationScreenState extends State<CelebrationScreen>
    with TickerProviderStateMixin {
  // Frame clock for the looping confetti + pulse rings; values come from
  // elapsed wall time since the screen opened.
  late final AnimationController _loop;
  // One-shot entrance for the badge "pop".
  late final AnimationController _entrance;
  final DateTime _openedAt = DateTime.now();
  late final List<_Shard> _shards;

  @override
  void initState() {
    super.initState();
    _shards = List.generate(20, _Shard.new);
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _loop.dispose();
    _entrance.dispose();
    super.dispose();
  }

  double get _elapsed =>
      DateTime.now().difference(_openedAt).inMilliseconds / 1000;

  @override
  Widget build(BuildContext context) {
    final copy = kMilestoneCopy[widget.milestone];
    return Scaffold(
      backgroundColor: AppColors.black,
      body: DecoratedBox(
        // Emerald radial background centered a little above middle.
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.28),
            radius: 1.0,
            colors: [Color(0xFF0D2C21), Color(0xFF04120C), Color(0xFF000000)],
            stops: [0.0, 0.58, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Confetti behind everything.
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, _) =>
                    CustomPaint(painter: _ConfettiPainter(_shards, _elapsed)),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(34),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _badgeWithRings(),
                    const SizedBox(height: 30),
                    Text(
                      copy?.title ?? '',
                      textAlign: TextAlign.center,
                      style: AppType.oswaldStyle(
                        size: 27,
                        weight: 600,
                        letterSpacing: 1,
                        color: AppColors.textHi,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        copy?.message ?? '',
                        textAlign: TextAlign.center,
                        style: AppType.groteskStyle(
                          size: 14,
                          color: const Color(
                            0xFFC8F0E1,
                          ).withValues(alpha: 0.78),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    _keepGoing(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeWithRings() {
    return SizedBox(
      width: 260,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _loop,
            builder: (context, _) => CustomPaint(
              size: const Size(260, 200),
              painter: _RingPainter(_elapsed),
            ),
          ),
          AnimatedBuilder(
            animation: _entrance,
            builder: (context, child) {
              final t = _entrance.value;
              final scale = 0.5 + Curves.easeOutBack.transform(t) * 0.5;
              return Opacity(
                opacity: Curves.easeIn.transform(t.clamp(0, 1)),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: _badge(),
          ),
        ],
      ),
    );
  }

  Widget _badge() {
    return Container(
      width: 152,
      height: 152,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.32, -0.48), // ~34% 26%
          radius: 0.95,
          colors: [AppColors.emerald300, AppColors.emerald600],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald500.withValues(alpha: 0.7),
            blurRadius: 64,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${widget.milestone}',
            style: AppType.groteskStyle(
              size: 62,
              weight: 700,
              color: const Color(0xFF04140E),
              height: 0.9,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'DAYS',
            style: AppType.oswaldStyle(
              size: 12,
              letterSpacing: 4,
              color: const Color(0xFF04140E).withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keepGoing() {
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
            color: AppColors.emerald500.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 15),
            child: Text(
              'KEEP GOING',
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

/// Two expanding pulse rings, staggered by 0.9s, looping every 2.4s.
class _RingPainter extends CustomPainter {
  const _RingPainter(this.elapsed);
  final double elapsed;

  static const double _period = 2.4;
  static const double _base = 90; // radius at scale 1

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (final (delay, alpha, color) in [
      (0.0, 0.5, AppColors.emerald400),
      (0.9, 0.4, AppColors.aqua400),
    ]) {
      final f = (((elapsed - delay) % _period) + _period) % _period / _period;
      if (elapsed < delay) continue;
      final scale = 0.7 + f * (2.5 - 0.7);
      final opacity = (0.85 * (1 - f)).clamp(0.0, 1.0) * (alpha / 0.5);
      canvas.drawCircle(
        center,
        _base * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.elapsed != elapsed;
}

/// A single confetti shard with deterministic parameters (mirrors the
/// prototype's index math).
class _Shard {
  _Shard(int i)
    : leftFraction = ((i * 53) % 100) / 100,
      duration = 1.9 + (i % 4) * 0.4,
      delay = (i % 6) * 0.18,
      size = 6 + (i % 3) * 3,
      baseRotation = ((i * 47) % 360) * math.pi / 180,
      // Emerald-dominant with a single aqua note (aurora, spent sparingly).
      color = const [
        AppColors.emerald400,
        AppColors.emerald300,
        AppColors.aqua400,
        AppColors.mintNode,
      ][i % 4];

  final double leftFraction;
  final double duration;
  final double delay;
  final double size;
  final double baseRotation;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.shards, this.elapsed);
  final List<_Shard> shards;
  final double elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in shards) {
      final t = elapsed - s.delay;
      if (t < 0) continue;
      final f = (t % s.duration) / s.duration;
      final x = s.leftFraction * size.width;
      final y = -24 + f * (size.height + 48);
      final opacity = (1 - f).clamp(0.0, 1.0);
      final rot = s.baseRotation + f * (400 * math.pi / 180);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: s.size,
        height: s.size * 1.7,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = s.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.elapsed != elapsed;
}
