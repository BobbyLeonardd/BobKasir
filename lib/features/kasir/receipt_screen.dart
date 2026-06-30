import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/app_button.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Struk'), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 40, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text('Pembayaran Berhasil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.success)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.surface3),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Column(
                children: [
                  _ReceiptRow(label: 'Kedai Kopi Bobby', isHeader: true),
                  SizedBox(height: 4),
                  _ReceiptRow(label: 'Jl. Contoh No. 1, Jakarta'),
                  Divider(height: 20),
                  _ReceiptRow(label: 'Americano × 1', value: 'Rp 25.000'),
                  _ReceiptRow(label: 'Matcha Latte × 2', value: 'Rp 50.000'),
                  Divider(height: 20),
                  _ReceiptRow(label: 'Total', value: 'Rp 75.000', bold: true),
                  _ReceiptRow(label: 'Bayar (Tunai)', value: 'Rp 100.000'),
                  _ReceiptRow(label: 'Kembalian', value: 'Rp 25.000', color: AppColors.success),
                  Divider(height: 20),
                  _ReceiptRow(label: 'Kasir: Budi Santoso'),
                  _ReceiptRow(label: '28 Jun 2026  14:23'),
                  _ReceiptRow(label: '#0043'),
                  Divider(height: 20),
                  _ReceiptRow(label: 'Terima kasih sudah berkunjung!'),
                  _ReceiptRow(label: 'by StarCyberCompany', isCaption: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            AppButton(label: 'Cetak Struk Customer', onPressed: () {}),
            const SizedBox(height: AppSpacing.s3),
            AppButton(label: 'Cetak Struk Dapur', variant: AppButtonVariant.secondary, onPressed: () {}),
            const SizedBox(height: AppSpacing.s3),
            AppButton(label: 'Transaksi Baru', variant: AppButtonVariant.ghost, onPressed: () => context.go('/kasir')),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool bold;
  final bool isHeader;
  final bool isCaption;
  final Color? color;

  const _ReceiptRow({required this.label, this.value, this.bold = false, this.isHeader = false, this.isCaption = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = isHeader
        ? const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)
        : isCaption
            ? const TextStyle(fontSize: 11, color: AppColors.onSurface3)
            : TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: 13, color: color ?? AppColors.onSurface);

    if (value == null) {
      return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Center(child: Text(label, style: style, textAlign: TextAlign.center)));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: style),
        Text(value!, style: style),
      ]),
    );
  }
}
