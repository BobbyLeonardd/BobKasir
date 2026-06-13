import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';

class _DiscountItem {
  final String id;
  final String name;
  final String type; // 'percent' | 'nominal'
  final int value;
  bool isActive;

  _DiscountItem({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
  }) : isActive = true;

  String get displayValue => type == 'percent'
      ? '$value%'
      : CurrencyHelper.format(value);
}

class DiscountScreen extends StatefulWidget {
  const DiscountScreen({super.key});

  @override
  State<DiscountScreen> createState() => _DiscountScreenState();
}

class _DiscountScreenState extends State<DiscountScreen> {
  final List<_DiscountItem> _discounts = [
    _DiscountItem(
        id: '1', name: 'Diskon 10%', type: 'percent', value: 10),
    _DiscountItem(
        id: '2', name: 'Member', type: 'percent', value: 15),
    _DiscountItem(
        id: '3',
        name: 'Happy Hour',
        type: 'nominal',
        value: 10000),
  ];

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String type = 'percent';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Tambah Diskon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Nama Diskon'),
              ),
              const SizedBox(height: AppSpacing.sm),
              RadioGroup<String>(
                groupValue: type,
                onChanged: (v) {
                  if (v != null) setLocal(() => type = v);
                },
                child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text('Persen',
                            style: AppTextStyles.bodySmall),
                        value: 'percent',
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: Text('Nominal',
                            style: AppTextStyles.bodySmall),
                        value: 'nominal',
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: valueCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  labelText: type == 'percent'
                      ? 'Persentase (%)'
                      : 'Nominal (Rp)',
                  suffixText: type == 'percent' ? '%' : null,
                  prefixText: type == 'nominal' ? 'Rp ' : null,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty ||
                    valueCtrl.text.isEmpty) { return; }
                setState(() {
                  _discounts.add(_DiscountItem(
                    id:
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text,
                    type: type,
                    value: int.parse(valueCtrl.text),
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Diskon'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor:
            isDark ? AppColors.champagneGold : AppColors.charcoal,
        child: Icon(Icons.add,
            color: isDark ? AppColors.obsidian : Colors.white),
      ),
      body: _discounts.isEmpty
          ? EmptyState(
              icon: Icons.local_offer_outlined,
              title: 'Belum ada diskon',
              subtitle:
                  'Tambahkan diskon untuk diterapkan saat transaksi.',
              actionLabel: 'Tambah Diskon',
              onAction: _showAddDialog,
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageH,
                vertical: AppSpacing.md,
              ),
              itemCount: _discounts.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final d = _discounts[i];
                return Container(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: border),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brushedGold
                            .withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Center(
                        child: Text(
                          d.displayValue,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.champagneGold
                                : AppColors.brushedGold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      d.name,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      d.type == 'percent'
                          ? 'Diskon persen'
                          : 'Diskon nominal',
                      style: AppTextStyles.caption,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(
                          label: d.isActive ? 'Aktif' : 'Nonaktif',
                          type: d.isActive
                              ? BadgeType.success
                              : BadgeType.neutral,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(d.isActive
                                  ? 'Nonaktifkan'
                                  : 'Aktifkan'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Hapus',
                                  style: TextStyle(
                                      color: AppColors.danger)),
                            ),
                          ],
                          onSelected: (v) {
                            if (v == 'toggle') {
                              setState(() =>
                                  _discounts[i].isActive =
                                      !_discounts[i].isActive);
                            } else if (v == 'delete') {
                              setState(
                                  () => _discounts.removeAt(i));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
