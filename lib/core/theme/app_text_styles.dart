import 'package:flutter/material.dart';
import 'app_colors.dart';

/// BobKasir Typography — Plus Jakarta Sans
/// Tabular figures enabled for monetary values
abstract class AppTextStyles {
  static const String _fontFamily = 'PlusJakartaSans';

  // Tabular figures feature for number alignment
  static const List<FontFeature> _tabularFeatures = [
    FontFeature.tabularFigures(),
  ];

  // ──────────────────────────────────────────
  // DISPLAY — Grand Total, hero numbers
  // ──────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.0,
    fontFeatures: _tabularFeatures,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    fontFeatures: _tabularFeatures,
    color: AppColors.lightTextPrimary,
  );

  // ──────────────────────────────────────────
  // HEADINGS
  // ──────────────────────────────────────────
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.lightTextPrimary,
  );

  // ──────────────────────────────────────────
  // LABEL / CATEGORY — uppercase, wide tracking
  // ──────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
    color: AppColors.lightTextSecondary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: AppColors.lightTextSecondary,
  );

  // ──────────────────────────────────────────
  // BODY
  // ──────────────────────────────────────────
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.lightTextSecondary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.lightTextSecondary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.lightTextPrimary,
  );

  // ──────────────────────────────────────────
  // PRICE / AMOUNT — tabular figures
  // ──────────────────────────────────────────
  static const TextStyle price = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabularFeatures,
    color: AppColors.lightTextPrimary,
  );

  static const TextStyle priceTotal = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabularFeatures,
    letterSpacing: -0.3,
    color: AppColors.lightTextPrimary,
  );

  // ──────────────────────────────────────────
  // BUTTON
  // ──────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // ──────────────────────────────────────────
  // CAPTION / HINT
  // ──────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.lightTextTertiary,
  );
}
