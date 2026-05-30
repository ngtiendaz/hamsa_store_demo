import 'order_item_model.dart';

class OrderModel {
  final String id;
  final String orderCode;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String? customerAddress;
  final String status; // 'pending_confirmation', 'confirmed', 'shipping', 'delivered', 'delivery_failed', 'cancelled', 'return_requested', 'returned'
  final double totalAmount;
  final String? note;
  final String paymentMethod; // 'wallet', 'cash', 'bank_transfer'
  final String paymentStatus; // 'unpaid', 'paid', 'refunded', 'partially_refunded'
  final String? createdBy;
  final String? confirmedBy;
  final String? shippedBy;
  final String? completedBy;
  final String? cancelledBy;
  final String? cancelledReason;
  final DateTime? confirmedAt;
  final DateTime? shippingAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerAddress,
    required this.status,
    required this.totalAmount,
    this.note,
    required this.paymentMethod,
    required this.paymentStatus,
    this.createdBy,
    this.confirmedBy,
    this.shippedBy,
    this.completedBy,
    this.cancelledBy,
    this.cancelledReason,
    this.confirmedAt,
    this.shippingAt,
    this.completedAt,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  bool get canCancel => status == 'pending_confirmation';

  String get statusLabel {
    switch (status) {
      case 'pending_confirmation':
        return 'Chờ xác nhận';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'shipping':
        return 'Đang giao hàng';
      case 'delivered':
        return 'Giao thành công';
      case 'delivery_failed':
        return 'Giao thất bại';
      case 'cancelled':
        return 'Đã hủy';
      case 'return_requested':
        return 'Yêu cầu trả hàng';
      case 'returned':
        return 'Đã trả hàng';
      default:
        return status;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['order_items'] as List? ?? [];
    return OrderModel(
      id: json['id'] as String,
      orderCode: json['order_code'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String,
      customerPhone: json['customer_phone'] as String?,
      customerAddress: json['customer_address'] as String?,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] is num)
          ? (json['total_amount'] as num).toDouble()
          : double.parse(json['total_amount'].toString()),
      note: json['note'] as String?,
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String,
      createdBy: json['created_by'] as String?,
      confirmedBy: json['confirmed_by'] as String?,
      shippedBy: json['shipped_by'] as String?,
      completedBy: json['completed_by'] as String?,
      cancelledBy: json['cancelled_by'] as String?,
      cancelledReason: json['cancelled_reason'] as String?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      shippingAt: json['shipping_at'] != null
          ? DateTime.parse(json['shipping_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: rawItems.map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'status': status,
      'total_amount': totalAmount,
      'note': note,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'created_by': createdBy,
      'confirmed_by': confirmedBy,
      'shipped_by': shippedBy,
      'completed_by': completedBy,
      'cancelled_by': cancelledBy,
      'cancelled_reason': cancelledReason,
      'confirmed_at': confirmedAt?.toIso8601String(),
      'shipping_at': shippingAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? orderCode,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? status,
    double? totalAmount,
    String? note,
    String? paymentMethod,
    String? paymentStatus,
    String? createdBy,
    String? confirmedBy,
    String? shippedBy,
    String? completedBy,
    String? cancelledBy,
    String? cancelledReason,
    DateTime? confirmedAt,
    DateTime? shippingAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItemModel>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      note: note ?? this.note,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdBy: createdBy ?? this.createdBy,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      shippedBy: shippedBy ?? this.shippedBy,
      completedBy: completedBy ?? this.completedBy,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledReason: cancelledReason ?? this.cancelledReason,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippingAt: shippingAt ?? this.shippingAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
