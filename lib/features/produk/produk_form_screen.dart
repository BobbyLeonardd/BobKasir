import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/providers/app_providers.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/repositories/product_repository.dart';
import '../../core/services/api_client.dart';
import '../../core/models/product_model.dart';
import '../../core/utils/currency.dart';
import '../../widgets/app_button.dart';

class ProdukFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProdukFormScreen({super.key, this.productId});
  @override
  ConsumerState<ProdukFormScreen> createState() => _ProdukFormScreenState();
}

class _ProdukFormScreenState extends ConsumerState<ProdukFormScreen> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  String? _selectedCategoryId;
  bool _stockEnabled = false;
  bool _loading = false;
  File? _imageFile;
  String? _existingImageUrl;

  bool get _isEdit => widget.productId != null;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final product = (ref.read(productsProvider).value ?? [])
          .firstWhere((p) => p.id == widget.productId,
              orElse: () => ProductModel(id: '', tenantId: '', categoryId: '', name: '', price: 0));
      _nameCtrl.text = product.name;
      _priceCtrl.text = product.price.toInt().toString();
      _descCtrl.text = product.description ?? '';
      _selectedCategoryId = product.categoryId.isEmpty ? null : product.categoryId;
      if (product.stock != null) {
        _stockEnabled = true;
        _stockCtrl.text = product.stock!.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _priceCtrl.dispose(); _descCtrl.dispose(); _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _selectedCategoryId == null) return;
    setState(() => _loading = true);
    try {
      final price = parseRupiah(_priceCtrl.text).toStringAsFixed(0);
      final repo = ref.read(productRepositoryProvider);
      if (_isEdit) {
        await repo.updateProduct(
          widget.productId!,
          name: _nameCtrl.text.trim(),
          price: price,
          categoryId: _selectedCategoryId,
          description: _descCtrl.text.isEmpty ? null : _descCtrl.text.trim(),
          stock: _stockEnabled ? int.tryParse(_stockCtrl.text) : null,
          imagePath: _imageFile?.path,
        );
      } else {
        await repo.createProduct(
          name: _nameCtrl.text.trim(),
          price: price,
          categoryId: _selectedCategoryId,
          description: _descCtrl.text.isEmpty ? null : _descCtrl.text.trim(),
          stock: _stockEnabled ? int.tryParse(_stockCtrl.text) : null,
          imagePath: _imageFile?.path,
        );
      }
      ref.invalidate(productsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ApiClient.parseError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).value ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Produk' : 'Tambah Produk')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: AppColors.surface3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : _existingImageUrl != null
                          ? Image.network(_existingImageUrl!, fit: BoxFit.cover)
                          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.onSurface3),
                              SizedBox(height: 4),
                              Text('Upload Gambar', style: TextStyle(fontSize: 12, color: AppColors.onSurface3)),
                            ]),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nama Produk *')),
            const SizedBox(height: AppSpacing.s4),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Kategori *'),
              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga *', prefixText: 'Rp '),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Keterangan (opsional)')),
            const SizedBox(height: AppSpacing.s4),
            Row(children: [
              Switch(value: _stockEnabled, onChanged: (v) => setState(() => _stockEnabled = v)),
              const SizedBox(width: 8),
              const Text('Aktifkan Stok'),
            ]),
            if (_stockEnabled) ...[
              const SizedBox(height: AppSpacing.s3),
              TextField(controller: _stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah Stok')),
            ],
            const SizedBox(height: AppSpacing.s8),
            AppButton(label: 'Simpan', loading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
