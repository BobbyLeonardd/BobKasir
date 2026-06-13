import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

/// Frosted glass offline banner — shown at top when network is unavailable.
/// Designed per design.md §7 — no red color, no panic, just informational.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            width: double.infinity,
            color: isDark
                ? AppColors.darkGlass
                : AppColors.lightGlass,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageH,
              vertical: AppSpacing.xs + 2,
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Mode Resiliensi: Transaksi tetap berjalan lokal.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.info,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
