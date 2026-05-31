class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productNameSnapshot;
  final String? barcodeSnapshot;
  final double priceSnapshot;
  final int quantity;
  final double subtotal;
  final DateTime createdAt;
  final String? productImageUrl;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productNameSnapshot,
    this.barcodeSnapshot,
    required this.priceSnapshot,
    required this.quantity,
    required this.subtotal,
    required this.createdAt,
    this.productImageUrl,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    String? imageUrl;
    if (json['products'] != null &&
        json['products']['product_images'] != null) {
      final list = json['products']['product_images'] as List;
      if (list.isNotEmpty) {
        imageUrl = list.first['image_url'] as String?;
      }
    }
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productNameSnapshot: json['product_name_snapshot'] as String,
      barcodeSnapshot: json['barcode_snapshot'] as String?,
      priceSnapshot: (json['price_snapshot'] is num)
          ? (json['price_snapshot'] as num).toDouble()
          : double.parse(json['price_snapshot'].toString()),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] is num)
          ? (json['subtotal'] as num).toDouble()
          : double.parse(json['subtotal'].toString()),
      createdAt: DateTime.parse(json['created_at'] as String),
      productImageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name_snapshot': productNameSnapshot,
      'barcode_snapshot': barcodeSnapshot,
      'price_snapshot': priceSnapshot,
      'quantity': quantity,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }

  OrderItemModel copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? productNameSnapshot,
    String? barcodeSnapshot,
    double? priceSnapshot,
    int? quantity,
    double? subtotal,
    DateTime? createdAt,
    String? productImageUrl,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      barcodeSnapshot: barcodeSnapshot ?? this.barcodeSnapshot,
      priceSnapshot: priceSnapshot ?? this.priceSnapshot,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      createdAt: createdAt ?? this.createdAt,
      productImageUrl: productImageUrl ?? this.productImageUrl,
    );
  }
}
