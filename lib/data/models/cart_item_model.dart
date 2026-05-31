import 'products_model.dart';

class CartItemModel {
  final String id;
  final String cartId;
  final String productId;
  final int quantity;
  final double priceSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final ProductModel? product;

  CartItemModel({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.priceSnapshot,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  double get subtotal => quantity * priceSnapshot;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as String,
      cartId: json['cart_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      priceSnapshot: (json['price_snapshot'] is num)
          ? (json['price_snapshot'] as num).toDouble()
          : double.parse(json['price_snapshot'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      product: json['products'] != null
          ? ProductModel.fromJson(json['products'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cart_id': cartId,
      'product_id': productId,
      'quantity': quantity,
      'price_snapshot': priceSnapshot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CartItemModel copyWith({
    String? id,
    String? cartId,
    String? productId,
    int? quantity,
    double? priceSnapshot,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProductModel? product,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      priceSnapshot: priceSnapshot ?? this.priceSnapshot,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
    );
  }
}
