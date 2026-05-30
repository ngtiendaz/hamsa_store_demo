import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamsa_store_demo/data/models/cart_item_model.dart';
import 'package:hamsa_store_demo/data/models/cart_model.dart';
import 'package:hamsa_store_demo/data/models/products_model.dart';
import 'package:hamsa_store_demo/data/models/profiles_model.dart';
import 'package:hamsa_store_demo/features/customer/cart/repository/customer_cart_repository.dart';
import 'package:hamsa_store_demo/features/customer/cart/viewmodel/customer_cart_view_model.dart';
import 'package:hamsa_store_demo/features/user/profile/repository/profile_repository.dart';
import 'package:hamsa_store_demo/features/user/profile/viewmodel/profile_viewmodel.dart';
import 'package:hamsa_store_demo/data/models/wallet_model.dart';
import 'package:hamsa_store_demo/data/models/wallet_transaction_model.dart';
import 'package:hamsa_store_demo/data/models/order_model.dart';
import 'package:hamsa_store_demo/features/customer/checkout/viewmodel/checkout_view_model.dart';
import 'package:hamsa_store_demo/features/customer/orders/repository/customer_order_repository.dart';
import 'package:hamsa_store_demo/features/customer/orders/viewmodel/customer_order_list_view_model.dart';
import 'package:hamsa_store_demo/features/admin/orders/repository/admin_order_repository.dart';
import 'package:hamsa_store_demo/features/admin/orders/viewmodel/admin_order_list_view_model.dart';
import 'package:hamsa_store_demo/data/models/admin_dashboard_stats_model.dart';
import 'package:hamsa_store_demo/features/admin/dashboard/repository/admin_dashboard_repository.dart';
import 'package:hamsa_store_demo/features/admin/dashboard/viewmodel/admin_dashboard_view_model.dart';

void main() {
  test(
    'CustomerCartViewModel persists quantity within product stock',
    () async {
      final repository = _FakeCustomerCartRepository();
      final viewModel = CustomerCartViewModel(repository: repository);
      final product = _buildProduct(stock: 2);

      viewModel.syncForUser('user-1');
      await Future<void>.delayed(Duration.zero);

      expect(await viewModel.addProduct(product), CartMutationResult.success);
      expect(await viewModel.addProduct(product), CartMutationResult.success);
      expect(
        await viewModel.addProduct(product),
        CartMutationResult.outOfStock,
      );
      expect(viewModel.itemCount, 1);
      expect(viewModel.totalQuantity, 2);
      expect(viewModel.totalAmount, 200000);
      expect(viewModel.selectedItemCount, 0);
      expect(viewModel.selectedTotalAmount, 0);

      viewModel.toggleProductSelection(product.id, true);
      expect(viewModel.selectedItemCount, 1);
      expect(viewModel.selectedTotalAmount, 200000);

      expect(
        await viewModel.decreaseQuantity(product),
        CartMutationResult.success,
      );
      expect(viewModel.totalQuantity, 1);
      expect(viewModel.selectedTotalAmount, 100000);

      expect(
        await viewModel.removeProduct(product.id),
        CartMutationResult.success,
      );
      expect(viewModel.entries, isEmpty);
      expect(viewModel.selectedItemCount, 0);
    },
  );

  test('ProfileViewModel updates editable profile fields', () async {
    final repository = _FakeProfileRepository();
    final viewModel = ProfileViewModel(
      profile: _buildProfile(),
      repository: repository,
    );

    viewModel.setName('Nguyễn Văn A');
    viewModel.setPhone('0909123456');

    expect(await viewModel.save(), isTrue);
    expect(viewModel.profile.name, 'Nguyễn Văn A');
    expect(viewModel.profile.phone, '0909123456');
    expect(repository.updatedUserId, 'user-1');
  });

  test('ProfileViewModel rejects an empty name', () async {
    final viewModel = ProfileViewModel(
      profile: _buildProfile(),
      repository: _FakeProfileRepository(),
    );

    viewModel.setName(' ');

    expect(await viewModel.save(), isFalse);
    expect(viewModel.errorMessage, 'Họ tên không được để trống.');
  });

  test('ProfileViewModel does not load wallet for admin or employee', () async {
    final repository = _FakeProfileRepository();
    final adminProfile = _buildProfile().copyWith(role: 'admin');
    final viewModel = ProfileViewModel(
      profile: adminProfile,
      repository: repository,
    );

    await Future<void>.delayed(Duration.zero);

    expect(viewModel.wallet, isNull);
    expect(repository.getWalletCalled, isFalse);
  });

  test('CheckoutViewModel place COD order successfully', () async {
    final orderRepo = _FakeCustomerOrderRepository();
    final profileRepo = _FakeProfileRepository();
    final viewModel = CheckoutViewModel(
      orderRepository: orderRepo,
      profileRepository: profileRepo,
    );

    final profile = _buildProfile().copyWith(phone: '0909123456');
    viewModel.initFromProfile(profile);

    // Set shipping info
    viewModel.setCustomerAddress('123 Đường ABC');
    viewModel.setPaymentMethod('cash');
    viewModel.setNote('Giao giờ hành chính');

    final product = _buildProduct(stock: 10);
    final entry = CustomerCartEntry(
      id: 'cart-item-1',
      product: product,
      quantity: 1,
    );

    final success = await viewModel.submitOrder(
      userId: profile.id,
      selectedEntries: [entry],
    );

    expect(success, isTrue);
    expect(viewModel.successOrderId, 'order-fake');
    expect(orderRepo.createOrderCalled, isTrue);
    expect(viewModel.errorMessage, isNull);
  });

  test(
    'CheckoutViewModel payment wallet failed if insufficient balance',
    () async {
      final orderRepo = _FakeCustomerOrderRepository();
      final profileRepo = _FakeProfileRepository();
      // Default mock profile balance is 100,000 VND
      final viewModel = CheckoutViewModel(
        orderRepository: orderRepo,
        profileRepository: profileRepo,
      );

      final profile = _buildProfile().copyWith(phone: '0909123456');
      viewModel.initFromProfile(profile);
      await Future<void>.delayed(Duration.zero); // Wait for loadWalletBalance

      viewModel.setCustomerAddress('123 Đường ABC');
      viewModel.setPaymentMethod('wallet');

      // Make an entry with subtotal > 100,000 VND (e.g. 2 items of 100k = 200k)
      final product = _buildProduct(stock: 10);
      final entry = CustomerCartEntry(
        id: 'cart-item-1',
        product: product,
        quantity: 2,
      );

      final success = await viewModel.submitOrder(
        userId: profile.id,
        selectedEntries: [entry],
      );

      expect(success, isFalse);
      expect(viewModel.successOrderId, isNull);
      expect(viewModel.errorMessage, contains('Số dư ví HamsaPay không đủ'));
      expect(orderRepo.createOrderCalled, isFalse);
    },
  );

  test(
    'CustomerOrderListViewModel request and cancel request cancellation',
    () async {
      final orderRepo = _FakeCustomerOrderRepository();
      final viewModel = CustomerOrderListViewModel(orderRepository: orderRepo);

      final initialOrder = OrderModel(
        id: 'order-1',
        orderCode: 'ORD-001',
        customerId: 'user-1',
        customerName: 'Khách hàng',
        customerPhone: '0909123456',
        customerAddress: '123 Đường ABC',
        status: 'pending_confirmation',
        totalAmount: 100000.0,
        paymentMethod: 'cash',
        paymentStatus: 'unpaid',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      orderRepo.orders.add(initialOrder);

      await viewModel.loadOrders('user-1');
      expect(viewModel.orders.length, 1);
      expect(viewModel.orders[0].status, 'pending_confirmation');

      // Request cancel
      final cancelReqSuccess = await viewModel.requestCancel(
        'order-1',
        'user-1',
      );
      expect(cancelReqSuccess, isTrue);
      expect(orderRepo.requestCancelCalled, isTrue);
      expect(viewModel.orders[0].status, 'cancel_requested');

      // Cancel request cancel
      final withdrawSuccess = await viewModel.cancelRequestCancel(
        'order-1',
        'user-1',
      );
      expect(withdrawSuccess, isTrue);
      expect(orderRepo.cancelRequestCancelCalled, isTrue);
      expect(viewModel.orders[0].status, 'pending_confirmation');
    },
  );

  test(
    'AdminOrderListViewModel confirm shipping and approve cancellation',
    () async {
      final initialOrders = [
        OrderModel(
          id: 'order-1',
          orderCode: 'ORD-001',
          customerId: 'user-1',
          customerName: 'Khách hàng',
          customerPhone: '0909123456',
          customerAddress: '123 Đường ABC',
          status: 'pending_confirmation',
          totalAmount: 100000.0,
          paymentMethod: 'cash',
          paymentStatus: 'unpaid',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        OrderModel(
          id: 'order-2',
          orderCode: 'ORD-002',
          customerId: 'user-1',
          customerName: 'Khách hàng',
          customerPhone: '0909123456',
          customerAddress: '123 Đường ABC',
          status: 'cancel_requested',
          totalAmount: 100000.0,
          paymentMethod: 'cash',
          paymentStatus: 'unpaid',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final orderRepo = _FakeAdminOrderRepository(initialOrders);
      final viewModel = AdminOrderListViewModel(orderRepository: orderRepo);

      await viewModel.loadOrders();
      expect(viewModel.orders.length, 2);

      // Confirm shipping
      final confirmSuccess = await viewModel.confirmOrder('order-1', 'admin-1');
      expect(confirmSuccess, isTrue);
      expect(
        viewModel.orders.firstWhere((o) => o.id == 'order-1').status,
        'shipping',
      );

      // Approve cancellation
      final approveCancelSuccess = await viewModel.approveCancel(
        'order-2',
        'admin-1',
      );
      expect(approveCancelSuccess, isTrue);
      expect(
        viewModel.orders.firstWhere((o) => o.id == 'order-2').status,
        'cancelled',
      );
    },
  );

  test('AdminDashboardViewModel reloads stats when period changes', () async {
    final repository = _FakeAdminDashboardRepository();
    final viewModel = AdminDashboardViewModel(repository: repository);

    await viewModel.loadStats();
    expect(viewModel.stats?.period, 'month');
    expect(viewModel.stats?.revenue, 59081500);

    await viewModel.changePeriod(DashboardPeriod.week);
    expect(viewModel.period, DashboardPeriod.week);
    expect(viewModel.stats?.period, 'week');

    await viewModel.changePeriod(DashboardPeriod.month);
    await viewModel.changeMonth(3);
    await viewModel.changeYear(2025);
    expect(viewModel.referenceDate, DateTime(2025, 3));
    expect(repository.requestedPeriods, [
      'month',
      'week',
      'month',
      'month',
      'month',
    ]);
    expect(repository.referenceDates.last, DateTime(2025, 3));
  });
}

class _FakeCustomerCartRepository implements CustomerCartDataSource {
  final Map<String, CartItemModel> _items = {};
  final DateTime _now = DateTime(2026);

  @override
  Future<CartModel?> getActiveCart(String userId) async {
    return CartModel(
      id: 'cart-1',
      userId: userId,
      status: 'active',
      createdAt: _now,
      updatedAt: _now,
      items: _items.values.toList(),
    );
  }

  @override
  Future<void> addProduct({
    required String userId,
    required ProductModel product,
    required int quantity,
  }) async {
    _items[product.id] = CartItemModel(
      id: 'item-${product.id}',
      cartId: 'cart-1',
      productId: product.id,
      quantity: quantity,
      priceSnapshot: product.price,
      createdAt: _now,
      updatedAt: _now,
      product: product,
    );
  }

  @override
  Future<void> deleteCartItem(String cartItemId) async {
    _items.removeWhere((key, item) => item.id == cartItemId);
  }

  @override
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final entry = _items.entries.singleWhere(
      (item) => item.value.id == cartItemId,
    );
    _items[entry.key] = entry.value.copyWith(quantity: quantity);
  }
}

ProductModel _buildProduct({required int stock}) {
  final now = DateTime(2026);
  return ProductModel(
    id: 'product-1',
    categoryId: 'category-1',
    brandId: 'brand-1',
    internalName: 'Sản phẩm test',
    price: 100000,
    stock: stock,
    status: 'active',
    isFeatured: false,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeProfileRepository implements ProfileDataSource {
  String? updatedUserId;
  bool getWalletCalled = false;

  @override
  Future<ProfileModel> updateProfile({
    required String userId,
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    updatedUserId = userId;
    return _buildProfile().copyWith(
      name: name,
      phone: phone,
      avatarUrl: avatarUrl,
      updatedAt: DateTime(2026, 5, 30),
    );
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    return 'https://example.com/avatar.jpg';
  }

  @override
  Future<WalletModel?> getWallet(String userId) async {
    getWalletCalled = true;
    return WalletModel(
      id: 'wallet-1',
      userId: userId,
      balance: 100000.0,
      currency: 'VND',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  Future<List<WalletTransactionModel>> getWalletTransactions(
    String userId,
  ) async {
    return [];
  }

  @override
  Future<void> processWalletTransaction({
    required String userId,
    required String type,
    required double amount,
    String? note,
  }) async {
    // Fake success
  }
}

ProfileModel _buildProfile() {
  final now = DateTime(2026);
  return ProfileModel(
    id: 'user-1',
    email: 'customer@example.com',
    name: 'Khách hàng',
    phone: null,
    avatarUrl: null,
    role: 'customer',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeCustomerOrderRepository implements CustomerOrderDataSource {
  final List<OrderModel> orders = [];
  bool createOrderCalled = false;
  bool requestCancelCalled = false;
  bool cancelRequestCancelCalled = false;

  @override
  Future<List<OrderModel>> getActiveOrders(String userId) async {
    return orders.where((o) => o.customerId == userId).toList();
  }

  @override
  Future<String> createOrder({
    required String userId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? note,
    required String paymentMethod,
    required List<String> cartItemIds,
    required String orderCode,
  }) async {
    createOrderCalled = true;
    final order = OrderModel(
      id: 'order-fake',
      orderCode: orderCode,
      customerId: userId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerAddress: customerAddress,
      note: note,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'wallet' ? 'paid' : 'unpaid',
      totalAmount: 100000.0,
      status: 'pending_confirmation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: [],
    );
    orders.add(order);
    return 'order-fake';
  }

  @override
  Future<void> requestCancelOrder(String orderId, String userId) async {
    requestCancelCalled = true;
    final idx = orders.indexWhere(
      (o) => o.id == orderId && o.customerId == userId,
    );
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'cancel_requested',
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> cancelRequestCancelOrder(String orderId, String userId) async {
    cancelRequestCancelCalled = true;
    final idx = orders.indexWhere(
      (o) => o.id == orderId && o.customerId == userId,
    );
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'pending_confirmation',
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> requestReturnOrder(String orderId, String userId) async {
    final idx = orders.indexWhere(
      (o) => o.id == orderId && o.customerId == userId,
    );
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'return_requested',
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> cancelRequestReturnOrder(String orderId, String userId) async {
    final idx = orders.indexWhere(
      (o) => o.id == orderId && o.customerId == userId,
    );
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'delivered',
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> updateOrderInfo({
    required String orderId,
    required String userId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? note,
  }) async {
    final idx = orders.indexWhere(
      (o) => o.id == orderId && o.customerId == userId,
    );
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        note: note,
        updatedAt: DateTime.now(),
      );
    }
  }
}

class _FakeAdminOrderRepository implements AdminOrderDataSource {
  final List<OrderModel> orders;

  _FakeAdminOrderRepository(this.orders);

  @override
  Future<List<OrderModel>> getAllOrders() async {
    return orders;
  }

  @override
  Future<void> confirmOrder(String orderId, String adminId) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'shipping',
        confirmedBy: adminId,
        confirmedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> approveCancelOrder(String orderId, String adminId) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'cancelled',
        cancelledBy: adminId,
        cancelledAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deliverOrderSuccess(String orderId, String adminId) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'delivered',
        paymentStatus: orders[idx].paymentMethod == 'cash'
            ? 'paid'
            : orders[idx].paymentStatus,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> deliverOrderFailed(String orderId, String adminId) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'delivery_failed',
        paymentStatus: orders[idx].paymentMethod == 'wallet'
            ? 'refunded'
            : orders[idx].paymentStatus,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> approveReturnOrder(String orderId, String adminId) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'returned',
        paymentStatus: orders[idx].paymentStatus == 'paid'
            ? 'refunded'
            : orders[idx].paymentStatus,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> cancelPendingOrder(String orderId, String adminId) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'cancelled',
        paymentStatus:
            orders[idx].paymentMethod == 'wallet' &&
                orders[idx].paymentStatus == 'paid'
            ? 'refunded'
            : orders[idx].paymentStatus,
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> rejectCancelOrder(String orderId, String adminId) async {
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      orders[idx] = orders[idx].copyWith(
        status: 'pending_confirmation',
        updatedAt: DateTime.now(),
      );
    }
  }
}

class _FakeAdminDashboardRepository implements AdminDashboardDataSource {
  final List<String> requestedPeriods = [];
  final List<DateTime> referenceDates = [];

  @override
  Future<AdminDashboardStatsModel> getStats(
    String period,
    DateTime referenceDate,
  ) async {
    requestedPeriods.add(period);
    referenceDates.add(referenceDate);

    return AdminDashboardStatsModel(
      period: period,
      referenceDate: referenceDate,
      startAt: DateTime(2026, 5, 1),
      endAt: DateTime(2026, 6, 1),
      revenue: 59081500,
      shippingCount: 0,
      cancelledCount: 1,
      deliveredCount: 1,
      refundedCount: 0,
      refundedAmount: 0,
      returnRate: 0,
      deliverySuccessRate: 100,
      lowStockProducts: const [],
      topSellingProducts: const [],
    );
  }
}
