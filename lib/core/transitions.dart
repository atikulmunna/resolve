import 'package:flutter/material.dart';

/// Slide-up overlay route used by Create and Journey (Design Spec §3.3/§3.5,
/// motion `slideUp` 0.34s cubic-bezier(.2,.8,.2,1)). Presents [child]
/// full-screen over Home; popping slides it back down.
class SlideUpRoute<T> extends PageRouteBuilder<T> {
  SlideUpRoute({required Widget child})
      : super(
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 340),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, _, _) => child,
          transitionsBuilder: (_, animation, _, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.2, 0.8, 0.2, 1),
              reverseCurve: const Cubic(0.2, 0.8, 0.2, 1),
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            );
          },
        );
}
