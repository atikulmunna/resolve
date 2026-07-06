import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../core/streak.dart';
import '../../data/habit_store.dart';
import '../../models/mood.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Present the relapse bottom sheet (Design Spec §3.4). Dim blurred scrim +
/// slide-up sheet; dismissing with the scrim, back gesture, or "Stay strong"
/// makes no change (FR-3.4).
Future<void> showRelapseSheet(BuildContext context, HabitStore store) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Log a relapse',
    barrierColor: Colors.transparent, // the sheet renders its own scrim
    transitionDuration: const Duration(milliseconds: 360),
    pageBuilder: (_, _, _) => RelapseSheet(store: store),
    transitionBuilder: (context, animation, _, child) {
      final slide = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.2, 0.85, 0.2, 1),
      );
      return Stack(
        children: [
          // Scrim: fade + blur.
          FadeTransition(
            opacity: animation,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(color: Colors.black.withValues(alpha: 0.62)),
              ),
            ),
          ),
          // Sheet: slide up from the bottom.
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(slide),
            child: Align(alignment: Alignment.bottomCenter, child: child),
          ),
        ],
      );
    },
  );
}

class RelapseSheet extends StatefulWidget {
  const RelapseSheet({super.key, required this.store});

  final HabitStore store;

  @override
  State<RelapseSheet> createState() => _RelapseSheetState();
}

class _RelapseSheetState extends State<RelapseSheet> {
  final TextEditingController _note = TextEditingController();
  Mood? _mood;
  late final String _streakLabel = _label();

  String _label() {
    final s = Streak.since(widget.store.habit.startedAt);
    return '${s.days}d ${s.hours}h';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _confirm() {
    final mood = _mood;
    if (mood == null) return;
    widget.store.logRelapse(mood: mood, note: _note.text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Lift the sheet above the keyboard when the note field is focused.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(22, 12, 22, 26 + bottomInset),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0C1512), Color(0xFF070D0B)],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 60,
              offset: const Offset(0, -20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Text(
              'Log a relapse',
              textAlign: TextAlign.center,
              style: AppType.oswaldStyle(
                size: 22,
                weight: 600,
                letterSpacing: 1,
                color: AppColors.textHiAlt,
              ),
            ),
            const SizedBox(height: 8),
            _subtitle(),
            const SizedBox(height: 22),
            _label2('HOW ARE YOU FEELING?'),
            const SizedBox(height: 10),
            _moodRow(),
            const SizedBox(height: 20),
            _label2('WHAT HAPPENED?'),
            const SizedBox(height: 10),
            _noteField(),
            const SizedBox(height: 20),
            _confirmButton(),
            const SizedBox(height: 10),
            _stayStrongButton(),
          ],
        ),
      ),
    );
  }

  Widget _subtitle() {
    final base = AppType.groteskStyle(
      size: 13,
      color: Colors.white.withValues(alpha: 0.55),
      height: 1.5,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Text.rich(
          TextSpan(
            style: base,
            children: [
              const TextSpan(text: 'Your '),
              TextSpan(
                text: _streakLabel,
                style: base.copyWith(color: AppColors.danger300),
              ),
              const TextSpan(
                text: " streak will reset to zero. Be honest, "
                    "the data is only useful if it's true.",
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _label2(String text) => Text(
        text,
        style: AppType.oswaldStyle(
          size: 10,
          letterSpacing: 2,
          color: AppColors.emerald400.withValues(alpha: 0.8),
        ),
      );

  Widget _moodRow() {
    return Row(
      children: [
        for (var i = 0; i < Mood.values.length; i++) ...[
          if (i > 0) const SizedBox(width: 7),
          Expanded(child: _moodPill(Mood.values[i])),
        ],
      ],
    );
  }

  Widget _moodPill(Mood mood) {
    final selected = _mood == mood;
    return GestureDetector(
      onTap: () => setState(() => _mood = mood),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: selected
              ? mood.color.withValues(alpha: 0.13)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: selected
                ? mood.color
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          mood.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: AppType.oswaldStyle(
            size: 10,
            letterSpacing: 0.5,
            color: selected ? mood.color : Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _noteField() {
    return TextField(
      controller: _note,
      cursorColor: AppColors.emerald400,
      style: AppType.groteskStyle(size: 15, color: AppColors.textHiAlt),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'What triggered it? (optional)',
        hintStyle: AppType.groteskStyle(
          size: 15,
          color: Colors.white.withValues(alpha: 0.26),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _border(Colors.white.withValues(alpha: 0.1)),
        enabledBorder: _border(Colors.white.withValues(alpha: 0.1)),
        focusedBorder: _border(AppColors.emerald400.withValues(alpha: 0.55)),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color),
      );

  Widget _confirmButton() {
    final enabled = _mood != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.emerald400, AppColors.emerald600],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? _confirm : null,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: Text(
                'CONFIRM RESET',
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
      ),
    );
  }

  Widget _stayStrongButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            'STAY STRONG',
            style: AppType.oswaldStyle(
              size: 13,
              letterSpacing: 2,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }
}
