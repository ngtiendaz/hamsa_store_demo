import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../user/auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/admin_order_list_view_model.dart';

class AdminOrderListView extends StatefulWidget {
  const AdminOrderListView({super.key});

  @override
  State<AdminOrderListView> createState() => _AdminOrderListViewState();
}

class _AdminOrderListViewState extends State<AdminOrderListView> {
  String _statusFilter = 'all'; // 'all', 'pending_confirmation', 'cancel_requested', 'shipping', 'cancelled'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrderListViewModel>().loadOrders();
    });
  }

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AdminOrderListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.orders.isEmpty) {
            return const AppLoading();
          }

          // Lọc danh sách theo status
          final filteredOrders = viewModel.orders.where((order) {
            if (_statusFilter == 'all') return true;
            return order.status == _statusFilter;
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter Bar
                  _buildFilterBar(),
                  
                  // Main Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => viewModel.loadOrders(),
                      child: filteredOrders.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.detail),
                                  SizedBox(height: 12),
                                  Text('Không tìm thấy đơn hàng nào.'),
                                ],
                              ),
                            )
                          : isDesktop
                              ? _buildDesktopTable(filteredOrders, profile.id, isSystemAdmin, viewModel)
                              : _buildMobileList(filteredOrders, profile.id, isSystemAdmin, viewModel),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      {'value': 'all', 'label': 'Tất cả'},
      {'value': 'pending_confirmation', 'label': 'Chờ xác nhận'},
      {'value': 'cancel_requested', 'label': 'Chờ hủy'},
      {'value': 'shipping', 'label': 'Đang giao'},
      {'value': 'cancelled', 'label': 'Đã hủy'},
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _statusFilter == filter['value'];
          return ChoiceChip(
            label: Text(
              filter['label']!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _statusFilter = filter['value']!;
                });
              }
            },
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildDesktopTable(
    List<dynamic> orders,
    String adminId,
    bool isAdminUser,
    AdminOrderListViewModel viewModel,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        color: AppColors.surface,
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.5), // Code
            1: FlexColumnWidth(2.0), // KH Info
            2: FlexColumnWidth(2.5), // Products
            3: FlexColumnWidth(1.2), // Total
            4: FlexColumnWidth(1.5), // Payment
            5: FlexColumnWidth(1.5), // Status
            6: FlexColumnWidth(2.0), // Action
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            // Header Row
            _buildTableHeaderRow(),
            
            // Data Rows
            ...orders.map((order) {
              return TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                ),
                children: [
                  // 1. Code & Time
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(dateFormat.format(order.createdAt), style: const TextStyle(color: AppColors.detail, fontSize: 12)),
                      ],
                    ),
                  ),
                  // 2. KH Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(order.customerPhone ?? 'Không có SĐT', style: const TextStyle(color: AppColors.detail, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          order.customerAddress ?? 'Không có địa chỉ',
                          style: const TextStyle(color: AppColors.detail, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 3. Products
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: order.items.map<Widget>((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${item.productNameSnapshot} x${item.quantity}', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                    ),
                  ),
                  // 4. Total
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      currencyFormat.format(order.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                    ),
                  ),
                  // 5. Payment
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.paymentMethod == 'wallet' ? 'Ví HamsaPay' : 'COD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          order.paymentStatus == 'paid'
                              ? 'Đã thu tiền'
                              : order.paymentStatus == 'refunded'
                                  ? 'Đã hoàn tiền'
                                  : 'Chưa thu tiền',
                          style: TextStyle(
                            color: order.paymentStatus == 'paid'
                                ? Colors.green
                                : order.paymentStatus == 'refunded'
                                    ? Colors.blue
                                    : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 6. Status Badge
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildStatusBadge(order),
                  ),
                  // 7. Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildActionButtons(context, order, adminId, isAdminUser, viewModel),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableHeaderRow() {
    final headers = ['ĐƠN HÀNG', 'KHÁCH HÀNG', 'SẢN PHẨM', 'TỔNG TIỀN', 'THANH TOÁN', 'TRẠNG THÁI', 'THAO TÁC'];
    return TableRow(
      decoration: const BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
      ),
      children: headers.map((header) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            header,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileList(
    List<dynamic> orders,
    String adminId,
    bool isAdminUser,
    AdminOrderListViewModel viewModel,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = orders[index];
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    _buildStatusBadge(order),
                  ],
                ),
                const SizedBox(height: 4),
                Text(dateFormat.format(order.createdAt), style: const TextStyle(color: AppColors.detail, fontSize: 12)),
                const Divider(height: 24),
                
                // KH Info
                Text('Người nhận: ${order.customerName} - ${order.customerPhone ?? "N/A"}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                Text('Địa chỉ: ${order.customerAddress ?? "N/A"}', style: const TextStyle(color: AppColors.detail, fontSize: 13)),
                const Divider(height: 24),

                // Products
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: order.items.map<Widget>((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${item.productNameSnapshot} x${item.quantity}', style: const TextStyle(fontSize: 13))),
                          Text(currencyFormat.format(item.subtotal), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),

                // Total + Payment Method
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.paymentMethod == 'wallet' ? 'Ví HamsaPay' : 'COD', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          order.paymentStatus == 'paid'
                              ? 'Đã thanh toán'
                              : order.paymentStatus == 'refunded'
                                  ? 'Đã hoàn tiền'
                                  : 'Chưa thanh toán',
                          style: TextStyle(
                            color: order.paymentStatus == 'paid'
                                ? Colors.green
                                : order.paymentStatus == 'refunded'
                                    ? Colors.blue
                                    : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      currencyFormat.format(order.totalAmount),
                      style: const TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                // Actions
                if (order.status == 'pending_confirmation' || order.status == 'cancel_requested') ...[
                  const Divider(height: 24),
                  _buildActionButtons(context, order, adminId, isAdminUser, viewModel),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(dynamic order) {
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

  Widget _buildActionButtons(
    BuildContext context,
    dynamic order,
    String adminId,
    bool isAdminUser,
    AdminOrderListViewModel viewModel,
  ) {
    if (order.status == 'pending_confirmation') {
      return AppButton(
        text: 'Xác nhận giao hàng',
        onPressed: () => _confirmDelivery(context, order.id, adminId, viewModel),
      );
    }
    
    if (order.status == 'cancel_requested') {
      if (isAdminUser) {
        return AppButton(
          text: 'Đồng ý hủy đơn',
          onPressed: () => _approveCancel(context, order.id, adminId, viewModel),
        );
      } else {
        // Employee thì disable nút hủy
        return Tooltip(
          message: 'Chỉ có quản trị viên mới được quyền phê duyệt hủy',
          child: Opacity(
            opacity: 0.5,
            child: AppButton(
              text: 'Đồng ý hủy đơn',
              onPressed: null,
            ),
          ),
        );
      }
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
}
