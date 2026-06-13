import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../data/promo_provider.dart';
import '../../domain/promo_model.dart';

class PromoScreen extends ConsumerWidget {
  const PromoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final promos = ref.watch(promoProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Promo & Voucher'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, ref),
        backgroundColor: isDark ? AppColors.champagneGold : AppColors.charcoal,
        child: Icon(Icons.add, color: isDark ? AppColors.obsidian : Colors.white),
      ),
      body: promos.isEmpty
          ? EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'Belum ada promo',
              subtitle: 'Buat promo atau voucher untuk menarik pelanggan.',
              actionLabel: 'Buat Promo',
              onAction: () => _showForm(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageH,
                vertical: AppSpacing.md,
              ),
              itemCount: promos.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) => _PromoCard(
                promo: promos[i],
                isDark: isDark,
                onEdit: () => _showForm(context, ref, existing: promos[i]),
                onToggle: () =>
                    ref.read(promoProvider.notifier).toggleActive(promos[i].id),
                onDelete: () =>
                    ref.read(promoProvider.notifier).delete(promos[i].id),
              ),
            ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref,
      {PromoModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => _PromoFormSheet(
        existing: existing,
        onSave: (p) {
          if (existing == null) {
            ref.read(promoProvider.notifier).add(p);
          } else {
            ref.read(promoProvider.notifier).update(existing.id, p);
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final PromoModel promo;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PromoCard({
    required this.promo,
    required this.isDark,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final accent = isDark ? AppColors.champagneGold : AppColors.brushedGold;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: promo.isValid ? accent.withValues(alpha: 0.3) : border,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  promo.typeLabel,
                  style: AppTextStyles.button.copyWith(color: accent, fontSize: 13),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  promo.name,
                  style: AppTextStyles.h3.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              StatusBadge(
                label: promo.isValid ? 'Aktif' : 'Nonaktif',
                type: promo.isValid ? BadgeType.success : BadgeType.neutral,
              ),
            ],
          ),
          if (promo.hasCode) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      size: 13, color: accent),
                  const SizedBox(width: 4),
                  Text(
                    promo.code!,
                    style: AppTextStyles.buttonSmall.copyWith(
                      letterSpacing: 2,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (promo.description?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(promo.description!, style: AppTextStyles.bodySmall),
          ],
          if (promo.minTransaction != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Min. transaksi: ${CurrencyHelper.format(promo.minTransaction!)}',
              style: AppTextStyles.caption,
            ),
          ],
          if (promo.validUntil != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Berlaku s/d: ${DateFormat('dd MMM yyyy', 'id_ID').format(promo.validUntil!)}',
              style: AppTextStyles.caption.copyWith(
                color: promo.validUntil!.isBefore(DateTime.now().add(const Duration(days: 3)))
                    ? AppColors.warning
                    : null,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Digunakan: ${promo.usageCount}x',
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text('Edit', style: AppTextStyles.buttonSmall),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                ),
                child: Text(
                  promo.isActive ? 'Nonaktifkan' : 'Aktifkan',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: promo.isActive ? AppColors.warning : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  foregroundColor: AppColors.danger,
                ),
                child: Text('Hapus', style: AppTextStyles.buttonSmall),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoFormSheet extends StatefulWidget {
  final PromoModel? existing;
  final void Function(PromoModel) onSave;

  const _PromoFormSheet({this.existing, required this.onSave});

  @override
  State<_PromoFormSheet> createState() => _PromoFormSheetState();
}

class _PromoFormSheetState extends State<_PromoFormSheet> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  PromoType _type = PromoType.percent;
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _hasCode = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final p = widget.existing!;
      _nameCtrl.text = p.name;
      _codeCtrl.text = p.code ?? '';
      _valueCtrl.text = p.discountValue.toStringAsFixed(0);
      _minCtrl.text = p.minTransaction?.toString() ?? '';
      _maxCtrl.text = p.maxDiscount?.toString() ?? '';
      _descCtrl.text = p.description ?? '';
      _type = p.type;
      _validFrom = p.validFrom;
      _validUntil = p.validUntil;
      _hasCode = p.hasCode;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.md,
        AppSpacing.pageH,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existing == null ? 'Buat Promo' : 'Edit Promo',
              style: AppTextStyles.h2,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Promo *'),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Type
            DropdownButtonFormField<PromoType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipe Diskon'),
              items: [
                const DropdownMenuItem(
                    value: PromoType.percent,
                    child: Text('Persentase (%)')),
                const DropdownMenuItem(
                    value: PromoType.nominal, child: Text('Nominal (Rp)')),
              ],
              onChanged: (v) => setState(() => _type = v!),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _valueCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: _type == PromoType.percent
                    ? 'Persentase (%)'
                    : 'Nominal (Rp)',
                suffixText: _type == PromoType.percent ? '%' : null,
                prefixText: _type == PromoType.nominal ? 'Rp ' : null,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Voucher code toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Pakai Kode Voucher', style: AppTextStyles.bodyMedium),
              value: _hasCode,
              onChanged: (v) => setState(() => _hasCode = v),
              activeThumbColor: AppColors.charcoal,
            ),
            if (_hasCode) ...[
              TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Kode Voucher',
                  hintText: 'Contoh: PROMO2026',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextField(
              controller: _minCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Min. Transaksi (Opsional)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Mulai', style: AppTextStyles.caption),
                    subtitle: Text(
                      _validFrom != null
                          ? dateFmt.format(_validFrom!)
                          : 'Pilih tanggal',
                      style: AppTextStyles.bodySmall,
                    ),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _validFrom ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => _validFrom = d);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Berakhir', style: AppTextStyles.caption),
                    subtitle: Text(
                      _validUntil != null
                          ? dateFmt.format(_validUntil!)
                          : 'Pilih tanggal',
                      style: AppTextStyles.bodySmall,
                    ),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate:
                            _validUntil ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (d != null) setState(() => _validUntil = d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameCtrl.text.isEmpty || _valueCtrl.text.isEmpty) return;
                  widget.onSave(PromoModel(
                    id: widget.existing?.id,
                    name: _nameCtrl.text,
                    code: _hasCode && _codeCtrl.text.isNotEmpty
                        ? _codeCtrl.text.toUpperCase()
                        : null,
                    type: _type,
                    discountValue: double.tryParse(_valueCtrl.text) ?? 0,
                    minTransaction: _minCtrl.text.isEmpty
                        ? null
                        : int.tryParse(_minCtrl.text),
                    validFrom: _validFrom,
                    validUntil: _validUntil,
                    description:
                        _descCtrl.text.isEmpty ? null : _descCtrl.text,
                  ));
                },
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
