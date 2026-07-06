import 'package:flutter/material.dart';

/// Design tokens - colors. Mirrors Design Spec §1.1.
/// AMOLED discipline: backgrounds are true black; color is spent only on
/// the emerald accent and the glass.
abstract final class AppColors {
  // Canvas
  static const Color black = Color(0xFF000000); // bg/black - AMOLED true black
  static const Color near = Color(0xFF050706); // bg/near - outer page

  // Emerald ramp
  static const Color emerald300 = Color(0xFF6EE7B7); // ring start, highlights
  static const Color emerald400 = Color(0xFF34D399); // PRIMARY accent
  static const Color emerald500 = Color(0xFF10B981); // glow, mid gradient
  static const Color emerald600 = Color(0xFF059669); // CTA / ring end
  static const Color teal400 = Color(0xFF2DD4BF); // ring mid stop / pulse fade
  static const Color mintNode = Color(0xFFA7F3D0); // orbiting ring node

  // Cool celebration accent - spent ONLY on milestone / celebration moments.
  static const Color aqua400 = Color(0xFF22D3EE); // celebration accent
  static const Color cyan500 = Color(0xFF06B6D4); // celebration deep

  // Text
  static const Color textHi = Color(0xFFEAFFF6); // primary numerals / headings
  static const Color textHiAlt = Color(0xFFF2FBF7);
  static const Color textMint = Color(0xB8A0F0D2); // ~rgba(160,240,210,.72)
  static const Color textMute = Color(0x80FFFFFF); // rgba(255,255,255,.5)
  static const Color textFaint = Color(0x59FFFFFF); // ~rgba(255,255,255,.35)

  // Danger
  static const Color danger300 = Color(0xFFFCA5A5); // relapse button text
  // Coral-leaning red: separates from emerald on luminance, not just hue, so
  // relapse/alive stays legible under red-green colorblindness.
  static const Color danger400 = Color(0xFFFB7185); // "Crushed" / relapse value
  static const Color relapseScar = Color(0xFFEF4444); // pulse scar dot

  // Warn / neutral moods
  static const Color warn = Color(0xFFFBBF24); // "Tempted"
  static const Color neutralMood = Color(0xFF93A29B); // "Okay"

  // Surfaces & hairlines
  static const Color cardFill = Color(0x08FFFFFF); // rgba(255,255,255,.03)
  static const Color hairline = Color(0x12FFFFFF); // ~rgba(255,255,255,.07)
  static const Color hairlineSoft = Color(0x0FFFFFFF); // ~.06

  // Home ambient gradient (radial, top-center)
  static const List<Color> ambient = [
    Color(0xFF0D221B),
    Color(0xFF060F0C),
    Color(0xFF000000),
  ];
}
