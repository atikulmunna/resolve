import 'package:flutter/material.dart';

import 'data/habit_store.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'theme/app_theme.dart';

/// Navigator for the whole app, so out-of-tree events (the home-screen widget's
/// PANIC deep link) can push routes without a BuildContext.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Root of the Resolve app. Offline-first, no backend, single dark theme.
/// The [store] is loaded from persistence in `main` before first paint.
class ResolveApp extends StatefulWidget {
  const ResolveApp({super.key, required this.store});

  final HabitStore store;

  @override
  State<ResolveApp> createState() => _ResolveAppState();
}

class _ResolveAppState extends State<ResolveApp> {
  @override
  void dispose() {
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resolve',
      debugShowCheckedModeBanner: false,
      navigatorKey: rootNavigatorKey,
      theme: AppTheme.dark,
      // First run shows the welcome flow; once a habit exists (created during
      // onboarding, or loaded from storage), the timer's Home is revealed.
      home: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOut,
            child: widget.store.isConfigured
                ? HomeScreen(key: const ValueKey('home'), store: widget.store)
                : OnboardingFlow(
                    key: const ValueKey('onboarding'),
                    store: widget.store,
                  ),
          );
        },
      ),
    );
  }
}
