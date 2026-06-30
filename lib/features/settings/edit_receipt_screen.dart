import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/receipt_setting_repository.dart';
import '../../core/services/api_client.dart';
import '../../widgets/app_button.dart';

class EditReceiptScreen extends ConsumerStatefulWidget {
  const EditReceiptScreen({super.key});
  @override
  ConsumerState<EditReceiptScreen> createState() => _EditReceiptScreenState();
}

class _EditReceiptScreenState extends ConsumerState<EditReceiptScreen> {
  final _shopCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _wifiCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  String _paperWidth = '58';
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _shopCtrl.dispose(); _addressCtrl.dispose(); _wifiCtrl.dispose(); _footerCtrl.dispose();
    super.dispose();
  }

  void _loadFromSettings(ReceiptSettingModel s) {
    if (_loaded) return;
    _loaded = true;
    _shopCtrl.text = s.shopName;
    _addressCtrl.text = s.address ?? '';
    _wifiCtrl.text = s.note ?? '';
    _footerCtrl.text = s.footer ?? '';
    _paperWidth = s.paperWidth;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = ReceiptSettingModel(
        shopName: _shopCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        note: _wifiCtrl.text.trim().isEmpty ? null : _wifiCtrl.text.trim(),
        footer: _footerCtrl.text.trim().isEmpty ? null : _footerCtrl.text.trim(),
        paperWidth: _paperWidth,
      );
      await ref.read(receiptSettingRepositoryProvider).update(updated);
      ref.invalidate(receiptSettingProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tersimpan')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Load settings once from API
    final settingsAsync = ref.watch(receiptSettingProvider);
    settingsAsync.whenData(_loadFromSettings);

    final isTablet = MediaQuery.of(context).size.width >= 600;
    final formWidget = SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _shopCtrl, decoration: const InputDecoration(labelText: 'Nama Kedai')),
          const SizedBox(height: AppSpacing.s4),
          TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Alamat')),
          const SizedBox(height: AppSpacing.s4),
          TextField(controller: _wifiCtrl, decoration: const InputDecoration(labelText: 'Keterangan (WiFi, dll)')),
          const SizedBox(height: AppSpacing.s4),
          TextField(controller: _footerCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Footer / Ucapan')),
          const SizedBox(height: AppSpacing.s4),
          const Text('Ukuran Kertas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: ['58', '80'].map((w) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(label: Text('${w}mm'), selected: _paperWidth == w, onSelected: (_) => setState(() => _paperWidth = w)),
          )).toList()),
          const SizedBox(height: AppSpacing.s4),
          Row(children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.surface3)),
              child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.onSurface3, size: 32),
            ),
            const SizedBox(width: 12),
            const Text('Logo kedai (opsional)', style: TextStyle(color: AppColors.onSurface2, fontSize: 13)),
          ]),
          if (!isTablet) ...[
            const SizedBox(height: AppSpacing.s6),
            const Text('Preview Struk', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: AppSpacing.s3),
            _buildPreview(),
          ],
          const SizedBox(height: AppSpacing.s6),
          AppButton(
            label: _saving ? 'Menyimpan...' : 'Simpan',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );

    if (isTablet) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Template Struk')),
        body: Row(
          children: [
            Expanded(child: formWidget),
            const VerticalDivider(width: 1),
            Expanded(child: Padding(padding: const EdgeInsets.all(AppSpacing.s6), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Preview Struk', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: AppSpacing.s3),
              _buildPreview(),
            ]))),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Template Struk')),
      body: formWidget,
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: AppColors.surface3), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_shopCtrl.text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), textAlign: TextAlign.center),
          Text(_addressCtrl.text, style: const TextStyle(fontSize: 11, color: AppColors.onSurface2), textAlign: TextAlign.center),
          if (_wifiCtrl.text.isNotEmpty) Text(_wifiCtrl.text, style: const TextStyle(fontSize: 11, color: AppColors.onSurface2), textAlign: TextAlign.center),
          const Divider(height: 16),
          const _PreviewRow(label: 'Americano × 1', value: 'Rp 25.000'),
          const _PreviewRow(label: 'Total', value: 'Rp 25.000', bold: true),
          const Divider(height: 16),
          Text(_footerCtrl.text, style: const TextStyle(fontSize: 11, color: AppColors.onSurface2), textAlign: TextAlign.center),
          const Text('by StarCyberCompany', style: TextStyle(fontSize: 10, color: AppColors.onSurface3), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _PreviewRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w700 : FontWeight.w400);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: style), Text(value, style: style)]),
    );
  }
}
