class CategoryModel {
  final String id;
  final String tenantId;
  final String name;
  final String? description;
  final int orderIndex;

  const CategoryModel({
    required this.id,
    required this.tenantId,
    required this.name,
    this.description,
    this.orderIndex = 0,
  });

  static List<CategoryModel> mockList = [
    const CategoryModel(id: 'cat_1', tenantId: 't1', name: 'Klasik Kopi', orderIndex: 0),
    const CategoryModel(id: 'cat_2', tenantId: 't1', name: 'Non-Kopi', orderIndex: 1),
    const CategoryModel(id: 'cat_3', tenantId: 't1', name: 'Makanan', orderIndex: 2),
    const CategoryModel(id: 'cat_4', tenantId: 't1', name: 'Minuman Segar', orderIndex: 3),
  ];
}

class ProductModel {
  final String id;
  final String tenantId;
  final String categoryId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int? stock;
  final bool isActive;

  const ProductModel({
    required this.id,
    required this.tenantId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.stock,
    this.isActive = true,
  });

  bool get isOutOfStock => stock != null && stock! <= 0;

  static List<ProductModel> mockList = [
    const ProductModel(id: 'p1', tenantId: 't1', categoryId: 'cat_1', name: 'Americano', price: 25000),
    const ProductModel(id: 'p2', tenantId: 't1', categoryId: 'cat_1', name: 'Cappuccino', price: 28000),
    const ProductModel(id: 'p3', tenantId: 't1', categoryId: 'cat_1', name: 'Latte', price: 30000),
    const ProductModel(id: 'p4', tenantId: 't1', categoryId: 'cat_1', name: 'Espresso', price: 22000),
    const ProductModel(id: 'p5', tenantId: 't1', categoryId: 'cat_1', name: 'Cold Brew', price: 32000),
    const ProductModel(id: 'p6', tenantId: 't1', categoryId: 'cat_2', name: 'Matcha Latte', price: 28000),
    const ProductModel(id: 'p7', tenantId: 't1', categoryId: 'cat_2', name: 'Teh Tarik', price: 18000),
    const ProductModel(id: 'p8', tenantId: 't1', categoryId: 'cat_2', name: 'Susu Segar', price: 15000, stock: 0),
    const ProductModel(id: 'p9', tenantId: 't1', categoryId: 'cat_3', name: 'Croissant', price: 22000),
    const ProductModel(id: 'p10', tenantId: 't1', categoryId: 'cat_3', name: 'Roti Bakar', price: 18000),
    const ProductModel(id: 'p11', tenantId: 't1', categoryId: 'cat_3', name: 'Sandwich', price: 35000),
    const ProductModel(id: 'p12', tenantId: 't1', categoryId: 'cat_4', name: 'Es Lemon', price: 15000),
  ];
}
