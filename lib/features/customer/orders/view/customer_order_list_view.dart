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

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<CustomerOrderListViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.orders.isEmpty) {
              return const AppLoading();
            }

            return Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.detail,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: 'Tất cả'),
                    Tab(text: 'Chờ xác nhận'),
                    Tab(text: 'Chờ xác nhận hủy'),
                    Tab(text: 'Đang giao'),
                    Tab(text: 'Đã giao'),
                    Tab(text: 'Đã hủy'),
                  ],
                ),
                const Divider(height: 1),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOrderList(context, viewModel, userId, null),
                      _buildOrderList(context, viewModel, userId, 'pending_confirmation'),
                      _buildOrderList(context, viewModel, userId, 'cancel_requested'),
                      _buildOrderList(context, viewModel, userId, 'shipping_or_confirmed'),
                      _buildOrderList(context, viewModel, userId, 'delivered'),
                      _buildOrderList(context, viewModel, userId, 'cancelled_or_failed'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(
    BuildContext context,
    CustomerOrderListViewModel viewModel,
    String userId,
    String? filterStatus,
  ) {
    final filteredOrders = viewModel.orders.where((order) {
      if (filterStatus == null) return true;
      if (filterStatus == 'shipping_or_confirmed') {
        return order.status == 'shipping' || order.status == 'confirmed';
      }
      if (filterStatus == 'cancelled_or_failed') {
        return order.status == 'cancelled' || order.status == 'delivery_failed';
      }
      return order.status == filterStatus;
    }).toList();

    if (filteredOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: const CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.detail),
                    SizedBox(height: 12),
                    Text('Không có đơn hàng nào.'),
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
        itemCount: filteredOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return _OrderCard(
            order: order,
            userId: userId,
            viewModel: viewModel,
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
    final double amountPaid = order.paymentStatus == 'paid' ? order.totalAmount : 0.0;
    final double amountDue = order.paymentStatus == 'unpaid' ? order.totalAmount : 0.0;

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
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final item = order.items[idx];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productNameSnapshot,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đơn giá: ${currencyFormat.format(item.priceSnapshot)}',
                          style: const TextStyle(color: AppColors.detail, fontSize: 13),
                        ),
                        Text(
                          'Số lượng: ${item.quantity}',
                          style: const TextStyle(color: AppColors.detail, fontSize: 13),
                        ),
                        Text(
                          'Thành tiền: ${currencyFormat.format(item.subtotal)}',
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ],
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
            const Divider(height: 24),

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Đã thanh toán: ${currencyFormat.format(amountPaid)}',
                      style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cần thanh toán: ${currencyFormat.format(amountDue)}',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Actions Buttons
            if (order.status == 'pending_confirmation' || order.status == 'cancel_requested' || order.status == 'delivered') ...[
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
                  if (order.status == 'delivered')
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showReturnDialog(context),
                      child: const Text('Yêu cầu đổi trả'),
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

  void _showReturnDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yêu cầu đổi trả đơn hàng'),
        content: const Text('Bạn có chắc chắn muốn gửi yêu cầu đổi trả cho đơn hàng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.requestReturn(order.id, userId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(context, 'Đã gửi yêu cầu đổi trả đơn hàng.');
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text('Gửi yêu cầu', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
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
