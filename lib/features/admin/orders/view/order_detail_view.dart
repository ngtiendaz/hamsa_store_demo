import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/models/order_item_model.dart';
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
        final double amountPaid = currentOrder.paymentStatus == 'paid' ? currentOrder.totalAmount : 0.0;
        final double amountDue = currentOrder.paymentStatus == 'unpaid' ? currentOrder.totalAmount : 0.0;

        Widget buildInfoLayout(bool isDesktop) {
          final infoList = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('THÔNG TIN ĐƠN HÀNG', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _buildInfoRow('Mã đơn hàng', currentOrder.orderCode),
              _buildInfoRow('Ngày đặt', formatVietnamDateTime(currentOrder.createdAt)),
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
          );

          final customerList = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('THÔNG TIN KHÁCH HÀNG', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _buildInfoRow('Họ và tên', currentOrder.customerName),
              _buildInfoRow('Số điện thoại', currentOrder.customerPhone ?? 'Không có'),
              _buildInfoRow('Địa chỉ nhận hàng', currentOrder.customerAddress ?? 'Không có'),
              _buildInfoRow('Ghi chú', currentOrder.note != null && currentOrder.note!.trim().isNotEmpty ? currentOrder.note! : 'Không có'),
            ],
          );

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: infoList),
                const SizedBox(width: 32),
                Expanded(child: customerList),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoList,
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                customerList,
              ],
            );
          }
        }

        final actionsWidget = _buildDetailActionButtons(context, currentOrder, profile.id, isSystemAdmin, viewModel);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: null, // Sẽ dùng Top Bar / AppBar của MainLayout để tránh lặp giao diện
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final hasActions = actionsWidget is! SizedBox;

              final infoSection = _OrderDetailSection(
                title: 'Thông tin chung & Khách hàng',
                child: buildInfoLayout(isDesktop),
              );

              final productCard = LayoutBuilder(
                builder: (context, pConstraints) {
                  final isCompact = pConstraints.maxWidth < 650;
                  if (isCompact) {
                    return _buildProductCompactList(currentOrder.items, currencyFormat, amountPaid, amountDue, currentOrder.totalAmount);
                  }
                  return _buildProductTable(currentOrder.items, currencyFormat, amountPaid, amountDue, currentOrder.totalAmount);
                },
              );

              if (isDesktop) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: hasActions ? 7 : 10,
                        child: Column(
                          children: [
                            infoSection,
                            const SizedBox(height: 20),
                            productCard,
                          ],
                        ),
                      ),
                      if (hasActions) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: _OrderDetailSection(
                            title: 'Thao tác nghiệp vụ',
                            child: actionsWidget,
                          ),
                        ),
                      ],
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
                    productCard,
                    if (hasActions) ...[
                      const SizedBox(height: 16),
                      _OrderDetailSection(
                        title: 'Thao tác nghiệp vụ',
                        child: actionsWidget,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductImage(String? url) {
    final placeholder = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.detail, size: 24),
    );

    if (url == null || url.trim().isEmpty) {
      return placeholder;
    }

    return AppNetworkImage(
      imageUrl: url,
      width: 48,
      height: 48,
      borderRadius: 8,
      fit: BoxFit.cover,
      placeholder: placeholder,
      errorWidget: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.broken_image_outlined, color: AppColors.detail, size: 24),
      ),
    );
  }

  Widget _buildProductTable(
    List<OrderItemModel> items,
    NumberFormat currencyFormat,
    double amountPaid,
    double amountDue,
    double totalAmount,
  ) {
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
              'Danh sách sản phẩm (${items.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const Divider(height: 24),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(64), // Ảnh
                1: FlexColumnWidth(3.0), // Tên
                2: FlexColumnWidth(1.5), // Mã
                3: FlexColumnWidth(1.5), // Giá
                4: FlexColumnWidth(1.0), // Số lượng
                5: FlexColumnWidth(1.8), // Thành tiền
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Header row
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  children: const [
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Ảnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Mã', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Giá', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center)),
                    Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Thành tiền', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right)),
                  ],
                ),
                // Data rows
                ...items.map((item) {
                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: _buildProductImage(item.productImageUrl),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Text(item.productNameSnapshot, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(item.barcodeSnapshot ?? 'N/A', style: const TextStyle(fontSize: 13, color: AppColors.detail)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(currencyFormat.format(item.priceSnapshot), style: const TextStyle(fontSize: 13)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('${item.quantity}', style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(currencyFormat.format(item.subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow('Tổng tiền hàng', currencyFormat.format(totalAmount)),
            _buildInfoRow('Đã thanh toán', currencyFormat.format(amountPaid), valueColor: Colors.green),
            _buildInfoRow('Cần thanh toán', currencyFormat.format(amountDue), valueColor: AppColors.error, isBoldValue: true),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCompactList(
    List<OrderItemModel> items,
    NumberFormat currencyFormat,
    double amountPaid,
    double amountDue,
    double totalAmount,
  ) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh sách sản phẩm (${items.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const Divider(height: 20),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final item = items[idx];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProductImage(item.productImageUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productNameSnapshot,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text('Mã: ${item.barcodeSnapshot ?? "N/A"}', style: const TextStyle(color: AppColors.detail, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Giá: ${currencyFormat.format(item.priceSnapshot)}', style: const TextStyle(fontSize: 13)),
                              Text('SL: ${item.quantity}', style: const TextStyle(fontSize: 13)),
                              Text('Thành tiền: ${currencyFormat.format(item.subtotal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const Divider(height: 24),
            _buildInfoRow('Tổng tiền hàng', currencyFormat.format(totalAmount)),
            _buildInfoRow('Đã thanh toán', currencyFormat.format(amountPaid), valueColor: Colors.green),
            _buildInfoRow('Cần thanh toán', currencyFormat.format(amountDue), valueColor: AppColors.error, isBoldValue: true),
          ],
        ),
      ),
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
      case 'delivery_failed':
        color = Colors.red;
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
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          order.statusLabel,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
        ),
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
            text: 'Xác nhận giao',
            onPressed: () => _confirmDelivery(context, order.id, adminId, viewModel),
          ),
        ],
      );
    }

    if (order.status == 'cancel_requested') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            text: 'Xác nhận',
            onPressed: () => _approveCancel(context, order.id, adminId, viewModel),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () => _rejectCancel(context, order.id, adminId, viewModel),
            child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            text: 'Hoàn trả',
            onPressed: () => _approveReturn(context, order.id, adminId, viewModel),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
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

  Future<void> _rejectCancel(
    BuildContext context,
    String orderId,
    String adminId,
    AdminOrderListViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối yêu cầu hủy'),
        content: const Text('Bạn có chắc muốn từ chối yêu cầu hủy đơn này? Đơn hàng sẽ trở lại trạng thái Chờ xử lý.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.rejectCancel(orderId, adminId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(context, 'Từ chối yêu cầu hủy thành công.');
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text('Đồng ý từ chối', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
