import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/shift_provider.dart';

class OpenShiftScreen extends ConsumerStatefulWidget {
  const OpenShiftScreen({super.key});

  @override
  ConsumerState<OpenShiftScreen> createState() =>
      _OpenShiftScreenState();
}

class _OpenShiftScreenState extends ConsumerState<OpenShiftScreen> {
  final _cashController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cashController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(shiftProvider.notifier).openShift(
            openingCash:
                CurrencyHelper.parse(_cashController.text),
            note: _noteController.text.isEmpty
                ? null
                : _noteController.text,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal buka shift: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Buka Shift'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modal Awal Kas',
                style: AppTextStyles.h3.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                )),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Masukkan jumlah uang di laci kas saat ini',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Modal Awal',
              hint: '0',
              controller: _cashController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Catatan (Opsional)',
              controller: _noteController,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Buka Shift Sekarang',
              onPressed: _open,
              isLoading: _isLoading,
              prefixIcon: Icons.lock_open_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
