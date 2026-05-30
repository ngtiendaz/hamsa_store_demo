class DashboardProductStatModel {
  final String id;
  final String name;
  final int? stock;
  final int? quantitySold;
  final double? revenue;
  final String? imageUrl;

  const DashboardProductStatModel({
    required this.id,
    required this.name,
    this.stock,
    this.quantitySold,
    this.revenue,
    this.imageUrl,
  });

  factory DashboardProductStatModel.fromJson(Map<String, dynamic> json) {
    return DashboardProductStatModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Sản phẩm',
      stock: (json['stock'] as num?)?.toInt(),
      quantitySold: (json['quantity_sold'] as num?)?.toInt(),
      revenue: (json['revenue'] as num?)?.toDouble(),
      imageUrl: json['image_url'] as String?,
    );
  }
}

class AdminDashboardStatsModel {
  final String period;
  final DateTime referenceDate;
  final DateTime startAt;
  final DateTime endAt;
  final double revenue;
  final int shippingCount;
  final int cancelledCount;
  final int deliveredCount;
  final int refundedCount;
  final double refundedAmount;
  final double returnRate;
  final double deliverySuccessRate;
  final List<DashboardProductStatModel> lowStockProducts;
  final List<DashboardProductStatModel> topSellingProducts;

  const AdminDashboardStatsModel({
    required this.period,
    required this.referenceDate,
    required this.startAt,
    required this.endAt,
    required this.revenue,
    required this.shippingCount,
    required this.cancelledCount,
    required this.deliveredCount,
    required this.refundedCount,
    required this.refundedAmount,
    required this.returnRate,
    required this.deliverySuccessRate,
    required this.lowStockProducts,
    required this.topSellingProducts,
  });

  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatsModel(
      period: json['period'] as String? ?? 'month',
      referenceDate: DateTime.parse(json['reference_date'] as String),
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      shippingCount: (json['shipping_count'] as num?)?.toInt() ?? 0,
      cancelledCount: (json['cancelled_count'] as num?)?.toInt() ?? 0,
      deliveredCount: (json['delivered_count'] as num?)?.toInt() ?? 0,
      refundedCount: (json['refunded_count'] as num?)?.toInt() ?? 0,
      refundedAmount: (json['refunded_amount'] as num?)?.toDouble() ?? 0,
      returnRate: (json['return_rate'] as num?)?.toDouble() ?? 0,
      deliverySuccessRate:
          (json['delivery_success_rate'] as num?)?.toDouble() ?? 0,
      lowStockProducts: _parseProducts(json['low_stock_products']),
      topSellingProducts: _parseProducts(json['top_selling_products']),
    );
  }

  static List<DashboardProductStatModel> _parseProducts(dynamic value) {
    if (value is! List) return const [];

    return value
        .map(
          (item) =>
              DashboardProductStatModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }
}
