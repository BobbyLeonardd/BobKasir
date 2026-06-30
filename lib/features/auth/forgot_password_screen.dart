import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../widgets/app_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls = List.generate(6, (_) => TextEditingController());
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose(); _passCtrl.dispose();
    for (final c in _otpCtrls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Lupa Sandi'), backgroundColor: AppColors.surface, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
        child: _step == 0 ? _buildStep1() : _step == 1 ? _buildStep2() : _buildStep3(),
      ),
    );
  }

  Widget _buildStep1() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Masukkan email Anda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Kami akan kirim kode verifikasi ke email tersebut.', style: TextStyle(color: AppColors.onSurface2)),
          const SizedBox(height: AppSpacing.s6),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: AppSpacing.s6),
          AppButton(label: 'Kirim Kode', loading: _loading, onPressed: () => setState(() => _step = 1)),
        ],
      );

  Widget _buildStep2() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Masukkan kode OTP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.s6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (i) => SizedBox(
              width: 44, height: 52,
              child: TextField(
                controller: _otpCtrls[i],
                textAlign: TextAlign.center,
                maxLength: 1,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.zero),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            )),
          ),
          const SizedBox(height: AppSpacing.s6),
          AppButton(label: 'Verifikasi', onPressed: () => setState(() => _step = 2)),
        ],
      );

  Widget _buildStep3() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Sandi Baru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.s6),
          TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Sandi Baru')),
          const SizedBox(height: AppSpacing.s4),
          TextField(obscureText: true, decoration: const InputDecoration(labelText: 'Konfirmasi Sandi')),
          const SizedBox(height: AppSpacing.s6),
          AppButton(label: 'Simpan Sandi Baru', loading: _loading, onPressed: () {
            setState(() => _loading = true);
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) context.go('/login');
            });
          }),
        ],
      );
}
