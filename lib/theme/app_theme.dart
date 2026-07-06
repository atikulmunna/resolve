import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// The single dark theme. AMOLED-black scaffold, emerald seed.
abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: AppColors.emerald400,
        secondary: AppColors.emerald300,
        surface: AppColors.black,
        error: AppColors.danger400,
      ),
      canvasColor: AppColors.black,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      textTheme: base.textTheme.apply(
        fontFamily: AppType.grotesk,
        bodyColor: AppColors.textHi,
        displayColor: AppColors.textHi,
      ),
    );
  }
}
