import 'package:flutter/material.dart';

import '../../data/habit_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/overlay_scaffold.dart';

/// Create ("New Habit") - slide-up overlay (Design Spec §3.3 / FR-1).
/// Collects a required habit name and an optional reason, then starts the clock
/// on "Start the clock". Pre-fills [initialName]/[initialWhy] when editing.
class CreateScreen extends StatefulWidget {
  const CreateScreen({
    super.key,
    required this.store,
    this.initialName,
    this.initialWhy,
    this.edit = false,
  });

  final HabitStore store;
  final String? initialName;
  final String? initialWhy;

  /// When true, saving updates name/reason and keeps the streak (FR-9.2);
  /// otherwise it starts a fresh clock (FR-1.2).
  final bool edit;

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName ?? '');
  late final TextEditingController _why =
      TextEditingController(text: widget.initialWhy ?? '');

  @override
  void dispose() {
    _name.dispose();
    _why.dispose();
    super.dispose();
  }

  bool get _canStart => _name.text.trim().isNotEmpty;

  void _start() {
    if (!_canStart) return;
    if (widget.edit) {
      widget.store.editHabit(name: _name.text.trim(), why: _why.text);
    } else {
      widget.store.createHabit(name: _name.text.trim(), why: _why.text);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayScaffold(
      title: widget.edit ? 'EDIT HABIT' : 'NEW HABIT',
      onBack: () => Navigator.of(context).pop(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
        physics: const BouncingScrollPhysics(),
        children: [
          Text(
            widget.edit
                ? 'Refine what you\nstand for.'
                : 'What are you\nbreaking free from?',
            style: AppType.groteskStyle(
              size: 26,
              weight: 700,
              letterSpacing: -0.5,
              color: AppColors.textHi,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 26),
          _label('THE HABIT'),
          const SizedBox(height: 9),
          _field(
            controller: _name,
            hint: 'e.g. No Social Media',
            fontSize: 16,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          _label('YOUR REASON'),
          const SizedBox(height: 9),
          _field(
            controller: _why,
            hint: "Why does this matter to you? Write it down, "
                "you'll read it when it's hard.",
            fontSize: 15,
            minLines: 3,
            maxLines: 5,
          ),
          if (!widget.edit) ...[
            const SizedBox(height: 22),
            _infoCard(),
          ],
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
        child: _startButton(),
      ),
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

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: AppColors.emerald500.withValues(alpha: 0.07),
        border: Border.all(color: AppColors.emerald400.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.schedule, size: 19, color: AppColors.emerald400),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'The clock starts the moment you begin, down to the second. '
              'No pause. No excuses. Just proof.',
              style: AppType.groteskStyle(
                size: 13,
                color: const Color(0xFFC8F0E1).withValues(alpha: 0.82),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _startButton() {
    final enabled = _canStart;
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
            onTap: enabled ? _start : null,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: Text(
                widget.edit ? 'SAVE CHANGES' : 'START THE CLOCK',
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
