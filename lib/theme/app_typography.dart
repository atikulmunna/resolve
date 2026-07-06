import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design tokens - typography. Mirrors Design Spec §1.2.
///
/// Oswald and Space Grotesk ship as *variable* fonts (one file each). Flutter
/// does not map [FontWeight] onto a variable `wght` axis automatically, so every
/// style sets an explicit [FontVariation] alongside [fontWeight] (the latter
/// keeps semantics correct for accessibility / fallback).
abstract final class AppType {
  static const String oswald = 'Oswald';
  static const String grotesk = 'SpaceGrotesk';

  static List<FontVariation> _wght(double w) => [FontVariation('wght', w)];

  /// Oswald - condensed, uppercase, tracked. Labels, captions, headings, CTAs.
  static TextStyle oswaldStyle({
    required double size,
    double weight = 400,
    double letterSpacing = 2,
    Color color = AppColors.textHi,
    double? height,
  }) {
    return TextStyle(
      fontFamily: oswald,
      fontVariations: _wght(weight),
      fontWeight: _named(weight),
      fontSize: size,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );
  }

  /// Space Grotesk - precise, tabular feel. All numerals and body copy.
  static TextStyle groteskStyle({
    required double size,
    double weight = 400,
    double letterSpacing = 0,
    Color color = AppColors.textHi,
    double? height,
  }) {
    return TextStyle(
      fontFamily: grotesk,
      fontVariations: _wght(weight),
      fontWeight: _named(weight),
      fontSize: size,
      letterSpacing: letterSpacing,
      color: color,
      height: height,
    );
  }

  static FontWeight _named(double w) {
    if (w >= 700) return FontWeight.w700;
    if (w >= 600) return FontWeight.w600;
    if (w >= 500) return FontWeight.w500;
    return FontWeight.w400;
  }
}
