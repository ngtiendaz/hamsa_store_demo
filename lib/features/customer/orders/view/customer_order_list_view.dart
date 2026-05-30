import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../user/auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/customer_order_list_view_model.dart';

class CustomerOrderListView extends StatefulWidget {
  const CustomerOrderListView({super.key});

  @override
  State<CustomerOrderListView> createState() => _CustomerOrderListViewState();
}

class _CustomerOrderListViewState extends State<CustomerOrderListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  void _refresh() {
    final userId = context.read<AuthViewModel>().currentProfile?.id;
    if (userId != null) {
      context.read<CustomerOrderListViewModel>().loadOrders(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final userId = authVM.currentProfile?.id;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Vui lòng đăng nhập để xem đơn hàng.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<CustomerOrderListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.orders.isEmpty) {
            return const AppLoading();
          }

          if (viewModel.orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: const CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.detail),
                          SizedBox(height: 12),
                          Text('Bạn chưa có đơn hàng nào.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final order = viewModel.orders[index];
                return _OrderCard(
                  order: order,
                  userId: userId,
                  viewModel: viewModel,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order; // OrderModel
  final String userId;
  final CustomerOrderListViewModel viewModel;

  const _OrderCard({
    required this.order,
    required this.userId,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    Color statusColor;
    String statusText = order.statusLabel;

    switch (order.status) {
      case 'pending_confirmation':
        statusColor = Colors.orange;
        break;
      case 'cancel_requested':
        statusColor = Colors.redAccent;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        break;
      case 'shipping':
        statusColor = Colors.indigo;
        break;
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = AppColors.detail;
    }

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Code + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(order.createdAt),
                        style: const TextStyle(color: AppColors.detail, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Items List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final item = order.items[idx];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${item.productNameSnapshot} x${item.quantity}',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat.format(item.subtotal),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 24),

            // Shipping Info
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.detail),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Giao đến: ${order.customerAddress ?? "Chưa nhập địa chỉ"}',
                    style: const TextStyle(color: AppColors.detail, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (order.note != null && order.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.note_alt_outlined, size: 16, color: AppColors.detail),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ghi chú: ${order.note}',
                      style: const TextStyle(color: AppColors.detail, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // Footer: Payment Method + Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.paymentMethod == 'wallet'
                      ? 'Thanh toán qua HamsaPay'
                      : 'Thanh toán khi nhận hàng (COD)',
                  style: const TextStyle(color: AppColors.detail, fontSize: 13),
                ),
                Text(
                  currencyFormat.format(order.totalAmount),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Actions Buttons
            if (order.status == 'pending_confirmation' || order.status == 'cancel_requested') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == 'pending_confirmation')
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showCancelDialog(context),
                      child: const Text('Yêu cầu hủy'),
                    ),
                  if (order.status == 'cancel_requested')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _onWithdrawCancel(context),
                      child: const Text('Rút yêu cầu hủy'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yêu cầu hủy đơn hàng'),
        content: const Text('Bạn có chắc chắn muốn gửi yêu cầu hủy đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.requestCancel(order.id, userId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(context, 'Đã gửi yêu cầu hủy đơn hàng.');
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text('Gửi yêu cầu', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _onWithdrawCancel(BuildContext context) async {
    final success = await viewModel.cancelRequestCancel(order.id, userId);
    if (context.mounted) {
      if (success) {
        AppToast.showSuccess(context, 'Đã rút yêu cầu hủy đơn hàng.');
      } else if (viewModel.errorMessage != null) {
        AppToast.showError(context, viewModel.errorMessage!);
      }
    }
  }
}
