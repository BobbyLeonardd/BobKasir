import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/product.dart';
import '../../data/product_repository.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  /// When [product] is non-null the form edits it; otherwise it creates one.
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _costController;
  late final TextEditingController _skuController;
  late final TextEditingController _descController;
  late bool _isActive;
  bool _isSaving = false;
  String? _selectedCategoryId;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController =
        TextEditingController(text: p != null ? p.price.toString() : '');
    _costController =
        TextEditingController(text: p?.cost != null ? '${p!.cost}' : '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _isActive = p?.isActive ?? true;
    _selectedCategoryId =
        (p?.categoryId.isNotEmpty ?? false) ? p!.categoryId : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _skuController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(productRepositoryProvider).saveProduct(
            id: widget.product?.id,
            name: _nameController.text.trim(),
            price: int.tryParse(_priceController.text) ?? 0,
            cost: _costController.text.trim().isEmpty
                ? null
                : int.tryParse(_costController.text),
            categoryId: _selectedCategoryId,
            sku: _skuController.text.trim().isEmpty
                ? null
                : _skuController.text.trim(),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            isActive: _isActive,
          );
      // Refresh catalog so cashier & list reflect the change.
      ref.invalidate(productCatalogProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit ? 'Produk diperbarui' : 'Produk ditambahkan'),
      ));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan produk: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = ref.watch(productCatalogProvider).maybeWhen(
          data: (c) => c.categories,
          orElse: () => const <Category>[],
        );
    // Guard: only keep the selected id if it exists in the loaded categories.
    final effectiveCategoryId =
        categories.any((c) => c.id == _selectedCategoryId)
            ? _selectedCategoryId
            : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageH,
          vertical: AppSpacing.pageV,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image upload placeholder (upload = follow-up)
              Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 36,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.ashGray,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('Foto produk (segera hadir)',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Nama Produk',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Category dropdown — populated from the live catalog.
              DropdownButtonFormField<String?>(
                initialValue: effectiveCategoryId,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tanpa kategori'),
                  ),
                  ...categories.map(
                    (c) => DropdownMenuItem<String?>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Harga Jual',
                hint: 'Contoh: 25000',
                controller: _priceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    v == null || v.isEmpty ? 'Harga wajib diisi' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Modal (Opsional)',
                controller: _costController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'SKU (Opsional)',
                controller: _skuController,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),

              AppTextField(
                label: 'Keterangan (Opsional)',
                controller: _descController,
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),

              Container(
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Tampilkan di Kasir',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Nonaktif = tidak tampil di kasir',
                    style: AppTextStyles.bodySmall,
                  ),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeThumbColor:
                      isDark ? AppColors.champagneGold : AppColors.charcoal,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Simpan Produk',
                onPressed: _save,
                isLoading: _isSaving,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
