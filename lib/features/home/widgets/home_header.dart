import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Home header: "CURRENT STREAK" over the habit name, with a glass (⋯) menu
/// button on the right (Design Spec §3.1). The menu dropdown is a later screen;
/// the button is present but inert for now.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.name, this.onMenu});

  final String name;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'CURRENT STREAK',
                style: AppType.oswaldStyle(
                  size: 10,
                  letterSpacing: 3,
                  color: AppColors.emerald400.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: AppType.oswaldStyle(
                  size: 23,
                  weight: 600,
                  letterSpacing: 0.4,
                  color: AppColors.textHiAlt,
                ),
              ),
            ],
          ),
        ),
        // Bare hamburger - floats directly on the UI, no container.
        GestureDetector(
          onTap: onMenu,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(8), // ≥44dp hit target
            child: Icon(
              Icons.menu,
              size: 30,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}
