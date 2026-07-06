import 'package:home_widget/home_widget.dart';

import '../models/habit.dart';

/// Bridges Resolve to the native Android home-screen widget (Tier-1).
///
/// A widget can't run a Flutter timer, so we push the raw `startedAt` (epoch
/// millis, as a String to avoid int/long ambiguity across the channel) plus the
/// habit name. The Kotlin `ResolveWidgetProvider` computes the day count and the
/// milestone ring itself on each update, preserving the app's
/// "streak = now() - startedAt" rule even while the app is closed.
class WidgetBridge {
  WidgetBridge._();

  static const String _provider = 'ResolveWidgetProvider';
  static const String _keyStartedAt = 'startedAtMs';
  static const String _keyName = 'habitName';

  /// Push the current habit to the widget and trigger a redraw. Best-effort:
  /// silently no-ops if there's no widget or the platform lacks support.
  static Future<void> save(Habit habit) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        _keyStartedAt,
        habit.startedAt.toUtc().millisecondsSinceEpoch.toString(),
      );
      await HomeWidget.saveWidgetData<String>(_keyName, habit.name);
      await HomeWidget.updateWidget(androidName: _provider);
    } catch (_) {
      // No widget placed, or a non-Android platform: nothing to update.
    }
  }
}
