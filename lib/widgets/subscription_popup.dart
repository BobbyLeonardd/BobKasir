import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/providers/app_providers.dart';
import 'app_button.dart';

/// Show subscription/trial popup when owner logs in for the first time.
/// Call this after setting currentUserProvider.
void showSubscriptionPopupIfNeeded(BuildContext context, WidgetRef ref) {
  final user = ref.read(currentUserProvider);
  if (user == null || !user.isOwner) return;

  final sub = ref.read(subscriptionProvider);
  // Only show for trial or expired
  if (sub.hasFullAccess && sub.status == SubscriptionStatus.active) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SubscriptionPopup(sub: sub),
    );
  });
}

class _SubscriptionPopup extends StatelessWidget {
  final SubscriptionState sub;
  const _SubscriptionPopup({required this.sub});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final isTrial = sub.status == SubscriptionStatus.trial;
    final isExpired = sub.status == SubscriptionStatus.expired;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: isTrial ? AppColors.infoBg : AppColors.errorBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isTrial ? Icons.access_time_outlined : Icons.lock_outline,
                color: isTrial ? AppColors.info : AppColors.error,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTrial ? 'Trial 7 Hari Aktif 🎉' : 'Langganan Berakhir',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isTrial
                  ? 'Nikmati semua fitur BobKasir gratis selama 7 hari.${sub.expiresAt != null ? '\n\nTrial berakhir: ${fmt.format(sub.expiresAt!)}' : ''}'
                  : 'Akses fitur penuh Anda telah berakhir. Pilih paket untuk melanjutkan operasional.',
              style: const TextStyle(color: AppColors.onSurface2, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s6),
            AppButton(
              label: isTrial ? 'Mulai Gunakan' : 'Pilih Paket',
              onPressed: () {
                Navigator.pop(context);
                if (isExpired) context.push('/settings/subscription');
              },
            ),
            if (isExpired) ...[
              const SizedBox(height: AppSpacing.s3),
              AppButton(
                label: 'Nanti Saja',
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
