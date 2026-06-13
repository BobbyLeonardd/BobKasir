import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/open_bill_provider.dart';
import '../../domain/open_bill_model.dart';
import '../../../products/domain/product.dart';
import '../../../products/data/product_repository.dart';
import '../../../auth/data/auth_provider.dart';
import '../../../auth/domain/user_model.dart';

class OpenBillDetailScreen extends ConsumerWidget {
  final String billId;
  const OpenBillDetailScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bills = ref.watch(openBillProvider);
    final role = ref.watch(currentRoleProvider) ?? UserRole.karyawan;
    final bill = bills.where((b) => b.id == billId).firstOrNull;

    if (bill == null) {
      return const Scaffold(
        body: Center(child: Text('Open bill tidak ditemukan')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(bill.billNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart_outlined),
            tooltip: 'Tambah Produk',
            onPressed: () => _showAddProductSheet(context, ref, bill),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          _BillInfoBar(bill: bill, isDark: isDark),

          // Items
          Expanded(
            child: bill.items.isEmpty
                ? EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Belum ada item',
                    subtitle: 'Tap + untuk menambah produk',
                    actionLabel: 'Tambah Produk',
                    onAction: () => _showAddProductSheet(context, ref, bill),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pageH,
                      vertical: AppSpacing.md,
                    ),
                    itemCount: bill.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _ItemTile(
                      item: bill.items[i],
                      isDark: isDark,
                      onIncrease: () => ref.read(openBillProvider.notifier)
                          .updateItemQty(bill.id, bill.items[i].id, bill.items[i].qty + 1),
                      onDecrease: () => ref.read(openBillProvider.notifier)
                          .updateItemQty(bill.id, bill.items[i].id, bill.items[i].qty - 1),
                      onRemove: () => ref.read(openBillProvider.notifier)
                          .removeItem(bill.id, bill.items[i].id),
                      onNote: () => _showNoteDialog(context, ref, bill.id, bill.items[i]),
                    ),
                  ),
          ),

          // Bottom bar
          if (bill.items.isNotEmpty)
            _BottomBar(
              bill: bill,
              isDark: isDark,
              role: role,
              onCheckout: () {
                ref.read(openBillProvider.notifier).checkout(bill.id);
                context.go(AppRoutes.cashier);
              },
              onCancel: role.canCancelDirect
                  ? () {
                      ref.read(openBillProvider.notifier).cancel(bill.id);
                      context.pop();
                    }
                  : null,
            ),
        ],
      ),
    );
  }

  void _showAddProductSheet(BuildContext context, WidgetRef ref, OpenBillModel bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scrollCtrl) => _ProductPickerSheet(
          billId: bill.id,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }

  void _showNoteDialog(BuildContext context, WidgetRef ref, String billId, OpenBillItem item) {
    final ctrl = TextEditingController(text: item.note);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Catatan: ${item.productName}'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Catatan item...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(openBillProvider.notifier).updateItemNote(billId, item.id, ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _BillInfoBar extends StatelessWidget {
  final OpenBillModel bill;
  final bool isDark;
  const _BillInfoBar({required this.bill, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Container(
      color: surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageH,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (bill.customerName?.isNotEmpty == true) ...[
            Icon(Icons.person_outline, size: 14, color: AppColors.ashGray),
            const SizedBox(width: 4),
            Text(bill.customerName!, style: AppTextStyles.bodySmall),
            const SizedBox(width: AppSpacing.md),
          ],
          if (bill.tableNumber?.isNotEmpty == true) ...[
            Icon(Icons.table_restaurant_outlined, size: 14, color: AppColors.ashGray),
            const SizedBox(width: 4),
            Text('Meja ${bill.tableNumber!}', style: AppTextStyles.bodySmall),
          ],
          const Spacer(),
          Text('${bill.itemCount} item', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final OpenBillItem item;
  final bool isDark;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final VoidCallback onNote;

  const _ItemTile({
    required this.item,
    required this.isDark,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onNote,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  CurrencyHelper.format(item.price),
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? AppColors.champagneGold : AppColors.brushedGold,
                  ),
                ),
                if (item.note.isNotEmpty)
                  GestureDetector(
                    onTap: onNote,
                    child: Text(
                      '📝 ${item.note}',
                      style: AppTextStyles.caption,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: onNote,
                    child: Text(
                      '+ Tambah catatan',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.champagneGold : AppColors.brushedGold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Qty control
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _QtyBtn(icon: Icons.remove, isDark: isDark, onTap: onDecrease),
              SizedBox(
                width: 32,
                child: Text(
                  '${item.qty}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _QtyBtn(icon: Icons.add, isDark: isDark, onTap: onIncrease),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            CurrencyHelper.format(item.subtotal),
            style: AppTextStyles.price.copyWith(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(icon, size: 15,
            color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final OpenBillModel bill;
  final bool isDark;
  final UserRole role;
  final VoidCallback onCheckout;
  final VoidCallback? onCancel;

  const _BottomBar({
    required this.bill,
    required this.isDark,
    required this.role,
    required this.onCheckout,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (onCancel != null)
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Cancel'),
              ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('TOTAL', style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
                )),
                Text(
                  CurrencyHelper.format(bill.subtotal),
                  style: AppTextStyles.priceTotal.copyWith(
                    color: isDark ? AppColors.champagneGold : AppColors.brushedGold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onCheckout,
                child: const Text('Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPickerSheet extends ConsumerStatefulWidget {
  final String billId;
  final ScrollController scrollController;
  const _ProductPickerSheet({required this.billId, required this.scrollController});

  @override
  ConsumerState<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<_ProductPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final all = ref.watch(productCatalogProvider).maybeWhen(
          data: (c) => c.products.where((p) => p.isActive).toList(),
          orElse: () => const <Product>[],
        );
    final products = all.where((p) {
      if (_search.isEmpty) return true;
      return p.name.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              return ListTile(
                title: Text(p.name, style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                )),
                subtitle: Text(p.categoryName, style: AppTextStyles.caption),
                trailing: Text(
                  CurrencyHelper.format(p.price),
                  style: AppTextStyles.price.copyWith(
                    color: isDark ? AppColors.champagneGold : AppColors.brushedGold,
                  ),
                ),
                onTap: () {
                  ref.read(openBillProvider.notifier).addItem(widget.billId, p);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
