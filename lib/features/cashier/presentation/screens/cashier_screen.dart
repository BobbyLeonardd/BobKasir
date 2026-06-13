import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../data/cart_provider.dart';
import '../../domain/cart_item.dart';
import '../../../products/domain/product.dart';
import '../../../products/data/product_repository.dart';

class CashierScreen extends ConsumerStatefulWidget {
  const CashierScreen({super.key});

  @override
  ConsumerState<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends ConsumerState<CashierScreen> {
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> source) {
    var products = source.where((p) => p.isActive).toList();
    if (_selectedCategoryId != 'all') {
      products =
          products.where((p) => p.categoryId == _selectedCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      products = products.where((p) => p.name.toLowerCase().contains(q)).toList();
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(cartProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final cartSubtotal = ref.watch(cartSubtotalProvider);
    final catalogAsync = ref.watch(productCatalogProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            catalogAsync.maybeWhen(
              data: (c) => _buildCategoryFilter(isDark, c.categories),
              orElse: () => const SizedBox(height: 40),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product grid
                  Expanded(
                    flex: 3,
                    child: catalogAsync.when(
                      data: (c) => _buildProductGrid(
                          isDark, _filterProducts(c.products)),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, _) => _buildError(isDark),
                    ),
                  ),
                  // Cart sidebar (if has items)
                  if (cart.isNotEmpty)
                    _CartSidebar(
                      cart: cart,
                      subtotal: cartSubtotal,
                      onCheckout: () => context.push(AppRoutes.checkout),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Floating checkout button (phone view, when cart has items)
      floatingActionButton: cart.isNotEmpty
          ? _FloatingCartButton(
              count: cartCount,
              subtotal: cartSubtotal,
              onTap: () => context.push(AppRoutes.checkout),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 40,
              color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Gagal memuat produk',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => ref.invalidate(productCatalogProvider),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.md,
        AppSpacing.pageH,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.ashGray,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Shift / open bill buttons
          _IconBtn(
            icon: Icons.receipt_outlined,
            isDark: isDark,
            tooltip: 'Open Bill',
            onTap: () => context.push(AppRoutes.openBill),
          ),
          const SizedBox(width: AppSpacing.xs),
          _IconBtn(
            icon: Icons.event_outlined,
            isDark: isDark,
            tooltip: 'Reservasi',
            onTap: () => context.push(AppRoutes.reservation),
          ),
          const SizedBox(width: AppSpacing.xs),
          _IconBtn(
            icon: Icons.restaurant_outlined,
            isDark: isDark,
            tooltip: 'Kitchen Display',
            onTap: () => context.push(AppRoutes.kitchenDisplay),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark, List<Category> categories) {
    final cats = [const Category(id: 'all', name: 'Semua'), ...categories];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final cat = cats[i];
          final isSelected = cat.id == _selectedCategoryId;
          return _CategoryChip(
            label: cat.name,
            isSelected: isSelected,
            isDark: isDark,
            onTap: () => setState(() => _selectedCategoryId = cat.id),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(bool isDark, List<Product> products) {
    if (products.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Belum ada produk',
        subtitle: 'Tambahkan produk pertama untuk mulai berjualan.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        AppSpacing.md,
        AppSpacing.pageH,
        AppSpacing.xxl + 60, // space for floating button
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.gridGap,
        mainAxisSpacing: AppSpacing.gridGap,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) => _ProductCard(
        product: products[i],
        isDark: isDark,
        onTap: () {
          ref.read(cartProvider.notifier).addProduct(products[i]);
          // Light haptic feedback — premium feel
          HapticFeedback.lightImpact();
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final activeBg = isDark ? AppColors.champagneGold : AppColors.charcoal;
    final inactiveBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isSelected ? activeBg : inactiveColor,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonSmall.copyWith(
            color: isSelected
                ? (isDark ? AppColors.obsidian : Colors.white)
                : (isDark ? AppColors.darkTextSecondary : AppColors.ashGray),
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: border, width: 1),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.04),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / placeholder
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg),
                ),
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, _, _) => _Placeholder(isDark: isDark),
                      )
                    : _Placeholder(isDark: isDark),
              ),
            ),
            // Name + price
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyHelper.format(product.price),
                    style: AppTextStyles.price.copyWith(
                      color: isDark
                          ? AppColors.champagneGold
                          : AppColors.brushedGold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final bool isDark;
  const _Placeholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: isDark ? AppColors.darkBorder : AppColors.platinum,
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.isDark,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Cart Sidebar (tablet / large screen)
// ─────────────────────────────────────────────
class _CartSidebar extends ConsumerWidget {
  final List<CartItem> cart;
  final int subtotal;
  final VoidCallback onCheckout;

  const _CartSidebar({
    required this.cart,
    required this.subtotal,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: border, width: 1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PESANAN',
                  style: AppTextStyles.label.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.ashGray,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(cartProvider.notifier).clear(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    foregroundColor: AppColors.danger,
                  ),
                  child: Text(
                    'Hapus',
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (_, i) => _CartRow(item: cart[i], isDark: isDark),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: AppTextStyles.bodyMedium),
                    Text(
                      CurrencyHelper.format(subtotal),
                      style: AppTextStyles.priceTotal.copyWith(
                        fontSize: 16,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onCheckout,
                    child: Text('Checkout', style: AppTextStyles.button),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartRow extends ConsumerWidget {
  final CartItem item;
  final bool isDark;

  const _CartRow({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  CurrencyHelper.format(item.product.price),
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.champagneGold
                        : AppColors.brushedGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _QtyControl(item: item, isDark: isDark),
        ],
      ),
    );
  }
}

class _QtyControl extends ConsumerWidget {
  final CartItem item;
  final bool isDark;
  const _QtyControl({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QtyBtn(
          icon: Icons.remove,
          isDark: isDark,
          onTap: () =>
              ref.read(cartProvider.notifier).decrement(item.product.id),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '${item.qty}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _QtyBtn(
          icon: Icons.add,
          isDark: isDark,
          onTap: () =>
              ref.read(cartProvider.notifier).increment(item.product.id),
        ),
      ],
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
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Icon(icon, size: 14,
          color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Floating checkout bar (phone)
// ─────────────────────────────────────────────
class _FloatingCartButton extends StatelessWidget {
  final int count;
  final int subtotal;
  final VoidCallback onTap;

  const _FloatingCartButton({
    required this.count,
    required this.subtotal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.champagneGold : AppColors.charcoal;
    final fg = isDark ? AppColors.obsidian : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageH),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Lihat Pesanan',
                  style: AppTextStyles.button.copyWith(color: fg),
                ),
              ),
              Text(
                CurrencyHelper.format(subtotal),
                style: AppTextStyles.priceTotal.copyWith(
                  fontSize: 15,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
