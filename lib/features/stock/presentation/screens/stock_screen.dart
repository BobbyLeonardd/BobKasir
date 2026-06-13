import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../products/domain/product.dart';
import '../../../products/data/product_repository.dart';

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filter(List<Product> source) {
    if (_search.isEmpty) return source;
    final q = _search.toLowerCase();
    return source.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Stok')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageH,
              AppSpacing.sm,
              AppSpacing.pageH,
              0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ref.watch(productCatalogProvider).when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, _) => Center(
                    child: TextButton(
                      onPressed: () =>
                          ref.invalidate(productCatalogProvider),
                      child: const Text('Gagal memuat. Coba lagi'),
                    ),
                  ),
                  data: (catalog) {
                    final items = _filter(catalog.products);
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Produk tidak ditemukan',
                        subtitle: 'Coba kata kunci berbeda.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageH,
                        vertical: AppSpacing.md,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _StockTile(
                        product: items[i],
                        isDark: isDark,
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _StockTile extends StatelessWidget {
  final Product product;
  final bool isDark;

  const _StockTile({required this.product, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final stock = product.stock;
    final isLow = stock != null && stock <= 5 && stock > 0;
    final isOut = stock != null && stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isOut
              ? AppColors.dangerLight
              : isLow
                  ? AppColors.warningLight
                  : border,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        title: Text(
          product.name,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          product.categoryName,
          style: AppTextStyles.caption,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stock == null)
              const StatusBadge(
                  label: 'Tidak Lacak', type: BadgeType.neutral)
            else if (isOut)
              const StatusBadge(label: 'Habis', type: BadgeType.danger)
            else if (isLow)
              StatusBadge(
                  label: '$stock tersisa',
                  type: BadgeType.warning)
            else
              StatusBadge(
                  label: '$stock', type: BadgeType.success),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () =>
                  _showAdjustDialog(context, product, isDark),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkBackground
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.ashGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustDialog(
      BuildContext context, Product product, bool isDark) {
    final ctrl = TextEditingController();
    String type = 'add';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Kelola Stok: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stok saat ini: ${product.stock ?? "Tidak dilacak"}',
                  style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.md),
              // Type selector
              Row(
                children: [
                  _TypeBtn(
                    label: '+ Tambah',
                    selected: type == 'add',
                    color: AppColors.success,
                    onTap: () => setState(() => type = 'add'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _TypeBtn(
                    label: '- Kurangi',
                    selected: type == 'subtract',
                    color: AppColors.danger,
                    onTap: () => setState(() => type = 'subtract'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  _TypeBtn(
                    label: '= Koreksi',
                    selected: type == 'set',
                    color: AppColors.info,
                    onTap: () => setState(() => type = 'set'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly
                ],
                decoration: InputDecoration(
                  labelText: type == 'set' ? 'Stok baru' : 'Jumlah',
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
                // TODO: Call stock API / update local DB
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stok diperbarui')),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(
              color: selected ? color : AppColors.lightBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? color : AppColors.ashGray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
