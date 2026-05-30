import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class CustomerOrderListView extends StatelessWidget {
  const CustomerOrderListView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.detail),
          SizedBox(height: 12),
          Text('Danh sách đơn hàng sẽ được cập nhật ở bước tiếp theo.'),
        ],
      ),
    );
  }
}
