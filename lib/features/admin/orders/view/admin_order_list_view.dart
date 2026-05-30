import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../data/models/order_model.dart';
import '../../../user/auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/admin_order_list_view_model.dart';

class AdminOrderListView extends StatefulWidget {
  const AdminOrderListView({super.key});

  @override
  State<AdminOrderListView> createState() => _AdminOrderListViewState();
}

class _AdminOrderListViewState extends State<AdminOrderListView> {
  String _statusFilter = 'all'; 
  String _searchQuery = '';

  late final Debounce _debounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _debounce = Debounce(delay: const Duration(milliseconds: 300));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminOrderListViewModel>().loadOrders();
    });
  }

  @override
  void dispose() {
    _debounce.dispose();
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

          // Lọc danh sách theo status và tìm kiếm
          final filteredOrders = viewModel.orders.where((order) {
            final matchesStatus = _statusFilter == 'all' || order.status == _statusFilter;
            final query = _searchQuery.trim().toLowerCase();
            if (query.isEmpty) return matchesStatus;

            final matchesCode = order.orderCode.toLowerCase().contains(query);
            final matchesCustomer = order.customerName.toLowerCase().contains(query);
            final matchesPhone = (order.customerPhone ?? '').toLowerCase().contains(query);

            return matchesStatus && (matchesCode || matchesCustomer || matchesPhone);
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search & Filter header
                  _buildHeader(),
                  
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth >= 700;
          
          final searchField = Container(
            width: isLarge ? 320 : double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                _debounce.run(() {
                  setState(() {
                    _searchQuery = val;
                  });
                });
              },
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm mã đơn, khách hàng, SĐT...',
                hintStyle: TextStyle(color: AppColors.detail, fontSize: 13),
                prefixIcon: Icon(Icons.search, size: 18, color: AppColors.detail),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          );

          if (isLarge) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                searchField,
                const SizedBox(width: 16),
                Expanded(child: _buildFilterBar()),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 12),
              _buildFilterBar(),
            ],
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
      {'value': 'delivered', 'label': 'Đã giao'},
      {'value': 'delivery_failed', 'label': 'Giao thất bại'},
      {'value': 'return_requested', 'label': 'Chờ xác nhận đổi trả'},
      {'value': 'returned', 'label': 'Đã hoàn trả'},
      {'value': 'cancelled', 'label': 'Đã hủy'},
    ];

    return SizedBox(
      height: 44,
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
                fontSize: 13,
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
    List<OrderModel> orders,
    String adminId,
    bool isAdminUser,
    AdminOrderListViewModel viewModel,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

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
            5: FlexColumnWidth(1.5), 
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildTableHeaderRow(),
            ...orders.map((order) {
              return TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                ),
                children: [
                  TableCell(
                    child: InkWell(
                      onTap: () => context.go('/admin/orders/detail', extra: order),
                      child: Padding(
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
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () => context.go('/admin/orders/detail', extra: order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(order.customerPhone ?? 'Không có SĐT', style: const TextStyle(color: AppColors.detail, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () => context.go('/admin/orders/detail', extra: order),
                      child: Padding(
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
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () => context.go('/admin/orders/detail', extra: order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          currencyFormat.format(order.totalAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () => context.go('/admin/orders/detail', extra: order),
                      child: Padding(
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
                    ),
                  ),
                  TableCell(
                    child: InkWell(
                      onTap: () => context.go('/admin/orders/detail', extra: order),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _buildStatusBadge(order),
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
    final headers = ['ĐƠN HÀNG', 'KHÁCH HÀNG', 'SẢN PHẨM', 'TỔNG TIỀN', 'THANH TOÁN', 'TRẠNG THÁI'];
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
    List<OrderModel> orders,
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
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.go('/admin/orders/detail', extra: order),
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
                  
                  Text('Người nhận: ${order.customerName} - ${order.customerPhone ?? "N/A"}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Địa chỉ: ${order.customerAddress ?? "N/A"}', style: const TextStyle(color: AppColors.detail, fontSize: 13)),
                  const Divider(height: 24),

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
}
