import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/subscription_repository.dart';
import '../../core/services/api_client.dart';
import '../../widgets/app_button.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String? _selectedPackage;
  bool _loading = false;

  Future<void> _checkout() async {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih paket terlebih dahulu')));
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ref.read(subscriptionRepositoryProvider).checkout(_selectedPackage!);
      final redirectUrl = data['data']?['redirect_url'] as String?;
      if (mounted && redirectUrl != null) {
        final uri = Uri.parse(redirectUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak bisa membuka: $redirectUrl')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manualPayment() async {
    if (_selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih paket terlebih dahulu')));
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await ref.read(subscriptionRepositoryProvider).manualPayment(_selectedPackage!);
      if (mounted) {
        final info = data['data'];
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Transfer Manual'),
            content: Text(info?.toString() ?? 'Ikuti instruksi yang dikirim ke email Anda.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sub = ref.watch(subscriptionProvider);
    final fmt = DateFormat('dd MMM yyyy');
    final isExpired = sub.status == SubscriptionStatus.expired;

    return Scaffold(
      appBar: AppBar(title: const Text('Langganan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isExpired)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                child: const Row(children: [
                  Icon(Icons.warning_amber, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Langganan Anda telah berakhir. Fitur terbatas.', style: TextStyle(color: AppColors.error, fontSize: 13))),
                ]),
              ),
            const SizedBox(height: AppSpacing.s4),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: AppColors.surface3)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sub.status == SubscriptionStatus.trial ? AppColors.infoBg : sub.status == SubscriptionStatus.active ? AppColors.successBg : AppColors.errorBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      sub.status == SubscriptionStatus.trial ? 'TRIAL' : sub.status == SubscriptionStatus.active ? 'AKTIF' : 'EXPIRED',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: sub.status == SubscriptionStatus.trial ? AppColors.info : sub.status == SubscriptionStatus.active ? AppColors.success : AppColors.error),
                    ),
                  ),
                  const Spacer(),
                  if (sub.package != null) Text(sub.package!, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                if (sub.expiresAt != null) ...[
                  const SizedBox(height: 8),
                  Text('Berakhir: ${fmt.format(sub.expiresAt!)}', style: const TextStyle(color: AppColors.onSurface2, fontSize: 13)),
                ],
              ]),
            ),
            const SizedBox(height: AppSpacing.s6),
            const Text('Pilih Paket', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: AppSpacing.s4),
            _PackageCard(
              title: 'Mingguan',
              price: 'Rp 25.000 / minggu',
              desc: '7 hari akses penuh',
              selected: _selectedPackage == 'weekly',
              onSelect: () => setState(() => _selectedPackage = 'weekly'),
            ),
            const SizedBox(height: AppSpacing.s3),
            _PackageCard(
              title: 'Bulanan',
              price: 'Rp 79.000 / bulan',
              desc: '30 hari akses penuh',
              isRecommended: true,
              selected: _selectedPackage == 'monthly',
              onSelect: () => setState(() => _selectedPackage = 'monthly'),
            ),
            const SizedBox(height: AppSpacing.s6),
            AppButton(
              label: _loading ? 'Memproses...' : 'Bayar via Midtrans',
              onPressed: _loading ? null : _checkout,
            ),
            const SizedBox(height: AppSpacing.s3),
            AppButton(
              label: _loading ? 'Memproses...' : 'Konfirmasi Manual',
              variant: AppButtonVariant.secondary,
              onPressed: _loading ? null : _manualPayment,
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String title;
  final String price;
  final String desc;
  final bool isRecommended;
  final bool selected;
  final VoidCallback onSelect;

  const _PackageCard({
    required this.title,
    required this.price,
    required this.desc,
    this.isRecommended = false,
    this.selected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = selected || isRecommended;
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primaryLight : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : isRecommended ? AppColors.primary : AppColors.surface3,
            width: highlight ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              if (isRecommended) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
                  child: const Text('Hemat', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(color: AppColors.onSurface2, fontSize: 13)),
          ])),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
      ),
    );
  }
}
