class Product {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final int price;
  final int? cost;
  final int? stock;
  final String? sku;
  final String? barcode;
  final String? imageUrl;
  final String? description;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.price,
    this.cost,
    this.stock,
    this.sku,
    this.barcode,
    this.imageUrl,
    this.description,
    this.isActive = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryId: json['category_id'] as String,
        categoryName: json['category_name'] as String? ?? '',
        price: json['price'] as int,
        cost: json['cost'] as int?,
        stock: json['stock'] as int?,
        sku: json['sku'] as String?,
        barcode: json['barcode'] as String?,
        imageUrl: json['image_url'] as String?,
        description: json['description'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category_id': categoryId,
        'category_name': categoryName,
        'price': price,
        'cost': cost,
        'stock': stock,
        'sku': sku,
        'barcode': barcode,
        'image_url': imageUrl,
        'description': description,
        'is_active': isActive,
      };
}

class Category {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;
  final bool isActive;

  const Category({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
      );
}
