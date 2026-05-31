import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/order_model.dart';
import '../../../login/auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/customer_order_list_view_model.dart';

class CustomerOrderDetailView extends StatelessWidget {
  final OrderModel order;

  const CustomerOrderDetailView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final userId = authVM.currentProfile?.id;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Vui lòng đăng nhập.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<CustomerOrderListViewModel>(
        builder: (context, viewModel, child) {
          final currentOrder = viewModel.orders.firstWhere(
            (o) => o.id == order.id,
            orElse: () => order,
          );

          final currencyFormat = NumberFormat.currency(
            locale: 'vi_VN',
            symbol: '₫',
          );
          final double amountPaid = currentOrder.paymentStatus == 'paid'
              ? currentOrder.totalAmount
              : 0.0;
          final double amountDue = currentOrder.paymentStatus == 'unpaid'
              ? currentOrder.totalAmount
              : 0.0;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              final infoSection = _OrderDetailSection(
                title: 'Thông tin chung',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Mã đơn hàng', currentOrder.orderCode),
                    _buildInfoRow(
                      'Ngày đặt',
                      formatVietnamDateTime(currentOrder.createdAt),
                    ),
                    _buildInfoRow(
                      'Phương thức thanh toán',
                      currentOrder.paymentMethod == 'wallet'
                          ? 'Ví HamsaPay'
                          : 'COD',
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trạng thái đơn hàng',
                          style: TextStyle(
                            color: AppColors.detail,
                            fontSize: 14,
                          ),
                        ),
                        _buildStatusBadge(currentOrder),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trạng thái thanh toán',
                          style: TextStyle(
                            color: AppColors.detail,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currentOrder.paymentStatus == 'paid'
                              ? 'Đã thu tiền'
                              : currentOrder.paymentStatus == 'refunded'
                              ? 'Đã hoàn tiền'
                              : 'Chưa thu tiền',
                          style: TextStyle(
                            color: currentOrder.paymentStatus == 'paid'
                                ? Colors.green
                                : currentOrder.paymentStatus == 'refunded'
                                ? Colors.blue
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final customerSection = _OrderDetailSection(
                title: 'Thông tin nhận hàng',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Họ và tên', currentOrder.customerName),
                    _buildInfoRow(
                      'Số điện thoại',
                      currentOrder.customerPhone ?? 'Không có',
                    ),
                    _buildInfoRow(
                      'Địa chỉ nhận hàng',
                      currentOrder.customerAddress ?? 'Không có',
                    ),
                    _buildInfoRow(
                      'Ghi chú',
                      currentOrder.note != null &&
                              currentOrder.note!.trim().isNotEmpty
                          ? currentOrder.note!
                          : 'Không có',
                    ),
                  ],
                ),
              );

              final productCard = _OrderDetailSection(
                title: 'Sản phẩm đã mua',
                child: Column(
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: currentOrder.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, idx) {
                        final item = currentOrder.items[idx];
                        final imgUrl = item.productImageUrl;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppNetworkImage(
                                imageUrl: imgUrl ?? '',
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                placeholder: Container(
                                  width: 64,
                                  height: 64,
                                  color: AppColors.surface,
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppColors.detail,
                                  ),
                                ),
                                errorWidget: Container(
                                  width: 64,
                                  height: 64,
                                  color: AppColors.surface,
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
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
                                    item.productNameSnapshot,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${currencyFormat.format(item.priceSnapshot)} x ${item.quantity}',
                                        style: const TextStyle(
                                          color: AppColors.detail,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(item.subtotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đã thanh toán',
                          style: TextStyle(
                            color: AppColors.detail,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(amountPaid),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Cần thanh toán',
                          style: TextStyle(
                            color: AppColors.detail,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          currencyFormat.format(amountDue),
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final actionsWidget = _buildDetailActionButtons(
                context,
                currentOrder,
                userId,
                viewModel,
              );

              if (isDesktop) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            infoSection,
                            const SizedBox(height: 20),
                            customerSection,
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            productCard,
                            if (actionsWidget is! SizedBox) ...[
                              const SizedBox(height: 20),
                              _OrderDetailSection(
                                title: '',
                                child: actionsWidget,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    infoSection,
                    const SizedBox(height: 16),
                    customerSection,
                    const SizedBox(height: 16),
                    productCard,
                    if (actionsWidget is! SizedBox) ...[
                      const SizedBox(height: 16),
                      _OrderDetailSection(title: '', child: actionsWidget),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.detail, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderModel order) {
    Color statusColor;
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
      case 'delivery_failed':
        statusColor = Colors.red;
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        break;
      case 'return_requested':
        statusColor = Colors.amber;
        break;
      case 'returned':
        statusColor = Colors.purple;
        break;
      default:
        statusColor = AppColors.detail;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailActionButtons(
    BuildContext context,
    OrderModel order,
    String userId,
    CustomerOrderListViewModel viewModel,
  ) {
    final status = order.status;
    if (status != 'pending_confirmation' &&
        status != 'cancel_requested' &&
        status != 'delivered' &&
        status != 'return_requested') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 'pending_confirmation') ...[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                _showUpdateDialog(context, order, viewModel, userId),
            child: const Text('Cập nhật thông tin nhận hàng'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                _showCancelDialog(context, order, viewModel, userId),
            child: const Text('Yêu cầu hủy đơn hàng'),
          ),
        ],
        if (status == 'cancel_requested')
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                _onWithdrawCancel(context, order, viewModel, userId),
            child: const Text('Rút yêu cầu hủy đơn hàng'),
          ),
        if (status == 'delivered')
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                _showReturnDialog(context, order, viewModel, userId),
            child: const Text('Yêu cầu đổi trả đơn hàng'),
          ),
        if (status == 'return_requested')
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                _showCancelReturnDialog(context, order, viewModel, userId),
            child: const Text('Hủy yêu cầu hoàn trả'),
          ),
      ],
    );
  }

  void _showUpdateDialog(
    BuildContext context,
    OrderModel order,
    CustomerOrderListViewModel viewModel,
    String userId,
  ) {
    final nameController = TextEditingController(text: order.customerName);
    final phoneController = TextEditingController(text: order.customerPhone);
    final addressController = TextEditingController(
      text: order.customerAddress,
    );
    final noteController = TextEditingController(text: order.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật thông tin nhận hàng'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  hintText: 'Nhập họ và tên người nhận',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: 'Nhập số điện thoại',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ giao hàng',
                  hintText: 'Nhập địa chỉ giao hàng',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Nhập ghi chú thêm (nếu có)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: AppColors.detail),
            ),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final address = addressController.text.trim();
              final note = noteController.text.trim();

              if (name.isEmpty || phone.isEmpty || address.isEmpty) {
                AppToast.showError(
                  context,
                  'Họ tên, SĐT và địa chỉ là bắt buộc.',
                );
                return;
              }

              Navigator.of(ctx).pop();
              final success = await viewModel.updateOrderInfo(
                orderId: order.id,
                userId: userId,
                customerName: name,
                customerPhone: phone,
                customerAddress: address,
                note: note,
              );
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(
                    context,
                    'Cập nhật thông tin đơn hàng thành công.',
                  );
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text(
              'Lưu lại',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    BuildContext context,
    OrderModel order,
    CustomerOrderListViewModel viewModel,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yêu cầu hủy đơn hàng'),
        content: const Text(
          'Bạn có chắc chắn muốn gửi yêu cầu hủy đơn hàng này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: AppColors.detail),
            ),
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
            child: const Text(
              'Gửi yêu cầu',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onWithdrawCancel(
    BuildContext context,
    OrderModel order,
    CustomerOrderListViewModel viewModel,
    String userId,
  ) async {
    final success = await viewModel.cancelRequestCancel(order.id, userId);
    if (context.mounted) {
      if (success) {
        AppToast.showSuccess(context, 'Đã rút yêu cầu hủy đơn hàng.');
      } else if (viewModel.errorMessage != null) {
        AppToast.showError(context, viewModel.errorMessage!);
      }
    }
  }

  void _showReturnDialog(
    BuildContext context,
    OrderModel order,
    CustomerOrderListViewModel viewModel,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yêu cầu đổi trả đơn hàng'),
        content: const Text(
          'Bạn có chắc chắn muốn gửi yêu cầu đổi trả cho đơn hàng này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: AppColors.detail),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.requestReturn(order.id, userId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(
                    context,
                    'Đã gửi yêu cầu đổi trả đơn hàng.',
                  );
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text(
              'Gửi yêu cầu',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelReturnDialog(
    BuildContext context,
    OrderModel order,
    CustomerOrderListViewModel viewModel,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy yêu cầu hoàn trả'),
        content: const Text(
          'Bạn có chắc chắn muốn hủy yêu cầu hoàn trả cho đơn hàng này để đưa về trạng thái giao thành công không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: AppColors.detail),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.cancelRequestReturn(
                order.id,
                userId,
              );
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(
                    context,
                    'Đã hủy yêu cầu hoàn trả thành công.',
                  );
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text(
              'Đồng ý',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _OrderDetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final hasTitle = title.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasTitle) ...[
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}
