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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // ── Real API call ──────────────────────────
    final result = await AuthApiService.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isError) {
      setState(() => _errorMessage = result.message);
      return;
    }

    // Register berhasil → arahkan ke verifikasi email
    if (result.isRegistered) {
      context.go(
        '${AppRoutes.verifyEmail}?email=${Uri.encodeComponent(result.email ?? _emailController.text.trim())}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
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
                _BrandHeader(isDark: isDark),
                const SizedBox(height: AppSpacing.xl),

                Text('Buat Akun', style: AppTextStyles.h1),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Daftar sebagai Owner dan mulai trial 7 hari gratis',
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Error banner
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
                  label: 'Nama Lengkap',
                  hint: 'Nama Anda',
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: AppSpacing.md),

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
                  textInputAction: TextInputAction.next,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.ashGray,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password wajib diisi';
                    if (v.length < 8) return 'Minimal 8 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  label: 'Konfirmasi Password',
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.ashGray,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Password tidak sama';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                AppButton(
                  label: 'Daftar',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: AppSpacing.md),

                _OrDivider(isDark: isDark),

                const SizedBox(height: AppSpacing.md),

                OutlinedButton(
                  onPressed: () async {
                    setState(() => _isLoading = true);

                    final result = await GoogleAuthService.signIn();

                    if (!mounted) return;
                    setState(() => _isLoading = false);

                    if (result.cancelled) return;

                    if (!result.success) {
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.error ?? 'Google sign-in gagal')),
                      );
                      return;
                    }

                    await ref.read(authProvider.notifier).onLoginSuccess(
                          token: result.token!,
                          user: result.user!,
                        );

                    final doShowTrial = result.user!.role == UserRole.owner &&
                        !AppStorage.instance.isTrialPopupShown;

                    if (doShowTrial) {
                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      await showTrialPopup(context);
                    }

                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    context.go(AppRoutes.cashier);
                  },
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
                      Text('Daftar dengan Google', style: AppTextStyles.button),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sudah punya akun? ', style: AppTextStyles.bodyMedium),
                    TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Masuk',
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
            color: isDark ? AppColors.champagneGold : AppColors.charcoal,
          ),
        ),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.champagneGold : AppColors.brushedGold,
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
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('atau', style: AppTextStyles.caption),
        ),
        Expanded(
          child: Divider(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ],
    );
  }
}
