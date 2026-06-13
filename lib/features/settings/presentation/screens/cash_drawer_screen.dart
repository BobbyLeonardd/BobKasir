import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/storage/app_storage.dart';
import '../../../../core/widgets/app_button.dart';

class CashDrawerScreen extends StatefulWidget {
  const CashDrawerScreen({super.key});

  @override
  State<CashDrawerScreen> createState() => _CashDrawerScreenState();
}

class _CashDrawerScreenState extends State<CashDrawerScreen> {
  late String _mode;

  @override
  void initState() {
    super.initState();
    _mode = AppStorage.instance.cashDrawerMode;
  }

  Future<void> _saveMode(String mode) async {
    await AppStorage.instance.saveCashDrawerMode(mode);
    setState(() => _mode = mode);
  }

  void _testOpen() {
    // TODO: Send ESC/POS open drawer command via printer service
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Perintah buka cash drawer dikirim ke printer'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent =
        isDark ? AppColors.champagneGold : AppColors.charcoal;

    final modes = [
      _ModeItem('off', 'Nonaktif',
          'Cash drawer dimatikan', Icons.block_outlined),
      _ModeItem('auto_cash', 'Auto saat Pembayaran Cash',
          'Terbuka otomatis setelah transaksi cash',
          Icons.payments_outlined),
      _ModeItem('manual', 'Manual Saja',
          'Hanya terbuka lewat tombol manual',
          Icons.touch_app_outlined),
      _ModeItem('always_ask', 'Selalu Tanya',
          'Sistem bertanya setelah checkout',
          Icons.help_outline_outlined),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Cash Drawer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MODE CASH DRAWER',
              style: AppTextStyles.label.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.ashGray,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: border),
              ),
              child: Column(
                children: modes.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  final isSelected = _mode == item.value;
                  return Column(
                    children: [
                      ListTile(
                        onTap: () => _saveMode(item.value),
                        leading: Icon(
                          item.icon,
                          color: isSelected
                              ? accent
                              : (isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.ashGray),
                          size: 22,
                        ),
                        title: Text(
                          item.label,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: isSelected
                                ? accent
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        subtitle: Text(item.desc,
                            style: AppTextStyles.caption),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: accent, size: 20)
                            : null,
                      ),
                      if (i < modes.length - 1)
                        Divider(height: 1, color: border),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Test button (only if not off)
            if (_mode != 'off') ...[
              Text(
                'TEST',
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.ashGray,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Buka Cash Drawer (Test)',
                onPressed: _testOpen,
                variant: AppButtonVariant.secondary,
                prefixIcon: Icons.open_in_full_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Pastikan printer Bluetooth sudah terhubung sebelum test.',
                style: AppTextStyles.caption,
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Cash drawer terhubung ke printer via port RJ11/RJ12. '
                      'Aplikasi mengirim perintah ESC/POS melalui printer Bluetooth.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeItem {
  final String value;
  final String label;
  final String desc;
  final IconData icon;

  const _ModeItem(this.value, this.label, this.desc, this.icon);
}
