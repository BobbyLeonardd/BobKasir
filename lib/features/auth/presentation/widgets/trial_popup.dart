import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/router/app_router.dart';

/// Shows the trial welcome popup.
/// Marks popup as shown so it only appears once.
Future<void> showTrialPopup(BuildContext context) async {
  await AppStorage.instance.markTrialPopupShown();
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _TrialPopupDialog(),
  );
}

class _TrialPopupDialog extends StatelessWidget {
  const _TrialPopupDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent =
        isDark ? AppColors.champagneGold : AppColors.brushedGold;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(
                  color: accent.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gold accent bar
                  Container(
                    width: 40,
                    height: 3,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.card_membership_outlined,
                      color: accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Selamat Datang di BobKasir!',
                    style: AppTextStyles.h2.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      'TRIAL GRATIS ${AppConstants.trialDays} HARI',
                      style: AppTextStyles.label.copyWith(color: accent),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Feature list
                  _FeatureItem(
                    icon: Icons.check_circle_outline,
                    text:
                        'Semua fitur premium terbuka selama trial',
                    accent: accent,
                  ),
                  _FeatureItem(
                    icon: Icons.check_circle_outline,
                    text: 'Kasir, laporan, stok, shift & lebih',
                    accent: accent,
                  ),
                  _FeatureItem(
                    icon: Icons.check_circle_outline,
                    text:
                        'Transaksi dasar tetap bisa digunakan setelah trial habis',
                    accent: accent,
                  ),
                  _FeatureItem(
                    icon: Icons.check_circle_outline,
                    text:
                        'Paket Mingguan Rp30.000 / Bulanan Rp100.000',
                    accent: accent,
                  ),

                  Divider(
                    height: AppSpacing.xl,
                    color: border,
                  ),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Lanjutkan Trial',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(AppRoutes.subscription);
                      },
                      child: Text(
                        'Lihat Paket Langganan',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
