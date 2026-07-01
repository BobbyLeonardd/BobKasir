import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/revenuecat_service.dart';
import '../../widgets/app_button.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  List<Package> _packages = [];
  Package? _selectedPackage;
  bool _loading = false;
  bool _fetchingPackages = true;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    final pkgs = await RevenueCatService.getOfferings();
    if (mounted) {
      setState(() {
        _packages = pkgs;
        if (pkgs.isNotEmpty) _selectedPackage = pkgs.first;
        _fetchingPackages = false;
      });
    }
  }

  Future<void> _checkout() async {
    if (_selectedPackage == null) return;
    
    setState(() => _loading = true);
    try {
      final success = await RevenueCatService.purchasePackage(_selectedPackage!);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran berhasil!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran gagal atau dibatalkan.')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            
            if (_fetchingPackages)
               const Center(child: CircularProgressIndicator())
            else if (_packages.isEmpty)
               const Text('Belum ada paket yang tersedia', style: TextStyle(color: AppColors.onSurface2))
            else
               ..._packages.map((pkg) => Padding(
                 padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                 child: _PackageCard(
                   title: pkg.storeProduct.title,
                   price: pkg.storeProduct.priceString,
                   desc: pkg.storeProduct.description,
                   selected: _selectedPackage?.identifier == pkg.identifier,
                   onSelect: () => setState(() => _selectedPackage = pkg),
                 ),
               )),

            const SizedBox(height: AppSpacing.s6),
            AppButton(
              label: _loading ? 'Memproses...' : 'Berlangganan via Google Play',
              onPressed: _loading || _packages.isEmpty ? null : _checkout,
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
  final bool selected;
  final VoidCallback onSelect;

  const _PackageCard({
    required this.title,
    required this.price,
    required this.desc,
    this.selected = false,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = selected;
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? AppColors.primaryLight : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surface3,
            width: highlight ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(color: AppColors.onSurface2, fontSize: 13)),
          ])),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
      ),
    );
  }
}
