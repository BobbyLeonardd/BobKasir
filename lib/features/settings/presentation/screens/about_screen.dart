import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Tentang BobKasir'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          children: [
            // Logo
            const SizedBox(height: AppSpacing.lg),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Text(
                  'B',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 80,
                    fontWeight: FontWeight.w300,
                    color: isDark ? AppColors.champagneGold : AppColors.charcoal,
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: 16,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.champagneGold
                          : AppColors.brushedGold,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(AppConstants.appName, style: AppTextStyles.h1),
            Text(
              'v${AppConstants.appVersion}',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Info list
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  _InfoTile(
                    label: 'Dibuat oleh',
                    value: AppConstants.companyName,
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: border),
                  _InfoTile(
                    label: 'Tahun Rilis',
                    value: '${AppConstants.releaseYear}',
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: border),
                  _InfoTile(
                    label: 'Versi',
                    value: AppConstants.appVersion,
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: border),
                  _InfoTile(
                    label: 'Platform',
                    value: 'Android (Flutter)',
                    isDark: isDark,
                  ),
                  Divider(height: 1, color: border),
                  _InfoTile(
                    label: 'Support',
                    value: 'support@bobkasir.id',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const Spacer(),
            Text(
              'Created by ${AppConstants.companyName}'.toUpperCase(),
              style: AppTextStyles.caption.copyWith(letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoTile({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
