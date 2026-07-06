import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Mood check-in options for a relapse (SRS §4 / Design Spec §1.1).
/// Ordered Crushed → Strong as they appear in the relapse sheet.
enum Mood {
  crushed('Crushed', AppColors.danger400),
  tempted('Tempted', AppColors.warn),
  okay('Okay', AppColors.neutralMood),
  steady('Steady', AppColors.emerald400),
  strong('Strong', AppColors.emerald500);

  const Mood(this.label, this.color);

  /// Display label, e.g. "Crushed".
  final String label;

  /// Color-coded chip / dot color.
  final Color color;

  /// Stable key for persistence (enum name).
  String get key => name;

  static Mood fromKey(String key) =>
      Mood.values.firstWhere((m) => m.name == key, orElse: () => Mood.okay);
}
