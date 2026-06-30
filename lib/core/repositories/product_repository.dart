// ignore_for_file: use_null_aware_elements
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../models/product_model.dart';

final productRepositoryProvider =
    Provider((ref) => ProductRepository(ref.read(apiClientProvider)));

class ProductRepository {
  final ApiClient _api;
  ProductRepository(this._api);

  Future<List<CategoryModel>> getCategories() async {
    final resp = await _api.get('/categories');
    final list = resp.data['data'] as List;
    return list.map((j) => CategoryModel(
          id: j['id'].toString(),
          tenantId: j['tenant_id'].toString(),
          name: j['name'],
          description: j['description'],
          orderIndex: j['order_index'] ?? 0,
        )).toList();
  }

  Future<CategoryModel> createCategory(String name, {String? description, int orderIndex = 0}) async {
    final resp = await _api.post('/categories', data: {
      'name': name,
      if (description != null) 'description': description,
      'order_index': orderIndex,
    });
    final j = resp.data['data'];
    return CategoryModel(
      id: j['id'].toString(),
      tenantId: j['tenant_id'].toString(),
      name: j['name'],
      description: j['description'],
      orderIndex: j['order_index'] ?? 0,
    );
  }

  Future<void> updateCategory(String id, {String? name, String? description, int? orderIndex}) async {
    await _api.put('/categories/$id', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (orderIndex != null) 'order_index': orderIndex,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _api.delete('/categories/$id');
  }

  Future<List<ProductModel>> getProducts({String? categoryId, bool? isActive}) async {
    final resp = await _api.get('/products', params: {
      if (categoryId != null) 'category_id': categoryId,
      if (isActive != null) 'is_active': isActive ? '1' : '0',
    });
    final list = resp.data['data'] as List;
    return list.map((j) => _productFromJson(j as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> createProduct({
    required String name,
    required String price,
    String? categoryId,
    String? description,
    String? imagePath,
    int? stock,
    bool isActive = true,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'price': price,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (stock != null) 'stock': stock,
      'is_active': isActive ? '1' : '0',
      if (imagePath != null)
        'image': await MultipartFile.fromFile(imagePath),
    });
    final resp = await _api.postForm('/products', form);
    return _productFromJson(resp.data['data']);
  }

  Future<ProductModel> updateProduct(String id, {
    String? name,
    String? price,
    String? categoryId,
    String? description,
    String? imagePath,
    int? stock,
    bool? isActive,
  }) async {
    final form = FormData.fromMap({
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      if (stock != null) 'stock': stock,
      if (isActive != null) 'is_active': isActive ? '1' : '0',
      if (imagePath != null)
        'image': await MultipartFile.fromFile(imagePath),
      '_method': 'PUT', // Laravel method spoofing for multipart
    });
    final resp = await _api.postForm('/products/$id', form);
    return _productFromJson(resp.data['data']);
  }

  Future<void> deleteProduct(String id) async {
    await _api.delete('/products/$id');
  }

  ProductModel _productFromJson(Map<String, dynamic> j) {
    return ProductModel(
      id: j['id'].toString(),
      tenantId: j['tenant_id'].toString(),
      categoryId: j['category_id']?.toString() ?? '',
      name: j['name'],
      description: j['description'],
      price: (j['price'] as num).toDouble(),
      imageUrl: j['image_url'],
      stock: j['stock'],
      isActive: j['is_active'] == true || j['is_active'] == 1,
    );
  }
}
