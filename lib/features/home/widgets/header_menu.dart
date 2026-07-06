import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/glass.dart';

/// The (⋯) menu (Design Spec §3.1 / FR-9): the habit's "why" and the Edit /
/// Reset actions, rendered as separate floating-glass pieces (no single boxy
/// container) that lift off the black. Anchored under the header, top-right; a
/// scrim tap dismisses.
Future<void> showHeaderMenu(
  BuildContext context, {
  required String? why,
  required VoidCallback onEdit,
  required VoidCallback onReset,
  required VoidCallback onExport,
  required VoidCallback onImport,
}) {
  final topInset = MediaQuery.of(context).viewPadding.top;
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Menu',
    barrierColor: Colors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => _MenuLayer(
      top: topInset + 56,
      why: why,
      onEdit: onEdit,
      onReset: onReset,
      onExport: onExport,
      onImport: onImport,
    ),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.2, 0.8, 0.2, 1),
      );
      return FadeTransition(
        opacity: animation,
        child: Align(
          alignment: Alignment.topRight,
          child: FractionalTranslation(
            translation: Offset(0, (1 - curved.value) * -0.06),
            child: Transform.scale(
              scale: 0.96 + 0.04 * curved.value,
              alignment: Alignment.topRight,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

class _MenuLayer extends StatelessWidget {
  const _MenuLayer({
    required this.top,
    required this.why,
    required this.onEdit,
    required this.onReset,
    required this.onExport,
    required this.onImport,
  });

  final double top;
  final String? why;
  final VoidCallback onEdit;
  final VoidCallback onReset;
  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    // Full-screen stack; empty areas have no child so taps fall through to the
    // barrier and dismiss.
    return Stack(
      children: [
        Positioned(
          top: top,
          right: 22,
          // Menu is presented above the Scaffold - supply a Material ancestor
          // for the InkWell ripples.
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              width: 236,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FloatingGlass(
                    radius: 16,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: _whyContent(),
                  ),
                  const SizedBox(height: 8),
                  _actionPill(
                    context,
                    icon: Icons.edit_outlined,
                    label: 'Edit habit',
                    color: AppColors.textHi,
                    iconColor: const Color(0xFFDFF7EE),
                    onTap: onEdit,
                  ),
                  const SizedBox(height: 8),
                  _actionPill(
                    context,
                    icon: Icons.ios_share,
                    label: 'Export backup',
                    color: AppColors.textHi,
                    iconColor: const Color(0xFFDFF7EE),
                    onTap: onExport,
                  ),
                  const SizedBox(height: 8),
                  _actionPill(
                    context,
                    icon: Icons.download_outlined,
                    label: 'Import backup',
                    color: AppColors.textHi,
                    iconColor: const Color(0xFFDFF7EE),
                    onTap: onImport,
                  ),
                  const SizedBox(height: 8),
                  _actionPill(
                    context,
                    icon: Icons.refresh,
                    label: 'Reset timer',
                    color: AppColors.danger300,
                    iconColor: AppColors.danger300,
                    onTap: onReset,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _whyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'YOUR WHY',
          style: AppType.oswaldStyle(
            size: 9,
            letterSpacing: 2,
            color: AppColors.emerald400.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          (why == null || why!.trim().isEmpty) ? 'No reason set yet.' : why!,
          style: AppType.groteskStyle(
            size: 13,
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _actionPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return FloatingGlass(
      radius: 14,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).pop(); // close the menu first
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 12),
              Text(label, style: AppType.groteskStyle(size: 14, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
