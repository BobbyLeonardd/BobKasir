import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/app_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.store, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 24),
              const Text('Mulai coba BobKasir\nselama 7 hari gratis', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3)),
              const SizedBox(height: 12),
              const Text('Akses semua fitur tanpa biaya. Setelah trial, pilih paket yang cocok untuk kedai Anda.', style: TextStyle(color: AppColors.onSurface2, fontSize: 15, height: 1.5)),
              const Spacer(),
              _FeatureRow(icon: Icons.point_of_sale, text: 'Kasir cepat & mudah'),
              const SizedBox(height: 12),
              _FeatureRow(icon: Icons.wifi_off, text: 'Jalan offline, sinkron otomatis'),
              const SizedBox(height: 12),
              _FeatureRow(icon: Icons.bar_chart, text: 'Laporan & dashboard lengkap'),
              const SizedBox(height: 12),
              _FeatureRow(icon: Icons.print, text: 'Cetak struk Bluetooth'),
              const Spacer(),
              AppButton(label: 'Mulai Trial Gratis', onPressed: () => context.go('/kasir')),
              const SizedBox(height: AppSpacing.s4),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/settings/subscription'),
                  child: const Text('Lihat paket harga', style: TextStyle(color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
