import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../data/models/order_model.dart';
import '../../../user/auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/admin_order_list_view_model.dart';

class AdminOrderDetailView extends StatelessWidget {
  final OrderModel order;

  const AdminOrderDetailView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final profile = authVM.currentProfile;

    if (profile == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Vui lòng đăng nhập.')),
      );
    }

    final isSystemAdmin = profile.isAdmin;

    return Consumer<AdminOrderListViewModel>(
      builder: (context, viewModel, child) {
        // Đồng bộ lại thông tin đơn hàng đang chọn nếu danh sách cập nhật
        final currentOrder = viewModel.orders.firstWhere(
          (o) => o.id == order.id,
          orElse: () => order,
        );

        final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
        final double amountPaid = currentOrder.paymentStatus == 'paid' ? currentOrder.totalAmount : 0.0;
        final double amountDue = currentOrder.paymentStatus == 'unpaid' ? currentOrder.totalAmount : 0.0;

        final infoSection = _OrderDetailSection(
          title: 'Thông tin chung',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Mã đơn hàng', currentOrder.orderCode),
              _buildInfoRow('Ngày đặt', dateFormat.format(currentOrder.createdAt)),
              _buildInfoRow('Phương thức thanh toán', currentOrder.paymentMethod == 'wallet' ? 'Ví HamsaPay' : 'COD'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trạng thái đơn hàng', style: TextStyle(color: AppColors.detail, fontSize: 14)),
                  _buildStatusBadge(currentOrder),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trạng thái thanh toán', style: TextStyle(color: AppColors.detail, fontSize: 14)),
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
          title: 'Khách hàng',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Họ và tên', currentOrder.customerName),
              _buildInfoRow('Số điện thoại', currentOrder.customerPhone ?? 'Không có'),
              _buildInfoRow('Địa chỉ nhận hàng', currentOrder.customerAddress ?? 'Không có'),
              _buildInfoRow('Ghi chú', currentOrder.note != null && currentOrder.note!.trim().isNotEmpty ? currentOrder.note! : 'Không có'),
            ],
          ),
        );

        final itemsSection = _OrderDetailSection(
          title: 'Danh sách sản phẩm (${currentOrder.items.length})',
          child: Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: currentOrder.items.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, idx) {
                  final item = currentOrder.items[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productNameSnapshot,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Đơn giá: ${currencyFormat.format(item.priceSnapshot)}', style: const TextStyle(color: AppColors.detail, fontSize: 13)),
                            Text('Số lượng: ${item.quantity}', style: const TextStyle(color: AppColors.detail, fontSize: 13)),
                            Text('Thành tiền: ${currencyFormat.format(item.subtotal)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              _buildInfoRow('Tổng tiền hàng', currencyFormat.format(currentOrder.totalAmount)),
              _buildInfoRow('Đã thanh toán', currencyFormat.format(amountPaid), valueColor: Colors.green),
              _buildInfoRow('Cần thanh toán', currencyFormat.format(amountDue), valueColor: AppColors.error, isBoldValue: true),
            ],
          ),
        );

        final actionsSection = _OrderDetailSection(
          title: 'Thao tác nghiệp vụ',
          child: _buildDetailActionButtons(context, currentOrder, profile.id, isSystemAdmin, viewModel),
        );

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: null, // Sẽ dùng Top Bar / AppBar của MainLayout để tránh lặp giao diện
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

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
                            itemsSection,
                            const SizedBox(height: 20),
                            actionsSection,
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
                    itemsSection,
                    const SizedBox(height: 16),
                    actionsSection,
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.detail, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBoldValue ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? AppColors.onSurface,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderModel order) {
    Color color;
    switch (order.status) {
      case 'pending_confirmation':
        color = Colors.orange;
        break;
      case 'cancel_requested':
        color = Colors.redAccent;
        break;
      case 'shipping':
        color = Colors.indigo;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.grey;
        break;
      case 'return_requested':
        color = Colors.amber;
        break;
      case 'returned':
        color = Colors.purple;
        break;
      default:
        color = AppColors.detail;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        order.statusLabel,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDetailActionButtons(
    BuildContext context,
    OrderModel order,
    String adminId,
    bool isAdminUser,
    AdminOrderListViewModel viewModel,
  ) {
    if (order.status == 'pending_confirmation') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            text: 'Xác nhận giao hàng',
            onPressed: () => _confirmDelivery(context, order.id, adminId, viewModel),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _cancelPendingOrder(context, order.id, adminId, viewModel),
            child: const Text('Hủy đơn hàng', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    if (order.status == 'cancel_requested') {
      if (isAdminUser) {
        return AppButton(
          text: 'Đồng ý hủy đơn',
          onPressed: () => _approveCancel(context, order.id, adminId, viewModel),
        );
      } else {
        return const Center(
          child: Text(
            'Chỉ có quản trị viên mới được quyền phê duyệt hủy đơn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        );
      }
    }

    if (order.status == 'shipping') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _deliverSuccess(context, order.id, adminId, viewModel),
            child: const Text('Giao thành công', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _deliverFailed(context, order.id, adminId, viewModel),
            child: const Text('Giao thất bại', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    if (order.status == 'return_requested') {
      if (isAdminUser) {
        return AppButton(
          text: 'Đồng ý đổi trả / Hoàn tiền',
          onPressed: () => _approveReturn(context, order.id, adminId, viewModel),
        );
      } else {
        return const Center(
          child: Text(
            'Chỉ có quản trị viên mới được quyền phê duyệt đổi trả.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        );
      }
    }

    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Đơn hàng đã hoàn thành vòng đời và không thể thao tác thêm.',
          style: TextStyle(color: AppColors.detail, fontStyle: FontStyle.italic, fontSize: 13),
        ),
      ),
    );
  }

  Future<void> _confirmDelivery(
    BuildContext context,
    String orderId,
    String adminId,
    AdminOrderListViewModel viewModel,
  ) async {
    final success = await viewModel.confirmOrder(orderId, adminId);
    if (context.mounted) {
      if (success) {
        AppToast.showSuccess(context, 'Đã xác nhận giao hàng cho đơn hàng.');
      } else if (viewModel.errorMessage != null) {
        AppToast.showError(context, viewModel.errorMessage!);
      }
    }
  }

  Future<void> _cancelPendingOrder(
    BuildContext context,
    String orderId,
    String adminId,
    AdminOrderListViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy đơn hàng'),
        content: const Text('Bạn có chắc chắn muốn hủy đơn hàng này? Thao tác này sẽ hoàn tiền và hoàn trả số lượng sản phẩm vào kho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.cancelPending(orderId, adminId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(context, 'Hủy đơn hàng thành công.');
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text('Đồng ý hủy', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveCancel(
    BuildContext context,
    String orderId,
    String adminId,
    AdminOrderListViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Phê duyệt hủy đơn hàng'),
        content: const Text(
          'Đồng ý hủy đơn hàng này sẽ hoàn tiền lại vào ví HamsaPay của khách hàng (nếu có) và cộng lại số lượng vào kho. Bạn có chắc chắn muốn duyệt hủy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.approveCancel(orderId, adminId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(context, 'Đã phê duyệt hủy đơn hàng thành công.');
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text('Đồng ý hủy', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deliverSuccess(
    BuildContext context,
    String orderId,
    String adminId,
    AdminOrderListViewModel viewModel,
  ) async {
    final success = await viewModel.deliverOrderSuccess(orderId, adminId);
    if (context.mounted) {
      if (success) {
        AppToast.showSuccess(context, 'Cập nhật trạng thái Giao hàng thành công.');
      } else if (viewModel.errorMessage != null) {
        AppToast.showError(context, viewModel.errorMessage!);
      }
    }
  }

  Future<void> _deliverFailed(
    BuildContext context,
    String orderId,
    String adminId,
    AdminOrderListViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đánh dấu giao hàng thất bại'),
        content: const Text('Xác nhận giao hàng thất bại? Đơn hàng sẽ bị hủy, hoàn trả sản phẩm vào kho và hoàn tiền ví (nếu thanh toán qua ví).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.deliverOrderFailed(orderId, adminId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(context, 'Cập nhật trạng thái Giao hàng thất bại.');
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text('Xác nhận thất bại', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _approveReturn(
    BuildContext context,
    String orderId,
    String adminId,
    AdminOrderListViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đồng ý đổi trả / Hoàn tiền'),
        content: const Text('Duyệt nhận lại hàng và hoàn trả tiền vào ví (nếu đã thanh toán) cho khách hàng? Thao tác này cũng hoàn trả tồn kho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.approveReturn(orderId, adminId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(context, 'Đã duyệt nhận lại hàng và hoàn tiền thành công.');
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text('Đồng ý', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
