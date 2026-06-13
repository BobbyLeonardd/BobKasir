import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';

/// Pajak & Service Charge settings screen
class TaxServiceScreen extends StatefulWidget {
  const TaxServiceScreen({super.key});

  @override
  State<TaxServiceScreen> createState() => _TaxServiceScreenState();
}

class _TaxServiceScreenState extends State<TaxServiceScreen> {
  // Pajak
  bool _taxEnabled = false;

  // Service Charge
  bool _serviceEnabled = false;

  bool _isSaving = false;

  final _taxRateCtrl = TextEditingController(text: '10');
  final _taxNameCtrl = TextEditingController(text: 'PPN');
  final _serviceRateCtrl = TextEditingController(text: '5');
  final _serviceNameCtrl =
      TextEditingController(text: 'Service Charge');

  @override
  void dispose() {
    _taxRateCtrl.dispose();
    _taxNameCtrl.dispose();
    _serviceRateCtrl.dispose();
    _serviceNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    // TODO: Save to local_settings + sync to API
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pengaturan pajak & service charge disimpan')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Pajak & Service Charge'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pajak section
            Text(
              'PAJAK',
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
                children: [
                  SwitchListTile(
                    title: Text('Aktifkan Pajak',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 14,
                        )),
                    value: _taxEnabled,
                    onChanged: (v) => setState(() => _taxEnabled = v),
                    activeThumbColor: isDark
                        ? AppColors.champagneGold
                        : AppColors.charcoal,
                  ),
                  if (_taxEnabled) ...[
                    Divider(height: 1, color: border),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _taxNameCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Nama Pajak'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _taxRateCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'))
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Persentase (%)',
                              hintText: '10',
                              suffixText: '%',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Service Charge section
            Text(
              'SERVICE CHARGE',
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
                children: [
                  SwitchListTile(
                    title: Text('Aktifkan Service Charge',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontSize: 14,
                        )),
                    value: _serviceEnabled,
                    onChanged: (v) =>
                        setState(() => _serviceEnabled = v),
                    activeThumbColor: isDark
                        ? AppColors.champagneGold
                        : AppColors.charcoal,
                  ),
                  if (_serviceEnabled) ...[
                    Divider(height: 1, color: border),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _serviceNameCtrl,
                            decoration: const InputDecoration(
                                labelText: 'Nama'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _serviceRateCtrl,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}'))
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Persentase (%)',
                              hintText: '5',
                              suffixText: '%',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Simpan',
              onPressed: _save,
              isLoading: _isSaving,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
