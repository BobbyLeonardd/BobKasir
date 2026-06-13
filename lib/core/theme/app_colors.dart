import 'package:flutter/material.dart';

/// BobKasir Design System — Executive Palette
/// Dual Theme: Ivory Elegance (light) & Midnight Obsidian (dark)
abstract class AppColors {
  // ──────────────────────────────────────────
  // LIGHT THEME — Ivory Elegance
  // ──────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFBFBFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFEBEBEB);

  static const Color lightTextPrimary = Color(0xFF1A1B1E);
  static const Color lightTextSecondary = Color(0xFF868E96);
  static const Color lightTextTertiary = Color(0xFFC1C3C8);

  static const Color lightAccent = Color(0xFFB89047); // Brushed Gold

  // ──────────────────────────────────────────
  // DARK THEME — Midnight Obsidian
  // ──────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0B0E);
  static const Color darkSurface = Color(0xFF15161A);
  static const Color darkBorder = Color(0xFF2A2B30);

  static const Color darkTextPrimary = Color(0xFFEAEAEA);
  static const Color darkTextSecondary = Color(0xFF8A8D93);
  static const Color darkTextTertiary = Color(0xFF4A4D53);

  static const Color darkAccent = Color(0xFFD4AF37); // Champagne Gold

  // ──────────────────────────────────────────
  // SEMANTIC — same across themes (adjusted lightness)
  // ──────────────────────────────────────────
  static const Color success = Color(0xFF2E7D32);       // Forest Green
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color danger = Color(0xFFC62828);        // Crimson Red
  static const Color dangerLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFD89A29);       // Warm Amber
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color info = Color(0xFF455A64);          // Deep Slate
  static const Color infoLight = Color(0xFFECEFF1);

  // ──────────────────────────────────────────
  // GLASS / BLUR SURFACE
  // ──────────────────────────────────────────
  static const Color lightGlass = Color(0xCCFFFFFF);   // rgba(255,255,255,0.8)
  static const Color darkGlass = Color(0xB214151A);    // rgba(20,21,26,0.7)

  // ──────────────────────────────────────────
  // NEUTRAL UTILITY
  // ──────────────────────────────────────────
  static const Color charcoal = Color(0xFF1A1B1E);
  static const Color ashGray = Color(0xFF868E96);
  static const Color platinum = Color(0xFFEBEBEB);
  static const Color obsidian = Color(0xFF0A0B0E);
  static const Color brushedGold = Color(0xFFB89047);
  static const Color champagneGold = Color(0xFFD4AF37);
}
