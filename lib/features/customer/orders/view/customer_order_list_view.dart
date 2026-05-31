import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../core/utils/formatters.dart';
import '../../../user/auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/customer_order_list_view_model.dart';

class CustomerOrderListView extends StatefulWidget {
  const CustomerOrderListView({super.key});

  @override
  State<CustomerOrderListView> createState() => _CustomerOrderListViewState();
}

class _CustomerOrderListViewState extends State<CustomerOrderListView> {
  String _statusFilter = 'all'; 
  String _searchQuery = '';

  late final Debounce _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _debounce = Debounce(delay: const Duration(milliseconds: 300));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  void dispose() {
    _debounce.dispose();
    _searchController.dispose();
    super.dispose();
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
      body: Consumer<CustomerOrderListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.orders.isEmpty) {
            return const AppLoading();
          }

          // Lọc danh sách theo status và tìm kiếm
          final filteredOrders = viewModel.orders.where((order) {
            final matchesStatus = _statusFilter == 'all' || order.status == _statusFilter;
            final query = _searchQuery.trim().toLowerCase();
            if (query.isEmpty) return matchesStatus;

            final matchesCode = order.orderCode.toLowerCase().contains(query);
            final matchesProduct = order.items.any((item) =>
                item.productNameSnapshot.toLowerCase().contains(query));

            return matchesStatus && (matchesCode || matchesProduct);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search & Filter header
              _buildHeader(viewModel, userId),
              
              // Main Content
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _refresh(),
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
                      : ListView.separated(
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(CustomerOrderListViewModel viewModel, String userId) {
    final filters = [
      {'value': 'all', 'label': 'Tất cả'},
      {'value': 'pending_confirmation', 'label': 'Chờ xác nhận'},
      {'value': 'cancel_requested', 'label': 'Chờ hủy'},
      {'value': 'shipping', 'label': 'Đang giao'},
      {'value': 'delivered', 'label': 'Đã giao'},
      {'value': 'return_requested', 'label': 'Chờ hoàn trả'},
      {'value': 'returned', 'label': 'Đã hoàn trả'},
      {'value': 'cancelled', 'label': 'Đã hủy'},
      {'value': 'delivery_failed', 'label': 'Giao thất bại'},
    ];

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth >= 700;
          
          final searchField = SizedBox(
            width: isLarge ? 320 : double.infinity,
            height: 40,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _debounce.run(() {
                  setState(() {
                    _searchQuery = val;
                  });
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm mã đơn, sản phẩm...',
                hintStyle: const TextStyle(color: AppColors.detail, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.detail),
                fillColor: AppColors.surface,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border, width: 1.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.0),
                ),
              ),
            ),
          );

          final filterDropdown = Container(
            width: isLarge ? 200 : double.infinity,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                icon: const Icon(Icons.filter_list, size: 18, color: AppColors.detail),
                style: const TextStyle(color: AppColors.onSurface, fontSize: 13, fontWeight: FontWeight.w500),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _statusFilter = newValue;
                    });
                  }
                },
                items: filters.map<DropdownMenuItem<String>>((filter) {
                  return DropdownMenuItem<String>(
                    value: filter['value'],
                    child: Text(filter['label']!),
                  );
                }).toList(),
              ),
            ),
          );

          final dateRangeButton = Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: InkWell(
              onTap: () async {
                final DateTimeRange? picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: viewModel.startDate != null && viewModel.endDate != null
                      ? DateTimeRange(start: viewModel.startDate!, end: viewModel.endDate!)
                      : null,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primary,
                          onPrimary: Colors.white,
                          onSurface: AppColors.onSurface,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  final endOfDay = DateTime(
                    picked.end.year,
                    picked.end.month,
                    picked.end.day,
                    23,
                    59,
                    59,
                    999,
                  );
                  viewModel.setDateRange(picked.start, endOfDay, userId);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.date_range, size: 18, color: AppColors.detail),
                  const SizedBox(width: 8),
                  Text(
                    viewModel.startDate == null || viewModel.endDate == null
                        ? 'Chọn khoảng thời gian'
                        : '${DateFormat('dd/MM/yyyy').format(viewModel.startDate!)} - ${DateFormat('dd/MM/yyyy').format(viewModel.endDate!)}',
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (viewModel.startDate != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14, color: AppColors.detail),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        viewModel.clearDateRange(userId);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );

          if (isLarge) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                searchField,
                const SizedBox(width: 16),
                filterDropdown,
                const SizedBox(width: 16),
                dateRangeButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 12),
              filterDropdown,
              const SizedBox(height: 12),
              dateRangeButton,
            ],
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

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push('/shop/orders/detail', extra: order);
          viewModel.loadOrders(userId);
        },
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
                        formatVietnamDateTime(order.createdAt),
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
            if (order.status == 'pending_confirmation' ||
                order.status == 'cancel_requested' ||
                order.status == 'delivered' ||
                order.status == 'return_requested') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == 'pending_confirmation') ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showUpdateDialog(context),
                      child: const Text('Cập nhật'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showCancelDialog(context),
                      child: const Text('Yêu cầu hủy'),
                    ),
                  ],
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
                  if (order.status == 'return_requested')
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _showCancelReturnDialog(context),
                      child: const Text('Hủy yêu cầu hoàn trả'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    ));
  }

  void _showUpdateDialog(BuildContext context) {
    final nameController = TextEditingController(text: order.customerName);
    final phoneController = TextEditingController(text: order.customerPhone);
    final addressController = TextEditingController(text: order.customerAddress);
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
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              final address = addressController.text.trim();
              final note = noteController.text.trim();

              if (name.isEmpty || phone.isEmpty || address.isEmpty) {
                AppToast.showError(context, 'Họ tên, SĐT và địa chỉ là bắt buộc.');
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
                  AppToast.showSuccess(context, 'Cập nhật thông tin đơn hàng thành công.');
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text('Lưu lại', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCancelReturnDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy yêu cầu hoàn trả'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu hoàn trả cho đơn hàng này để đưa về trạng thái giao thành công không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy bỏ', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await viewModel.cancelRequestReturn(order.id, userId);
              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(context, 'Đã hủy yêu cầu hoàn trả thành công.');
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: const Text('Đồng ý', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
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
