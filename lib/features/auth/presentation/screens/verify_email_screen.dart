import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/auth_api_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isResending = false;

  Future<void> _resend() async {
    setState(() => _isResending = true);
    final result = await AuthApiService.resendVerification(widget.email);
    if (mounted) {
      setState(() => _isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isError
                ? result.message ?? 'Gagal kirim ulang'
                : 'Email verifikasi dikirim ulang',
          ),
          backgroundColor: result.isError ? AppColors.danger : AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageH,
            vertical: AppSpacing.pageV,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.email_outlined,
                size: 72,
                color: AppColors.brushedGold,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Verifikasi Email', style: AppTextStyles.h1, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Kami mengirim email verifikasi ke:',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.email,
                style: AppTextStyles.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Buka email dan klik link verifikasi untuk mengaktifkan akun Anda.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Saya Sudah Verifikasi',
                onPressed: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: 'Kirim Ulang Email',
                onPressed: _resend,
                isLoading: _isResending,
                variant: AppButtonVariant.ghost,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(
                  'Kembali ke Login',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.ashGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
