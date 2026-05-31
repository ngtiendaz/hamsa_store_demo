import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../../../data/models/admin_dashboard_stats_model.dart';

class DashboardProductList extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<DashboardProductStatModel> products;
  final bool showStock;

  const DashboardProductList({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.products,
    required this.showStock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.detail,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu.',
                  style: TextStyle(color: AppColors.detail),
                ),
              ),
            )
          else
            ...products.indexed.map(
              (entry) => _ProductRow(
                rank: entry.$1 + 1,
                product: entry.$2,
                showStock: showStock,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final int rank;
  final DashboardProductStatModel product;
  final bool showStock;

  const _ProductRow({
    required this.rank,
    required this.product,
    required this.showStock,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: AppColors.detail,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppNetworkImage(
              imageUrl: product.imageUrl ?? '',
              width: 44,
              height: 44,
              borderRadius: 10,
              fit: BoxFit.cover,
              placeholder: Container(
                width: 44,
                height: 44,
                color: AppColors.surface,
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: AppColors.detail,
                ),
              ),
              errorWidget: Container(
                width: 44,
                height: 44,
                color: AppColors.surface,
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 20,
                  color: AppColors.detail,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!showStock) ...[
                  const SizedBox(height: 3),
                  Text(
                    currency.format(product.revenue ?? 0),
                    style: const TextStyle(
                      color: AppColors.detail,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            showStock
                ? '${product.stock ?? 0} còn lại'
                : '${product.quantitySold ?? 0} đã bán',
            style: TextStyle(
              color: showStock ? AppColors.error : AppColors.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
