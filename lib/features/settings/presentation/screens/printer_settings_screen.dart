import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../features/printer/data/bluetooth_printer_service.dart';

class PrinterSettingsScreen extends ConsumerWidget {
  const PrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final printerState = ref.watch(bluetoothPrinterProvider);
    final notifier = ref.read(bluetoothPrinterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Printer Bluetooth'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status printer terhubung ──
            _ConnectionCard(state: printerState, isDark: isDark, notifier: notifier),
            const SizedBox(height: AppSpacing.lg),

            // ── Ukuran kertas ──
            Text('UKURAN KERTAS',
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
                )),
            const SizedBox(height: AppSpacing.sm),
            _PaperSizeSelector(state: printerState, isDark: isDark, notifier: notifier),
            const SizedBox(height: AppSpacing.lg),

            // ── Info kompatibilitas ──
            _CompatibilityCard(isDark: isDark),
            const SizedBox(height: AppSpacing.lg),

            // ── Scan ──
            AppButton(
              label: printerState.isScanning
                  ? 'Mencari Printer Bluetooth...'
                  : 'Scan Printer Bluetooth',
              onPressed: printerState.isScanning
                  ? null
                  : () => notifier.scan(),
              isLoading: printerState.isScanning,
              prefixIcon: Icons.bluetooth_searching_outlined,
              variant: AppButtonVariant.ghost,
            ),

            // ── Daftar perangkat ditemukan ──
            if (printerState.scannedDevices.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('PERANGKAT DITEMUKAN',
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
                  )),
              const SizedBox(height: AppSpacing.sm),
              ...printerState.scannedDevices.map((device) {
                final isConnected =
                    printerState.connectedDevice?.address == device.address &&
                        printerState.isConnected;
                final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
                final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(
                      color: isConnected ? AppColors.success : border,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.print_outlined,
                      color: isConnected
                          ? AppColors.success
                          : (isDark ? AppColors.darkTextSecondary : AppColors.ashGray),
                    ),
                    title: Text(
                      device.name ?? 'Unknown Printer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    subtitle: Text(device.address ?? '', style: AppTextStyles.caption),
                    trailing: isConnected
                        ? TextButton(
                            onPressed: () => notifier.disconnect(),
                            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                            child: const Text('Putus'),
                          )
                        : TextButton(
                            onPressed: () => notifier.connect(device),
                            child: const Text('Hubungkan'),
                          ),
                  ),
                );
              }),
            ],

            // ── Test & cetak ──
            if (printerState.isConnected) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Test Cetak',
                onPressed: () => notifier.printTest(),
                variant: AppButtonVariant.secondary,
                prefixIcon: Icons.receipt_long_outlined,
              ),
            ],

            if (printerState.errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        printerState.errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final BluetoothPrinterState state;
  final bool isDark;
  final BluetoothPrinterNotifier notifier;

  const _ConnectionCard({
    required this.state,
    required this.isDark,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final isConnected = state.isConnected;
    final isConnecting = state.status == PrinterStatus.connecting;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isConnected ? AppColors.success.withValues(alpha: 0.4) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.successLight
                  : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnected ? Icons.print : Icons.print_disabled_outlined,
              color: isConnected ? AppColors.success : AppColors.ashGray,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected
                      ? (state.connectedDevice?.name ?? 'Printer Terhubung')
                      : isConnecting
                          ? 'Menghubungkan...'
                          : 'Belum ada printer',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                ),
                if (isConnected)
                  Text(
                    '${state.connectedDevice?.address ?? ''} · ${state.paperSize}',
                    style: AppTextStyles.caption,
                  )
                else
                  Text(
                    'Scan untuk mencari printer',
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          if (isConnected)
            StatusBadge(label: 'Terhubung', type: BadgeType.success),
        ],
      ),
    );
  }
}

class _PaperSizeSelector extends StatelessWidget {
  final BluetoothPrinterState state;
  final bool isDark;
  final BluetoothPrinterNotifier notifier;

  const _PaperSizeSelector({
    required this.state,
    required this.isDark,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.champagneGold : AppColors.charcoal;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Row(
      children: ['58mm', '80mm'].asMap().entries.map((e) {
        final size = e.value;
        final isSelected = state.paperSize == size;
        return Expanded(
          child: GestureDetector(
            onTap: () => notifier.setPaperSize(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: e.key == 0 ? AppSpacing.sm : 0),
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.08)
                    : surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? accent : border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    size,
                    style: AppTextStyles.h3.copyWith(
                      color: isSelected
                          ? accent
                          : (isDark ? AppColors.darkTextSecondary : AppColors.ashGray),
                    ),
                  ),
                  Text(
                    size == '58mm' ? '32 karakter' : '48 karakter',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CompatibilityCard extends StatelessWidget {
  final bool isDark;
  const _CompatibilityCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final brands = [
      'Epson TM-T20/T82/T88',
      'Xprinter XP-58/XP-80/XP-N160',
      'RONGTA RP500/RP58/RP80',
      'MUNBYN ITPP941/ITPP047',
      'iDPRT SP-L / SP-X',
      'POS-5890 / POS-8360',
      'Cashino PTP-II / PTP-III',
      'Dan semua printer ESC/POS Bluetooth',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Printer yang Didukung',
                style: AppTextStyles.buttonSmall.copyWith(color: AppColors.info),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...brands.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('• $b',
                style: AppTextStyles.caption.copyWith(color: AppColors.info)),
          )),
        ],
      ),
    );
  }
}
