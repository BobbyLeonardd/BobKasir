import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/helpers/currency_helper.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../products/domain/product.dart';
import '../../data/product_repository.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        bottom: TabBar(
          controller: _tabController,
          labelStyle: AppTextStyles.buttonSmall,
          labelColor: isDark ? AppColors.champagneGold : AppColors.charcoal,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.ashGray,
          indicatorColor:
              isDark ? AppColors.champagneGold : AppColors.charcoal,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: border,
          tabs: const [
            Tab(text: 'Produk'),
            Tab(text: 'Kategori'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.productForm),
        backgroundColor:
            isDark ? AppColors.champagneGold : AppColors.charcoal,
        child: Icon(
          Icons.add,
          color: isDark ? AppColors.obsidian : Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProductList(isDark: isDark),
          _CategoryList(isDark: isDark),
        ],
      ),
    );
  }
}

class _ProductList extends ConsumerWidget {
  final bool isDark;
  const _ProductList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(productCatalogProvider);
    return catalogAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => _CatalogError(
        isDark: isDark,
        onRetry: () => ref.invalidate(productCatalogProvider),
      ),
      data: (catalog) {
        final products = catalog.products;
        if (products.isEmpty) {
          return EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Belum ada produk',
            subtitle: 'Tambahkan produk pertama untuk mulai berjualan.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(productCatalogProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageH,
              vertical: AppSpacing.md,
            ),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _ProductListTile(
              product: products[i],
              isDark: isDark,
            ),
          ),
        );
      },
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final Product product;
  final bool isDark;

  const _ProductListTile({required this.product, required this.isDark});

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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            Icons.image_outlined,
            color: isDark ? AppColors.darkBorder : AppColors.platinum,
            size: 20,
          ),
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyHelper.format(product.price),
              style: AppTextStyles.price.copyWith(
                color: isDark
                    ? AppColors.champagneGold
                    : AppColors.brushedGold,
              ),
            ),
            if (!product.isActive)
              const StatusBadge(label: 'Nonaktif', type: BadgeType.neutral),
          ],
        ),
        onTap: () => context.push(AppRoutes.productForm, extra: product),
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final bool isDark;
  const _CategoryList({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(productCatalogProvider);
    return catalogAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => _CatalogError(
        isDark: isDark,
        onRetry: () => ref.invalidate(productCatalogProvider),
      ),
      data: (catalog) {
        final cats = catalog.categories.where((c) => c.id != 'all').toList();
        if (cats.isEmpty) {
          return EmptyState(
            icon: Icons.label_outline,
            title: 'Belum ada kategori',
            subtitle: 'Buat kategori untuk mengelompokkan produk.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageH,
            vertical: AppSpacing.md,
          ),
          itemCount: cats.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final cat = cats[i];
            final bg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
            final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
            return Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: border),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.label_outline,
                  color:
                      isDark ? AppColors.champagneGold : AppColors.brushedGold,
                ),
                title: Text(
                  cat.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}

class _CatalogError extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRetry;
  const _CatalogError({required this.isDark, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 40,
              color: isDark ? AppColors.darkTextSecondary : AppColors.ashGray),
          const SizedBox(height: AppSpacing.sm),
          Text('Gagal memuat data',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.ashGray,
              )),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
