import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/services/google_auth_service.dart';
import '../../core/providers/app_providers.dart';
import '../../widgets/app_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  int _step = 0;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _shopCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    _confirmCtrl.dispose(); _shopCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerWithGoogle() async {
    setState(() { _googleLoading = true; _error = null; });
    try {
      final idToken = await ref.read(googleAuthServiceProvider).signIn();
      if (idToken == null) { setState(() => _googleLoading = false); return; }
      final repo = ref.read(authRepositoryProvider);
      final data = await repo.googleAuth(idToken);
      if (data['needs_shop_name'] == true) {
        if (mounted) context.go('/onboarding');
        return;
      }
      final user = await repo.getProfile();
      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) context.go('/kasir');
    } catch (e) {
      setState(() => _error = ApiClient.parseError(e));
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _nextStep() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Semua field wajib diisi.');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'Konfirmasi sandi tidak cocok.');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'Sandi minimal 8 karakter.');
      return;
    }
    setState(() { _step = 1; _error = null; });
  }

  Future<void> _register() async {
    if (_shopCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nama kedai wajib diisi.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authRepositoryProvider).register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        shopName: _shopCtrl.text.trim(),
        shopAddress: _addressCtrl.text.isEmpty ? null : _addressCtrl.text.trim(),
      );
      // Redirect to OTP verification
      if (mounted) context.push('/otp', extra: _emailCtrl.text.trim());
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
      appBar: AppBar(
        title: Text(_step == 0 ? 'Daftar Akun' : 'Info Kedai'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _step == 0 ? context.pop() : setState(() { _step = 0; _error = null; }),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
            child: Row(
              children: [
                _StepDot(active: _step == 0, done: _step > 0, label: '1'),
                Expanded(child: Divider(color: _step > 0 ? AppColors.primary : AppColors.surface3)),
                _StepDot(active: _step == 1, done: false, label: '2'),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6, vertical: AppSpacing.s4),
              child: _step == 0 ? _buildStep1() : _buildStep2(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Data Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.s6),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Lengkap')),
          const SizedBox(height: AppSpacing.s4),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: AppSpacing.s4),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Sandi',
              suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          TextField(controller: _confirmCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi Sandi')),
          const SizedBox(height: AppSpacing.s6),
          AppButton(label: 'Lanjut', onPressed: _nextStep),
          const SizedBox(height: AppSpacing.s4),
          AppButton(
            label: 'Daftar dengan Google',
            variant: AppButtonVariant.secondary,
            loading: _googleLoading,
            onPressed: _googleLoading ? null : _registerWithGoogle,
            icon: const Icon(Icons.g_mobiledata, color: AppColors.primary, size: 22),
          ),
        ],
      );

  Widget _buildStep2() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Info Kedai', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.s6),
          TextField(controller: _shopCtrl, decoration: const InputDecoration(labelText: 'Nama Kedai')),
          const SizedBox(height: AppSpacing.s4),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Alamat (opsional)')),
          const SizedBox(height: AppSpacing.s6),
          AppButton(
            label: 'Selesai & Mulai',
            loading: _loading,
            onPressed: _loading ? null : _register,
          ),
        ],
      );
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  final String label;
  const _StepDot({required this.active, required this.done, required this.label});

  @override
  Widget build(BuildContext context) {
    final bg = done || active ? AppColors.primary : AppColors.surface3;
    final fg = done || active ? Colors.white : AppColors.onSurface3;
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: done ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
