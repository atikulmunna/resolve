import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shared chrome for the slide-up overlays (Create §3.3, Journey §3.5): the
/// overlay ambient gradient, a back button + screen title, an expanding [body],
/// and an optional pinned [footer].
class OverlayScaffold extends StatelessWidget {
  const OverlayScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.onBack,
    this.footer,
  });

  final String title;
  final Widget body;
  final VoidCallback onBack;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: DecoratedBox(
        // bg/overlay - radial(120% 80% at 50% 0%, #0c1c16, #04100b 55%, #000).
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.3,
            colors: [Color(0xFF0C1C16), Color(0xFF04100B), Color(0xFF000000)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 20, 8),
                child: Row(
                  children: [
                    // Bare back chevron - no container.
                    GestureDetector(
                      onTap: onBack,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(8), // ≥44dp hit target
                        child: Icon(
                          Icons.chevron_left,
                          size: 34,
                          color: Color(0xFFDFF7EE),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: AppType.oswaldStyle(
                        size: 20,
                        weight: 600,
                        letterSpacing: 2,
                        color: AppColors.textHiAlt,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
              ?footer,
            ],
          ),
        ),
      ),
    );
  }
}

