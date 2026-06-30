import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/product_model.dart';
import '../../core/utils/currency.dart';
import '../../widgets/empty_state.dart';

class ProdukScreen extends ConsumerStatefulWidget {
  const ProdukScreen({super.key});
  @override
  ConsumerState<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends ConsumerState<ProdukScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    final products = ref.watch(productsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Kategori'), Tab(text: 'Produk')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/produk/baru'),
            tooltip: '+ Produk',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Tab Kategori ──
          categories.isEmpty
              ? const EmptyState(icon: Icons.category_outlined, message: 'Belum ada kategori.')
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    return ListTile(
                      leading: const Icon(Icons.drag_handle, color: AppColors.onSurface3),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error), onPressed: () {}),
                      ]),
                    );
                  },
                ),
          // ── Tab Produk ──
          products.isEmpty
              ? EmptyState(icon: Icons.coffee_outlined, message: 'Belum ada produk.', actionLabel: '+ Tambah Produk', onAction: () => context.push('/produk/baru'))
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    final cat = (ref.read(categoriesProvider).value ?? []).firstWhere((c) => c.id == p.categoryId, orElse: () => CategoryModel(id: '', tenantId: '', name: '-'));
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                      leading: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)),
                        child: p.imageUrl != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(p.imageUrl!, fit: BoxFit.cover))
                            : const Icon(Icons.coffee, color: AppColors.onSurface3),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${cat.name}  •  ${formatRupiah(p.price)}', style: const TextStyle(fontSize: 13, color: AppColors.onSurface2)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (p.isOutOfStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(999)),
                            child: const Text('HABIS', style: TextStyle(color: AppColors.error, fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                        IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => context.push('/produk/${p.id}/edit')),
                        IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error), onPressed: () {}),
                      ]),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
