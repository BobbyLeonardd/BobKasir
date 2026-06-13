import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  final _nameController = TextEditingController(text: 'BobKasir Cafe');
  final _addressController = TextEditingController(text: 'Jl. Contoh No. 1, Surabaya');
  final _phoneController = TextEditingController(text: '+62 812 3456 7890');
  final _footerController = TextEditingController(text: 'Terima kasih sudah berkunjung!');

  bool _showTableNumber = true;
  bool _showCustomerName = true;
  bool _showCashierName = true;
  bool _showTax = true;
  bool _showServiceCharge = true;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Template Struk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: 'Nama Kedai',
              controller: _nameController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Alamat',
              controller: _addressController,
              textInputAction: TextInputAction.next,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Nomor HP',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Footer Struk',
              hint: 'Pesan di bagian bawah struk',
              controller: _footerController,
              maxLines: 2,
            ),

            const SizedBox(height: AppSpacing.lg),
            Text(
              'TAMPILKAN DI STRUK',
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  _ToggleTile(
                    title: 'Nomor Meja',
                    value: _showTableNumber,
                    onChanged: (v) => setState(() => _showTableNumber = v),
                    isDark: isDark,
                    showDivider: true,
                    border: border,
                  ),
                  _ToggleTile(
                    title: 'Nama Customer',
                    value: _showCustomerName,
                    onChanged: (v) => setState(() => _showCustomerName = v),
                    isDark: isDark,
                    showDivider: true,
                    border: border,
                  ),
                  _ToggleTile(
                    title: 'Nama Kasir',
                    value: _showCashierName,
                    onChanged: (v) => setState(() => _showCashierName = v),
                    isDark: isDark,
                    showDivider: true,
                    border: border,
                  ),
                  _ToggleTile(
                    title: 'Pajak',
                    value: _showTax,
                    onChanged: (v) => setState(() => _showTax = v),
                    isDark: isDark,
                    showDivider: true,
                    border: border,
                  ),
                  _ToggleTile(
                    title: 'Service Charge',
                    value: _showServiceCharge,
                    onChanged: (v) => setState(() => _showServiceCharge = v),
                    isDark: isDark,
                    showDivider: false,
                    border: border,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Simpan Pengaturan',
              onPressed: () async {
                setState(() => _isSaving = true);
                await Future.delayed(const Duration(milliseconds: 800));
                if (!mounted) return;
                setState(() => _isSaving = false);
                // ignore: use_build_context_synchronously
                context.pop();
              },
              isLoading: _isSaving,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final bool showDivider;
  final Color border;

  const _ToggleTile({
    required this.title,
    required this.value,
    required this.onChanged,
    required this.isDark,
    required this.showDivider,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 14,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: isDark ? AppColors.champagneGold : AppColors.charcoal,
        ),
        if (showDivider) Divider(height: 1, color: border),
      ],
    );
  }
}
