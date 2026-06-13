import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/local_db.dart';
import '../domain/product.dart';

/// Result of loading the catalog. [fromCache] is true when the server was
/// unreachable and we fell back to the local SQLite cache (offline mode).
class ProductCatalog {
  final List<Product> products;
  final List<Category> categories;
  final bool fromCache;

  const ProductCatalog({
    this.products = const [],
    this.categories = const [],
    this.fromCache = false,
  });
}

/// Maps between the API/local-DB shapes and the [Product]/[Category] models.
/// Kept pure (no I/O) so it can be unit-tested directly.
class ProductMapper {
  const ProductMapper._();

  static int _asInt(Object? v) => (v as num?)?.toInt() ?? 0;
  static int? _asIntOrNull(Object? v) => (v as num?)?.toInt();

  /// Server product JSON → [Product]. Server nests category/stock/image as
  /// relations, so flatten them here.
  static Product productFromApi(Map<String, dynamic> j) {
    final category = j['category'] as Map<String, dynamic>?;
    final stock = j['stock'] as Map<String, dynamic>?;
    final image = j['primary_image'] as Map<String, dynamic>?;
    return Product(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      categoryId: (j['category_id'] as String?) ?? '',
      categoryName: category?['name'] as String? ?? '',
      price: _asInt(j['price']),
      cost: _asIntOrNull(j['cost']),
      stock: _asIntOrNull(stock?['quantity']),
      sku: j['sku'] as String?,
      barcode: j['barcode'] as String?,
      imageUrl: (image?['url'] ?? image?['path'] ?? j['image_url']) as String?,
      description: j['description'] as String?,
      isActive: (j['is_active'] as bool?) ?? true,
    );
  }

  static Map<String, dynamic> productToDb(Product p) => {
        'id': p.id,
        'name': p.name,
        'category_id': p.categoryId,
        'category_name': p.categoryName,
        'price': p.price,
        'cost': p.cost,
        'stock': p.stock,
        'sku': p.sku,
        'image_url': p.imageUrl,
        'description': p.description,
        'is_active': p.isActive ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      };

  static Product productFromDb(Map<String, dynamic> r) => Product(
        id: r['id'] as String,
        name: r['name'] as String? ?? '',
        categoryId: r['category_id'] as String? ?? '',
        categoryName: r['category_name'] as String? ?? '',
        price: _asInt(r['price']),
        cost: _asIntOrNull(r['cost']),
        stock: _asIntOrNull(r['stock']),
        sku: r['sku'] as String?,
        imageUrl: r['image_url'] as String?,
        description: r['description'] as String?,
        isActive: (_asInt(r['is_active'])) == 1,
      );

  static Map<String, dynamic> categoryToDb(Category c) => {
        'id': c.id,
        'name': c.name,
        'sort_order': c.sortOrder,
        'is_active': c.isActive ? 1 : 0,
      };

  static Category categoryFromDb(Map<String, dynamic> r) => Category(
        id: r['id'] as String,
        name: r['name'] as String? ?? '',
        sortOrder: _asInt(r['sort_order']),
        isActive: (_asInt(r['is_active'])) == 1,
      );
}

abstract class ProductRepository {
  /// Offline-first: fetch from the server and refresh the cache; on any network
  /// failure, fall back to the locally cached catalog (PRD §26.1).
  Future<ProductCatalog> loadCatalog();

  /// Create (id == null) or update a product on the server.
  Future<void> saveProduct({
    String? id,
    required String name,
    required int price,
    int? cost,
    String? categoryId,
    String? sku,
    String? description,
    required bool isActive,
  });
}

class DefaultProductRepository implements ProductRepository {
  const DefaultProductRepository();

  @override
  Future<ProductCatalog> loadCatalog() async {
    try {
      final categories = await _fetchCategories();
      final products = await _fetchProducts();

      // Refresh local cache for offline use.
      await LocalDb.instance
          .cacheCategories(categories.map(ProductMapper.categoryToDb).toList());
      await LocalDb.instance
          .cacheProducts(products.map(ProductMapper.productToDb).toList());

      return ProductCatalog(
          products: products, categories: categories, fromCache: false);
    } catch (_) {
      return _loadFromCache();
    }
  }

  Future<List<Category>> _fetchCategories() async {
    final res = await DioClient.instance.dio.get('/categories');
    final data = res.data['data'];
    final list = data is List ? data : const [];
    return list
        .whereType<Map>()
        .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.isActive)
        .toList();
  }

  Future<List<Product>> _fetchProducts() async {
    final res = await DioClient.instance.dio.get('/products', queryParameters: {
      'per_page': 200,
    });
    final data = res.data['data'];
    // index() returns a paginator: { ..., data: [...] }
    final list = data is Map ? data['data'] : data;
    final items = list is List ? list : const [];
    return items
        .whereType<Map>()
        .map((e) => ProductMapper.productFromApi(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ProductCatalog> _loadFromCache() async {
    final catRows = await LocalDb.instance.getCachedCategories();
    final prodRows = await LocalDb.instance.getCachedProducts();
    return ProductCatalog(
      products: prodRows.map(ProductMapper.productFromDb).toList(),
      categories: catRows.map(ProductMapper.categoryFromDb).toList(),
      fromCache: true,
    );
  }

  @override
  Future<void> saveProduct({
    String? id,
    required String name,
    required int price,
    int? cost,
    String? categoryId,
    String? sku,
    String? description,
    required bool isActive,
  }) async {
    final data = {
      'name': name,
      'price': price,
      'cost': cost,
      'category_id': categoryId,
      'sku': sku,
      'description': description,
      'is_active': isActive,
    };
    final dio = DioClient.instance.dio;
    if (id == null) {
      await dio.post('/products', data: data);
    } else {
      await dio.put('/products/$id', data: data);
    }
  }
}

final productRepositoryProvider =
    Provider<ProductRepository>((ref) => const DefaultProductRepository());

/// Catalog for the cashier/products screens. Refresh with
/// `ref.invalidate(productCatalogProvider)`.
final productCatalogProvider = FutureProvider<ProductCatalog>((ref) async {
  return ref.read(productRepositoryProvider).loadCatalog();
});
