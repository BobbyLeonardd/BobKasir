import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/helpers/date_helper.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/subscription_provider.dart';
import 'subscription_webview_screen.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _processing = false;

  Future<void> _checkout(String slug) async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final checkout = await SubscriptionApiService.checkout(slug);
      if (!mounted) return;

      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => SubscriptionWebViewScreen(checkout: checkout),
        ),
      );
      if (!mounted) return;

      // The subscription is activated server-side by the Midtrans webhook
      // (idempotent). Re-fetch so the UI reflects the latest state.
      ref.invalidate(subscriptionStatusProvider);
      ref.invalidate(subscriptionHistoryProvider);

      final msg = switch (result) {
        'success' => 'Pembayaran berhasil. Langganan sedang diaktifkan.',
        'pending' => 'Pembayaran tertunda. Menunggu konfirmasi.',
        'error' => 'Pembayaran gagal. Silakan coba lagi.',
        _ => 'Pembayaran dibatalkan.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    } on DioException catch (e) {
      if (!mounted) return;
      final data = e.response?.data;
      final m = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Tidak dapat terhubung ke server';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Checkout gagal: $m')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Checkout gagal: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusAsync = ref.watch(subscriptionStatusProvider);
    final historyAsync = ref.watch(subscriptionHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Langganan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Column(
          children: [
            _StatusCard(
              isDark: isDark,
              status: statusAsync.asData?.value,
              loading: statusAsync.isLoading,
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(
              'PILIH PAKET',
              style: AppTextStyles.label.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.ashGray,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _PlanCard(
              name: 'Mingguan',
              price: AppConstants.weeklyPriceCents,
              days: AppConstants.weeklyDays,
              isDark: isDark,
              processing: _processing,
              onSelect: () => _checkout('weekly'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PlanCard(
              name: 'Bulanan',
              price: AppConstants.monthlyPriceCents,
              days: AppConstants.monthlyDays,
              isDark: isDark,
              isRecommended: true,
              processing: _processing,
              onSelect: () => _checkout('monthly'),
            ),

            const SizedBox(height: AppSpacing.xl),
            _FeaturesList(isDark: isDark),
            const SizedBox(height: AppSpacing.xl),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'RIWAYAT PEMBAYARAN',
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.ashGray,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _PaymentHistory(
              isDark: isDark,
              payments: historyAsync.asData?.value ?? const [],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isDark;
  final SubscriptionStatus? status;
  final bool loading;
  const _StatusCard({
    required this.isDark,
    required this.status,
    required this.loading,
  });

  (String, Color) _badge(String s) => switch (s) {
        'active' => ('AKTIF', AppColors.success),
        'trial' => ('TRIAL', AppColors.warning),
        'pending_payment' => ('MENUNGGU', AppColors.warning),
        'expired' => ('KEDALUWARSA', AppColors.danger),
        _ => (s.toUpperCase(), AppColors.ashGray),
      };

  @override
  Widget build(BuildContext context) {
    final s = status?.status ?? (loading ? 'memuat' : 'expired');
    final (badgeLabel, badgeColor) = _badge(s);
    final expiry = status?.effectiveExpiry;

    final title = switch (s) {
      'active' => 'Langganan Aktif',
      'trial' => 'Trial Aktif',
      'expired' => 'Langganan Berakhir',
      'pending_payment' => 'Menunggu Pembayaran',
      _ => loading ? 'Memuat...' : 'Tidak Aktif',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.champagneGold.withValues(alpha: 0.12),
                  AppColors.darkSurface,
                ]
              : [
                  AppColors.brushedGold.withValues(alpha: 0.06),
                  AppColors.lightSurface,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? AppColors.champagneGold.withValues(alpha: 0.3)
              : AppColors.brushedGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Langganan',
                style: AppTextStyles.label.copyWith(
                  color: isDark
                      ? AppColors.champagneGold
                      : AppColors.brushedGold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  badgeLabel,
                  style: AppTextStyles.labelSmall.copyWith(color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.h2.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          if (expiry != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Berakhir: ${DateHelper.formatDate(expiry)}',
              style: AppTextStyles.bodySmall.copyWith(color: badgeColor),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            s == 'expired'
                ? 'Fitur premium terkunci. Berlangganan untuk membukanya kembali.'
                : 'Semua fitur premium terbuka. Perpanjang untuk melanjutkan.',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final int price;
  final int days;
  final bool isDark;
  final bool isRecommended;
  final bool processing;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.days,
    required this.isDark,
    this.isRecommended = false,
    required this.processing,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isRecommended
        ? (isDark ? AppColors.champagneGold : AppColors.brushedGold)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: borderColor,
          width: isRecommended ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.h3.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (isRecommended) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.champagneGold.withValues(alpha: 0.1)
                              : AppColors.brushedGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'TERBAIK',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.champagneGold
                                : AppColors.brushedGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text('$days hari masa aktif', style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  CurrencyHelper.format(price),
                  style: AppTextStyles.priceTotal.copyWith(
                    color: isDark
                        ? AppColors.champagneGold
                        : AppColors.brushedGold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: AppButton(
              label: 'Pilih',
              onPressed: onSelect,
              isLoading: processing,
              isFullWidth: false,
              height: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesList extends StatelessWidget {
  final bool isDark;
  const _FeaturesList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final features = [
      'Kasir & checkout tidak terbatas',
      'Dashboard & laporan lengkap',
      'Export laporan PDF/Excel',
      'Kelola produk & kategori',
      'Shift kasir & tutup kas',
      'Printer Bluetooth & cash drawer',
      'Multi device',
      'Offline mode & sinkronisasi otomatis',
      'Kelola tim (Owner, Manager, Karyawan)',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FITUR PREMIUM',
            style: AppTextStyles.label.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        f,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  final bool isDark;
  final List<Map<String, dynamic>> payments;
  const _PaymentHistory({required this.isDark, required this.payments});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: payments.isEmpty
          ? Text('Belum ada pembayaran.', style: AppTextStyles.bodySmall)
          : Column(
              children: payments.map((p) {
                final status = (p['status'] ?? '').toString();
                final paid = status == 'settlement' || status == 'capture';
                final created = DateTime.tryParse(p['created_at']?.toString() ?? '');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p['plan'] ?? '-'} · ${CurrencyHelper.format((p['amount'] as num?)?.toInt() ?? 0)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          if (created != null)
                            Text(DateHelper.formatDate(created),
                                style: AppTextStyles.caption),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (paid ? AppColors.success : AppColors.warning)
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          paid ? 'Berhasil' : status,
                          style: AppTextStyles.labelSmall.copyWith(
                            color:
                                paid ? AppColors.success : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
