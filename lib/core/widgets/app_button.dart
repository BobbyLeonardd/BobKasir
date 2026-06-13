import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? prefixIcon;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.prefixIcon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: switch (variant) {
        AppButtonVariant.primary => _buildPrimary(isDark),
        AppButtonVariant.secondary => _buildSecondary(isDark),
        AppButtonVariant.ghost => _buildGhost(isDark),
        AppButtonVariant.destructive => _buildDestructive(isDark),
      },
    );
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    if (prefixIcon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(prefixIcon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.button.copyWith(color: color)),
        ],
      );
    }
    return Text(label);
  }

  Widget _buildPrimary(bool isDark) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildContent(Colors.white),
    );
  }

  Widget _buildSecondary(bool isDark) {
    final accent = isDark ? AppColors.champagneGold : AppColors.brushedGold;
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: accent, width: 1.5),
        foregroundColor: accent,
      ),
      child: _buildContent(accent),
    );
  }

  Widget _buildGhost(bool isDark) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: _buildContent(
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildDestructive(bool isDark) {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.danger,
        backgroundColor: AppColors.dangerLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: _buildContent(AppColors.danger),
    );
  }
}
