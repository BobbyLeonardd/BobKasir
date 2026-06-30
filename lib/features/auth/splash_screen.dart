import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/fcm_service.dart';
import '../../widgets/subscription_popup.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Minimum splash display time
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final authRepo = ref.read(authRepositoryProvider);
    final isLoggedIn = await authRepo.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      try {
        final user = await authRepo.getProfile();
        ref.read(currentUserProvider.notifier).state = user;
        // Initialize FCM after login
        ref.read(fcmServiceProvider).initialize().ignore();
        if (mounted) {
          context.go('/kasir');
          showSubscriptionPopupIfNeeded(context, ref);
        }
      } catch (_) {
        // Token expired / invalid
        await authRepo.logout();
        if (mounted) context.go('/login');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.coffee, size: 52, color: AppColors.primary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'BobKasir',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'by StarCyberCompany',
                    style: TextStyle(fontSize: 13, color: AppColors.onSurface2),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'v1.0.0',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurface3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
