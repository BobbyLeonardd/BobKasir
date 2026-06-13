import 'package:flutter_test/flutter_test.dart';
import 'package:bobkasir/features/products/data/product_repository.dart';
import 'package:bobkasir/features/products/domain/product.dart';

/// The API nests category/stock/image as relations while the cache stores a
/// flat row. These mappers bridge both — and are the trickiest part of #1.
void main() {
  group('ProductMapper.productFromApi', () {
    test('flattens nested category, stock and image', () {
      final p = ProductMapper.productFromApi({
        'id': 'p1',
        'name': 'Latte',
        'category_id': 'c1',
        'price': 32000,
        'cost': 12000,
        'is_active': true,
        'sku': 'LT1',
        'category': {'id': 'c1', 'name': 'Minuman'},
        'stock': {'quantity': 7},
        'primary_image': {'url': 'http://img/latte.png'},
      });

      expect(p.id, 'p1');
      expect(p.name, 'Latte');
      expect(p.categoryId, 'c1');
      expect(p.categoryName, 'Minuman');
      expect(p.price, 32000);
      expect(p.cost, 12000);
      expect(p.stock, 7);
      expect(p.imageUrl, 'http://img/latte.png');
      expect(p.isActive, isTrue);
    });

    test('tolerates missing relations and null category', () {
      final p = ProductMapper.productFromApi({
        'id': 'p2',
        'name': 'Air Mineral',
        'category_id': null,
        'price': 5000,
      });

      expect(p.categoryId, '');
      expect(p.categoryName, '');
      expect(p.stock, isNull);
      expect(p.cost, isNull);
      expect(p.imageUrl, isNull);
      expect(p.isActive, isTrue); // default when omitted
    });
  });

  group('ProductMapper cache round-trip', () {
    test('product survives toDb/fromDb', () {
      const original = Product(
        id: 'p1',
        name: 'Latte',
        categoryId: 'c1',
        categoryName: 'Minuman',
        price: 32000,
        cost: 12000,
        stock: 5,
        isActive: false,
      );

      final restored =
          ProductMapper.productFromDb(ProductMapper.productToDb(original));

      expect(restored.id, 'p1');
      expect(restored.name, 'Latte');
      expect(restored.categoryName, 'Minuman');
      expect(restored.price, 32000);
      expect(restored.cost, 12000);
      expect(restored.stock, 5);
      expect(restored.isActive, isFalse);
    });

    test('category survives toDb/fromDb', () {
      const c = Category(id: 'c1', name: 'Minuman', sortOrder: 2, isActive: true);

      final restored =
          ProductMapper.categoryFromDb(ProductMapper.categoryToDb(c));

      expect(restored.id, 'c1');
      expect(restored.name, 'Minuman');
      expect(restored.sortOrder, 2);
      expect(restored.isActive, isTrue);
    });
  });
}
