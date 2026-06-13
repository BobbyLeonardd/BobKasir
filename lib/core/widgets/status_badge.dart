import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';

enum BadgeType { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      BadgeType.success => (AppColors.successLight, AppColors.success),
      BadgeType.warning => (AppColors.warningLight, AppColors.warning),
      BadgeType.danger => (AppColors.dangerLight, AppColors.danger),
      BadgeType.info => (AppColors.infoLight, AppColors.info),
      BadgeType.neutral => (
          AppColors.lightBorder,
          AppColors.lightTextSecondary,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(color: fg),
      ),
    );
  }
}
