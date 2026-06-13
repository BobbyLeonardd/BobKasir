import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/data/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _subtextFade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
    );
    _subtextFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigate(AuthState authState) {
    if (_navigated) return;
    if (authState.isLoading) return;

    _navigated = true;
    if (authState.isAuthenticated) {
      context.go(AppRoutes.cashier);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    // Watch auth and navigate after minimum splash duration
    ref.listen(authProvider, (_, next) {
      if (!next.isLoading) {
        // Ensure at least 1.8s of splash
        Future.delayed(
          _controller.isCompleted
              ? Duration.zero
              : const Duration(milliseconds: 400),
          () {
            if (mounted) _navigate(next);
          },
        );
      }
    });

    // If auth resolved quickly, trigger after animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !authState.isLoading) {
        if (mounted) _navigate(authState);
      }
    });

    final logoColor =
        isDark ? AppColors.champagneGold : AppColors.charcoal;
    final dotColor =
        isDark ? AppColors.champagneGold : AppColors.brushedGold;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logoFade,
              child: _LogoMark(charColor: logoColor, dotColor: dotColor),
            ),
            const SizedBox(height: AppSpacing.lg),
            FadeTransition(
              opacity: _textFade,
              child: Text(
                AppConstants.appName.toUpperCase(),
                style: AppTextStyles.label.copyWith(
                  fontSize: 13,
                  letterSpacing: 6,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FadeTransition(
              opacity: _subtextFade,
              child: Text(
                'v${AppConstants.appVersion}',
                style: AppTextStyles.caption.copyWith(
                  letterSpacing: 1,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.ashGray,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: FadeTransition(
        opacity: _subtextFade,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Text(
              'Created by ${AppConstants.companyName}'.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                letterSpacing: 2,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  final Color charColor;
  final Color dotColor;
  const _LogoMark({required this.charColor, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text(
          'B',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 80,
            fontWeight: FontWeight.w300,
            color: charColor,
            letterSpacing: -4,
          ),
        ),
        Positioned(
          right: -6,
          bottom: 16,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
