import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/api_client.dart';
import '../../core/services/google_auth_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/subscription_popup.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      final idToken = await ref.read(googleAuthServiceProvider).signIn();
      if (idToken == null) {
        setState(() => _googleLoading = false);
        return; // user cancelled
      }
      final repo = ref.read(authRepositoryProvider);
      final data = await repo.googleAuth(idToken);
      if (data['needs_shop_name'] == true) {
        if (mounted) context.go('/onboarding');
        return;
      }
      final user = await repo.getProfile();
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) {
        context.go('/kasir');
        showSubscriptionPopupIfNeeded(context, ref);
      }
    } catch (e) {
      setState(() => _error = ApiClient.parseError(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email dan sandi tidak boleh kosong.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final repo = ref.read(authRepositoryProvider);
      final data = await repo.login(email, password);

      // Handle requires_verification (owner/admin email not verified)
      if (data['requires_verification'] == true) {
        if (mounted) context.push('/otp', extra: email);
        return;
      }

      final user = await repo.getProfile();
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) {
        context.go('/kasir');
        showSubscriptionPopupIfNeeded(context, ref);
      }
    } catch (e) {
      setState(() => _error = ApiClient.parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.coffee, size: 32, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Selamat datang kembali', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Masuk ke akun Anda', style: TextStyle(fontSize: 15, color: AppColors.onSurface2)),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 14))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: AppSpacing.s4),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Sandi',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              AppButton(label: 'Masuk', onPressed: _login, loading: _loading),
              const SizedBox(height: AppSpacing.s4),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('atau', style: TextStyle(color: AppColors.onSurface3, fontSize: 13)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.s4),
              AppButton(
                label: 'Masuk dengan Google',
                variant: AppButtonVariant.secondary,
                onPressed: _googleLoading ? null : _loginWithGoogle,
                loading: _googleLoading,
                icon: const Icon(Icons.g_mobiledata, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: AppSpacing.s6),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Text.rich(TextSpan(children: [
                    TextSpan(text: 'Belum punya akun? ', style: TextStyle(color: AppColors.onSurface2)),
                    TextSpan(text: 'Daftar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ])),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text('Lupa sandi?', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
