import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/models/order_model.dart';
import '../../../login/auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/admin_order_list_view_model.dart';

class AdminOrderListView extends StatefulWidget {
  final String? initialStatus;

  const AdminOrderListView({super.key, this.initialStatus});

  @override
  State<AdminOrderListView> createState() => _AdminOrderListViewState();
}

class _AdminOrderListViewState extends State<AdminOrderListView> {
  static const _allowedStatusFilters = {
    'all',
    'pending_confirmation',
    'cancel_requested',
    'shipping',
    'delivered',
    'delivery_failed',
    'return_requested',
    'returned',
    'cancelled',
    'refunded',
  };

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialStatus = _normalizeStatusFilter(widget.initialStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrderListViewModel>().initFilters(
        status: initialStatus,
      );
    });
  }

  @override
  void didUpdateWidget(covariant AdminOrderListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialStatus != oldWidget.initialStatus) {
      final newStatus = _normalizeStatusFilter(widget.initialStatus);
      context.read<AdminOrderListViewModel>().selectStatus(newStatus);
    }
  }

  String _normalizeStatusFilter(String? status) {
    return _allowedStatusFilters.contains(status) ? status! : 'all';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      appBar: null, // Bỏ appBar phụ để dùng Top Bar từ MainLayout
      body: Consumer<AdminOrderListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.orders.isEmpty) {
            return const AppLoading();
          }

          final filteredOrders = viewModel.orders;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search & Filter header
                  _buildHeader(viewModel),

                  // Main Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => viewModel.loadOrders(),
                      child: filteredOrders.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 56,
                                    color: AppColors.detail,
                                  ),
                                  SizedBox(height: 12),
                                  Text('Không tìm thấy đơn hàng nào.'),
                                ],
                              ),
                            )
                          : isDesktop
                          ? _buildDesktopTable(
                              filteredOrders,
                              profile.id,
                              isSystemAdmin,
                              viewModel,
                            )
                          : _buildMobileList(
                              filteredOrders,
                              profile.id,
                              isSystemAdmin,
                              viewModel,
                            ),
                    ),
                  ),
                  if (viewModel.orders.isNotEmpty)
                    _buildPaginationFooter(viewModel),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(AdminOrderListViewModel viewModel) {
    final filters = [
      {'value': 'all', 'label': 'Tất cả'},
      {'value': 'pending_confirmation', 'label': 'Chờ xác nhận'},
      {'value': 'cancel_requested', 'label': 'Chờ hủy'},
      {'value': 'shipping', 'label': 'Đang giao'},
      {'value': 'delivered', 'label': 'Đã giao'},
      {'value': 'delivery_failed', 'label': 'Giao thất bại'},
      {'value': 'return_requested', 'label': 'Chờ xác nhận đổi trả'},
      {'value': 'returned', 'label': 'Đã hoàn trả'},
      {'value': 'cancelled', 'label': 'Đã hủy'},
      {'value': 'refunded', 'label': 'Đã hoàn tiền'},
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
                viewModel.setKeyword(val);
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm mã đơn, khách hàng, SĐT...',
                hintStyle: const TextStyle(
                  color: AppColors.detail,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppColors.detail,
                ),
                fillColor: AppColors.surface,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.0,
                  ),
                ),
              ),
            ),
          );

          final filterDropdown = Container(
            width: isLarge ? 220 : double.infinity,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: viewModel.status,
                icon: const Icon(
                  Icons.filter_list,
                  size: 18,
                  color: AppColors.detail,
                ),
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    viewModel.selectStatus(newValue);
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
                  initialDateRange:
                      viewModel.startDate != null && viewModel.endDate != null
                      ? DateTimeRange(
                          start: viewModel.startDate!,
                          end: viewModel.endDate!,
                        )
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
                  viewModel.setDateRange(picked.start, endOfDay);
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.date_range,
                    size: 18,
                    color: AppColors.detail,
                  ),
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
                      icon: const Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.detail,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        viewModel.clearDateRange();
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

  Widget _buildPaginationFooter(AdminOrderListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: viewModel.hasPreviousPage
                ? viewModel.previousPage
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('Trang ${viewModel.currentPage}/${viewModel.totalPages}'),
          IconButton(
            onPressed: viewModel.hasNextPage ? viewModel.nextPage : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(
    List<OrderModel> orders,
    String adminId,
    bool isAdminUser,
    AdminOrderListViewModel viewModel,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        color: AppColors.surface,
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(2.0),
            2: FlexColumnWidth(2.8),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1.5),
            5: FlexColumnWidth(1.7),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildTableHeaderRow(),
            ...orders.map((order) {
              return TableRow(
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.border, width: 0.5),
                  ),
                ),
                children: [
                  TableCell(
                    child: InkWell(
                      onTap: () =>
                          context.push('/admin/orders/detail', extra: order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatVietnamDateTime(order.createdAt),
                              style: const TextStyle(
                                color: AppColors.detail,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () =>
                          context.push('/admin/orders/detail', extra: order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.customerPhone ?? 'Không có SĐT',
                              style: const TextStyle(
                                color: AppColors.detail,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () =>
                          context.push('/admin/orders/detail', extra: order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: order.items.map<Widget>((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${item.productNameSnapshot} x${item.quantity}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () =>
                          context.push('/admin/orders/detail', extra: order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          currencyFormat.format(order.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () =>
                          context.push('/admin/orders/detail', extra: order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.paymentMethod == 'wallet'
                                  ? 'Ví HamsaPay'
                                  : 'COD',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () =>
                          context.push('/admin/orders/detail', extra: order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(child: _buildStatusBadge(order)),
                      ),
                    ),
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
    final headers = [
      'ĐƠN HÀNG',
      'KHÁCH HÀNG',
      'SẢN PHẨM',
      'TỔNG TIỀN',
      'THANH TOÁN',
      'TRẠNG THÁI',
    ];
    return TableRow(
      decoration: const BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      children: headers.map((header) {
        final isStatus = header == 'TRẠNG THÁI';
        final textWidget = Text(
          header,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black87,
          ),
        );
        return Padding(
          padding: const EdgeInsets.all(16),
          child: isStatus ? Center(child: textWidget) : textWidget,
        );
      }).toList(),
    );
  }

  Widget _buildMobileList(
    List<OrderModel> orders,
    String adminId,
    bool isAdminUser,
    AdminOrderListViewModel viewModel,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/admin/orders/detail', extra: order),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      _buildStatusBadge(order),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatVietnamDateTime(order.createdAt),
                    style: const TextStyle(
                      color: AppColors.detail,
                      fontSize: 12,
                    ),
                  ),
                  const Divider(height: 24),

                  Text(
                    'Người nhận: ${order.customerName} - ${order.customerPhone ?? "N/A"}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Địa chỉ: ${order.customerAddress ?? "N/A"}',
                    style: const TextStyle(
                      color: AppColors.detail,
                      fontSize: 13,
                    ),
                  ),
                  const Divider(height: 24),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: order.items.map<Widget>((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productNameSnapshot} x${item.quantity}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              currencyFormat.format(item.subtotal),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.paymentMethod == 'wallet'
                                ? 'Ví HamsaPay'
                                : 'COD',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          order.statusLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
