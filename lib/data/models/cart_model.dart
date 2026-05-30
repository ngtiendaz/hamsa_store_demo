import 'cart_item_model.dart';

class CartModel {
  final String id;
  final String userId;
  final String status; // 'active', 'checked_out', 'abandoned'
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CartItemModel> items;

  CartModel({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.subtotal);
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  factory CartModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['cart_items'] as List? ?? [];
    return CartModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: rawItems.map((item) => CartItemModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CartModel copyWith({
    String? id,
    String? userId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CartItemModel>? items,
  }) {
    return CartModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
