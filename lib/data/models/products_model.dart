class ProductModel {
  final String id;
  final String categoryId;
  final String brandId;
  final String internalName;
  final String? tradeName;
  final String? barcode;
  final String? description;
  final double price;
  final int stock;
  final String status; // 'active', 'inactive'
  final bool isFeatured;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> imageUrls;

  ProductModel({
    required this.id,
    required this.categoryId,
    required this.brandId,
    required this.internalName,
    this.tradeName,
    this.barcode,
    this.description,
    required this.price,
    required this.stock,
    required this.status,
    required this.isFeatured,
    this.createdBy,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrls = const [],
  });

  bool get isActive => status == 'active';
  String get displayName => tradeName ?? internalName;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<String> urls = [];
    if (json['product_images'] != null) {
      final images = json['product_images'] as List;
      urls = images.map((img) => img['image_url'] as String).toList();
    }

    return ProductModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      brandId: json['brand_id'] as String,
      internalName: json['internal_name'] as String,
      tradeName: json['trade_name'] as String?,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.parse(json['price'].toString()),
      stock: json['stock'] as int,
      status: json['status'] as String? ?? 'active',
      isFeatured: json['is_featured'] as bool? ?? false,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      deletedBy: json['deleted_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      imageUrls: urls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'brand_id': brandId,
      'internal_name': internalName,
      'trade_name': tradeName,
      'barcode': barcode,
      'description': description,
      'price': price,
      'stock': stock,
      'status': status,
      'is_featured': isFeatured,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'deleted_at': deletedAt?.toIso8601String(),
      'deleted_by': deletedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? id,
    String? categoryId,
    String? brandId,
    String? internalName,
    String? tradeName,
    String? barcode,
    String? description,
    double? price,
    int? stock,
    String? status,
    bool? isFeatured,
    String? createdBy,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? imageUrls,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      internalName: internalName ?? this.internalName,
      tradeName: tradeName ?? this.tradeName,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrls: imageUrls ?? this.imageUrls,
    );
  }
}
