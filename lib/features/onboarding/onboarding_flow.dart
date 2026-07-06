import 'package:flutter/material.dart';

import '../../data/habit_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../home/widgets/ambient_orbs.dart';
import 'widgets/brand_mark.dart';
import 'widgets/ignition_mark.dart';

/// First-run welcome flow (shown when the store is unconfigured): an impressive
/// welcome → habit input → "good luck" send-off, after which the clock starts
/// and the app reveals Home. On completion it calls [HabitStore.createHabit];
/// the app root swaps to Home when the store becomes configured.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.store});

  final HabitStore store;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _why = TextEditingController();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _clock.dispose();
    _name.dispose();
    _why.dispose();
    super.dispose();
  }

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
  }

  void _finish() {
    // Starts the clock; the root gate swaps to Home when configured.
    widget.store.createHabit(name: _name.text.trim(), why: _why.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.3,
            colors: AppColors.ambient,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            AmbientOrbs(clock: _clock),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _stepFor(_step),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepFor(int step) {
    return switch (step) {
      0 => _WelcomeStep(key: const ValueKey(0), clock: _clock, onBegin: () => _go(1)),
      1 => _InputStep(
          key: const ValueKey(1),
          name: _name,
          why: _why,
          onBack: () => _go(0),
          onContinue: () => _go(2),
        ),
      _ => _GoodLuckStep(
          key: const ValueKey(2),
          clock: _clock,
          habitName: _name.text.trim(),
          onStart: _finish,
        ),
    };
  }
}

// ── Step 0: Welcome ──────────────────────────────────────────────────────────
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({
    super.key,
    required this.clock,
    required this.onBegin,
  });

  final Listenable clock;
  final VoidCallback onBegin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        BrandMark(clock: clock, size: 168),
        const SizedBox(height: 34),
        Text(
          'RESOLVE',
          style: AppType.oswaldStyle(
            size: 34,
            weight: 600,
            letterSpacing: 8,
            color: AppColors.textHi,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Reclaim your time, one second at a time.',
          textAlign: TextAlign.center,
          style: AppType.groteskStyle(
            size: 14,
            color: AppColors.textMute,
            height: 1.5,
          ),
        ),
        const Spacer(flex: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            "You're about to start a clock that doesn't stop. "
            "Every second you hold the line is proof you're changing.",
            textAlign: TextAlign.center,
            style: AppType.groteskStyle(
              size: 14.5,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: 'BEGIN', onTap: onBegin),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Step 1: Input ────────────────────────────────────────────────────────────
class _InputStep extends StatefulWidget {
  const _InputStep({
    super.key,
    required this.name,
    required this.why,
    required this.onBack,
    required this.onContinue,
  });

  final TextEditingController name;
  final TextEditingController why;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<_InputStep> createState() => _InputStepState();
}

class _InputStepState extends State<_InputStep> {
  bool get _canContinue => widget.name.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BackButton(onTap: widget.onBack),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 18),
            children: [
              Text(
                'What are you\nbreaking free from?',
                style: AppType.groteskStyle(
                  size: 26,
                  weight: 700,
                  letterSpacing: -0.5,
                  color: AppColors.textHi,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 28),
              _label('THE HABIT'),
              const SizedBox(height: 9),
              _field(
                controller: widget.name,
                hint: 'e.g. No Social Media',
                fontSize: 16,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 22),
              _label('YOUR REASON'),
              const SizedBox(height: 9),
              _field(
                controller: widget.why,
                hint: "Why does this matter to you? Write it down, "
                    "you'll read it when it's hard.",
                fontSize: 15,
                minLines: 3,
                maxLines: 5,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'CONTINUE',
          onTap: _canContinue ? widget.onContinue : null,
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppType.oswaldStyle(
          size: 10,
          letterSpacing: 2,
          color: AppColors.emerald400.withValues(alpha: 0.8),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required double fontSize,
    int minLines = 1,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      cursorColor: AppColors.emerald400,
      style: AppType.groteskStyle(
        size: fontSize,
        color: AppColors.textHiAlt,
        height: 1.5,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: AppType.groteskStyle(
          size: fontSize,
          color: Colors.white.withValues(alpha: 0.26),
          height: 1.5,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: _border(Colors.white.withValues(alpha: 0.1)),
        enabledBorder: _border(Colors.white.withValues(alpha: 0.1)),
        focusedBorder: _border(AppColors.emerald400.withValues(alpha: 0.55)),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: color),
      );
}

// ── Step 2: Good luck ────────────────────────────────────────────────────────
class _GoodLuckStep extends StatelessWidget {
  const _GoodLuckStep({
    super.key,
    required this.clock,
    required this.habitName,
    required this.onStart,
  });

  final Listenable clock;
  final String habitName;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final name = habitName.isEmpty ? 'that habit' : habitName;
    return Column(
      children: [
        const Spacer(flex: 2),
        IgnitionMark(clock: clock, size: 150),
        const SizedBox(height: 36),
        Text(
          'Good luck.',
          style: AppType.oswaldStyle(
            size: 30,
            weight: 600,
            letterSpacing: 1,
            color: AppColors.textHi,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text.rich(
            TextSpan(
              style: AppType.groteskStyle(
                size: 15,
                color: Colors.white.withValues(alpha: 0.62),
                height: 1.6,
              ),
              children: [
                const TextSpan(text: 'From this second on, you’re done with '),
                TextSpan(
                  text: name,
                  style: AppType.groteskStyle(
                    size: 15,
                    weight: 600,
                    color: AppColors.emerald300,
                    height: 1.6,
                  ),
                ),
                const TextSpan(
                  text: '. No pause, no excuses. Just the clock, and you.',
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Spacer(flex: 3),
        PrimaryButton(label: 'START THE CLOCK', onTap: onStart),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Shared bits ──────────────────────────────────────────────────────────────
/// Full-width emerald-gradient CTA; dims and disables when [onTap] is null.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 54,
              alignment: Alignment.center,
              child: Text(
                label,
                style: AppType.oswaldStyle(
                  size: 15,
                  weight: 600,
                  letterSpacing: 2,
                  color: const Color(0xFF04140E),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: const Icon(
            Icons.chevron_left,
            size: 24,
            color: Color(0xFFDFF7EE),
          ),
        ),
      ),
    );
  }
}
