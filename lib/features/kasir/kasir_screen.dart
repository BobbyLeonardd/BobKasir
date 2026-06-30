import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/repositories/openbill_repository.dart';
import '../../core/models/product_model.dart';
import '../../core/models/order_model.dart';
import '../../core/utils/currency.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_button.dart';
import 'openbill_sheet.dart';

class KasirScreen extends ConsumerStatefulWidget {
  const KasirScreen({super.key});
  @override
  ConsumerState<KasirScreen> createState() => _KasirScreenState();
}

class _KasirScreenState extends ConsumerState<KasirScreen> {
  void _openOpenbillSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const OpenbillSheet(),
    );
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CartSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final products = ref.watch(filteredProductsProvider).value ?? [];
    final cartCount = ref.watch(cartItemCountProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final selectedCat = ref.watch(selectedCategoryProvider);
    final user = ref.watch(currentUserProvider);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    final header = Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.coffee, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(user?.name ?? 'Kedai', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
          Stack(
            clipBehavior: Clip.none,
            children: [
              TextButton.icon(
                onPressed: _openOpenbillSheet,
                icon: const Icon(Icons.receipt_outlined, size: 18),
                label: const Text('Openbill'),
                style: TextButton.styleFrom(foregroundColor: AppColors.onSurface2),
              ),
              if ((ref.watch(openbillsProvider).value ?? []).isNotEmpty)
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 16, height: 16,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text('${(ref.watch(openbillsProvider).value ?? []).length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          TextButton.icon(
            onPressed: () => context.push('/reservasi'),
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: const Text('Reservasi'),
            style: TextButton.styleFrom(foregroundColor: AppColors.onSurface2),
          ),
        ],
      ),
    );

    final categoryChips = SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Semua'),
              selected: selectedCat == null,
              onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = null,
            ),
          ),
          ...categories.map((c) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(c.name),
              selected: selectedCat == c.id,
              onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = c.id,
            ),
          )),
        ],
      ),
    );

    final productGrid = products.isEmpty
        ? const EmptyState(icon: Icons.coffee_outlined, message: 'Belum ada produk.')
        : GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.s3),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isTablet ? 3 : 2,
              childAspectRatio: 0.82,
              crossAxisSpacing: AppSpacing.s3,
              mainAxisSpacing: AppSpacing.s3,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) => _ProductCard(product: products[i]),
          );

    final cartBar = cartCount == 0
        ? Container(
            height: AppSpacing.cartBarHeight,
            color: AppColors.surface3,
            alignment: Alignment.center,
            child: const Text('Belum ada item', style: TextStyle(color: AppColors.onSurface3, fontSize: 13)),
          )
        : GestureDetector(
            onTap: _openCart,
            child: Container(
              height: AppSpacing.cartBarHeight,
              color: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('$cartCount item', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(formatRupiah(cartTotal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                ],
              ),
            ),
          );

    if (isTablet) {
      return Column(
        children: [
          header,
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      categoryChips,
                      const SizedBox(height: 4),
                      Expanded(child: productGrid),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(width: 320, child: _CartPanel()),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        header,
        const Divider(height: 1),
        const SizedBox(height: 8),
        categoryChips,
        const SizedBox(height: 4),
        Expanded(child: productGrid),
        cartBar,
      ],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOut = product.isOutOfStock;
    return GestureDetector(
      onTap: isOut ? null : () => ref.read(cartProvider.notifier).addProduct(product),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isOut ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
                          child: Image.network(product.imageUrl!, fit: BoxFit.cover),
                        )
                      : const Center(child: Icon(Icons.coffee, size: 36, color: AppColors.onSurface3)),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(formatRupiah(product.price), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      if (isOut)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(999)),
                          child: const Text('HABIS', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartSheet extends ConsumerWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, ctrl) => Column(
        children: [
          Container(height: 4, width: 40, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: AppColors.surface3, borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Align(alignment: Alignment.centerLeft, child: Text('Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          const Divider(),
          Expanded(
            child: ListView.separated(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cart.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => _CartItemRow(item: cart[i]),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(color: AppColors.onSurface2)),
                    Text(formatRupiah(total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Openbill',
                        variant: AppButtonVariant.secondary,
                        onPressed: () async {
                          final items = List<CartItem>.from(ref.read(cartProvider));
                          Navigator.pop(context);
                          try {
                            await ref.read(openbillRepositoryProvider).createOpenbill('Tanpa nama', items);
                            ref.read(cartProvider.notifier).clear();
                            ref.invalidate(openbillsProvider);
                          } catch (_) {}
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'Checkout →',
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/checkout');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _CartItemRow extends ConsumerWidget {
  final CartItem item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w500))),
          Row(
            children: [
              IconButton(iconSize: 18, icon: const Icon(Icons.remove_circle_outline), onPressed: () => ref.read(cartProvider.notifier).decrement(item.productId), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w700))),
              IconButton(iconSize: 18, icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), onPressed: () => ref.read(cartProvider.notifier).increment(item.productId), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(width: 8),
          Text(formatRupiah(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _CartPanel extends ConsumerWidget {
  const _CartPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    return Column(
      children: [
        Expanded(
          child: cart.isEmpty
              ? const EmptyState(icon: Icons.shopping_cart_outlined, message: 'Keranjang kosong')
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _CartItemRow(item: cart[i]),
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontSize: 15, color: AppColors.onSurface2)),
                  Text(formatRupiah(total), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              AppButton(label: 'Checkout', onPressed: () => context.push('/checkout')),
            ],
          ),
        ),
      ],
    );
  }
}
