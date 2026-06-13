import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../data/auth_provider.dart';
import '../../data/auth_api_service.dart';
import '../../data/google_auth_service.dart';
import '../../domain/user_model.dart';
import '../../../../core/storage/app_storage.dart';
import '../widgets/trial_popup.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ── Real API call ──────────────────────────
    final result = await AuthApiService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Email belum diverifikasi
    if (result.isEmailUnverified) {
      context.push(
        '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(result.email ?? '')}',
      );
      return;
    }

    if (result.isError) {
      setState(() => _errorMessage = result.message);
      return;
    }

    // Login berhasil
    await ref.read(authProvider.notifier).onLoginSuccess(
          token: result.token!,
          user: result.user!,
        );

    if (!mounted) return;

    // Show trial popup untuk owner baru
    if (result.user!.role == UserRole.owner &&
        !AppStorage.instance.isTrialPopupShown) {
      await AppStorage.instance.markFirstLoginDone();
      if (!mounted) return;
      await showTrialPopup(context);
    }

    if (!mounted) return;
    context.go(AppRoutes.cashier);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageH,
            vertical: AppSpacing.pageV,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                _BrandHeader(isDark: isDark),
                const SizedBox(height: AppSpacing.xxl),

                Text('Masuk', style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Kelola bisnis Anda dengan mudah',
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: AppSpacing.xl),

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                AppTextField(
                  label: 'Email',
                  hint: 'nama@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email wajib diisi';
                    if (!v.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.ashGray,
                      size: 20,
                    ),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.forgotPassword),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Lupa password?',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.champagneGold
                            : AppColors.brushedGold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                AppButton(
                  label: 'Masuk',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: AppSpacing.md),

                _OrDivider(isDark: isDark),
                const SizedBox(height: AppSpacing.md),

                _GoogleButton(onPressed: () async {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  final result = await GoogleAuthService.signIn();

                  if (!mounted) return;
                  setState(() => _isLoading = false);

                  if (result.cancelled) return;

                  if (!result.success) {
                    setState(() => _errorMessage = result.error);
                    return;
                  }

                  await ref.read(authProvider.notifier).onLoginSuccess(
                        token: result.token!,
                        user: result.user!,
                      );

                  final doShowTrial = result.isNewUser &&
                      result.user!.role == UserRole.owner &&
                      !AppStorage.instance.isTrialPopupShown;

                  if (doShowTrial) {
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    await showTrialPopup(context);
                  }

                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  context.go(AppRoutes.cashier);
                }),

                const SizedBox(height: AppSpacing.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Belum punya akun? ',
                        style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () =>
                          context.push(AppRoutes.register),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Daftar',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.champagneGold
                              : AppColors.charcoal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final bool isDark;
  const _BrandHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'B',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 32,
            fontWeight: FontWeight.w300,
            color:
                isDark ? AppColors.champagneGold : AppColors.charcoal,
          ),
        ),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.champagneGold
                : AppColors.brushedGold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          AppConstants.appName,
          style: AppTextStyles.h2.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  final bool isDark;
  const _OrDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md),
          child: Text('atau', style: AppTextStyles.caption),
        ),
        Expanded(
          child: Divider(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder,
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'G',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Masuk dengan Google', style: AppTextStyles.button),
        ],
      ),
    );
  }
}
