import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamsa_store_demo/data/dto/pagination_result.dart';
import 'package:hamsa_store_demo/data/models/cart_item_model.dart';
import 'package:hamsa_store_demo/data/models/cart_model.dart';
import 'package:hamsa_store_demo/data/models/products_model.dart';
import 'package:hamsa_store_demo/data/models/profiles_model.dart';
import 'package:hamsa_store_demo/features/customer/cart/repository/customer_cart_repository.dart';
import 'package:hamsa_store_demo/features/customer/cart/viewmodel/customer_cart_view_model.dart';
import 'package:hamsa_store_demo/features/login/profile/repository/profile_repository.dart';
import 'package:hamsa_store_demo/features/login/profile/viewmodel/profile_viewmodel.dart';
import 'package:hamsa_store_demo/data/models/wallet_model.dart';
import 'package:hamsa_store_demo/data/models/wallet_transaction_model.dart';
import 'package:hamsa_store_demo/data/models/order_model.dart';
import 'package:hamsa_store_demo/features/customer/checkout/viewmodel/checkout_view_model.dart';
import 'package:hamsa_store_demo/features/customer/orders/repository/customer_order_repository.dart';
import 'package:hamsa_store_demo/features/customer/orders/viewmodel/customer_order_list_view_model.dart';
import 'package:hamsa_store_demo/features/admin/orders/repository/admin_order_repository.dart';
import 'package:hamsa_store_demo/features/admin/orders/viewmodel/admin_order_list_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hamsa_store_demo/features/login/auth/viewmodel/register_view_model.dart';
import 'package:hamsa_store_demo/features/login/auth/viewmodel/auth_viewmodel.dart';
import 'package:hamsa_store_demo/data/models/admin_dashboard_stats_model.dart';
import 'package:hamsa_store_demo/features/admin/dashboard/repository/admin_dashboard_repository.dart';
import 'package:hamsa_store_demo/features/admin/dashboard/viewmodel/admin_dashboard_view_model.dart';

void main() {
  test('ProductModel sorts product images by sort order', () {
    final product = ProductModel.fromJson({
      'id': 'product-1',
      'category_id': 'category-1',
      'brand_id': 'brand-1',
      'internal_name': 'Sản phẩm test',
      'trade_name': 'Sản phẩm test',
      'price': 100000,
      'stock': 10,
      'status': 'active',
      'is_featured': false,
      'created_at': '2026-05-31T00:00:00Z',
      'updated_at': '2026-05-31T00:00:00Z',
      'product_images': [
        {'image_url': 'image-2.jpg', 'sort_order': 2},
        {'image_url': 'image-1.jpg', 'sort_order': 1},
      ],
    });

    expect(product.imageUrls, ['image-1.jpg', 'image-2.jpg']);
  });

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

  group('Auth & Registration Tests', () {
    test('RegisterViewModel validation and registration flow', () async {
      final authViewModel = _FakeAuthViewModel();
      final viewModel = RegisterViewModel(authViewModel: authViewModel);

      // Initial state
      expect(viewModel.email, isEmpty);
      expect(viewModel.password, isEmpty);

      // Validate empty
      expect(viewModel.validate(), isFalse);
      expect(viewModel.errorMessage, contains('Email không được để trống'));

      // Validate invalid email
      viewModel.setEmail('invalid_email');
      expect(viewModel.validate(), isFalse);
      expect(viewModel.errorMessage, contains('Email không đúng định dạng'));

      // Validate short password
      viewModel.setEmail('test@example.com');
      viewModel.setPassword('123');
      expect(viewModel.validate(), isFalse);
      expect(
        viewModel.errorMessage,
        contains('Mật khẩu phải chứa ít nhất 6 ký tự'),
      );

      // Validate password mismatch
      viewModel.setPassword('123456');
      viewModel.setConfirmPassword('1234567');
      expect(viewModel.validate(), isFalse);
      expect(viewModel.errorMessage, contains('Mật khẩu xác nhận không khớp'));

      // Successful validation
      viewModel.setConfirmPassword('123456');
      expect(viewModel.validate(), isTrue);

      // Registration call
      final success = await viewModel.register();
      expect(success, isTrue);
      expect(authViewModel.registeredEmail, 'test@example.com');
      expect(
        authViewModel.registeredName,
        'test',
      ); // derived from email local-part since name is empty
    });

    test('AuthViewModel recent accounts logic', () async {
      SharedPreferences.setMockInitialValues({});
      final authViewModel = _FakeAuthViewModelForRecentAccounts();

      final profile1 = ProfileModel(
        id: 'user-1',
        email: 'user1@example.com',
        name: 'User One',
        role: 'customer',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final profile2 = ProfileModel(
        id: 'user-2',
        email: 'user2@example.com',
        name: 'User Two',
        role: 'customer',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Initially empty
      var recent = await authViewModel.getRecentAccounts();
      expect(recent, isEmpty);

      // Save user 1
      await authViewModel.saveRecentAccount(profile1);
      recent = await authViewModel.getRecentAccounts();
      expect(recent.length, 1);
      expect(recent[0].email, 'user1@example.com');

      // Save user 2 (should be at top)
      await authViewModel.saveRecentAccount(profile2);
      recent = await authViewModel.getRecentAccounts();
      expect(recent.length, 2);
      expect(recent[0].email, 'user2@example.com');
      expect(recent[1].email, 'user1@example.com');

      // Save user 1 again (should move to top)
      await authViewModel.saveRecentAccount(profile1);
      recent = await authViewModel.getRecentAccounts();
      expect(recent.length, 2);
      expect(recent[0].email, 'user1@example.com');
      expect(recent[1].email, 'user2@example.com');

      // Remove user 2
      await authViewModel.removeRecentAccount('user2@example.com');
      recent = await authViewModel.getRecentAccounts();
      expect(recent.length, 1);
      expect(recent[0].email, 'user1@example.com');
    });
  });
}

class _FakeAuthViewModel extends AuthViewModel {
  String? registeredEmail;
  String? registeredName;

  _FakeAuthViewModel() : super();

  @override
  Future<bool> register(String email, String password, String name) async {
    registeredEmail = email;
    registeredName = name;
    return true;
  }
}

class _FakeAuthViewModelForRecentAccounts extends AuthViewModel {
  _FakeAuthViewModelForRecentAccounts() : super();
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

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
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
  Future<List<OrderModel>> getActiveOrders(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var list = orders.where((o) => o.customerId == userId).toList();
    if (startDate != null) {
      list = list
          .where(
            (o) =>
                o.createdAt.isAfter(startDate) ||
                o.createdAt.isAtSameMomentAs(startDate),
          )
          .toList();
    }
    if (endDate != null) {
      list = list
          .where(
            (o) =>
                o.createdAt.isBefore(endDate) ||
                o.createdAt.isAtSameMomentAs(endDate),
          )
          .toList();
    }
    return list;
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
  Future<PaginationResult<OrderModel>> getAllOrders({
    String? keyword,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  }) async {
    var list = orders;
    if (status != null && status != 'all') {
      if (status == 'refunded') {
        list = list
            .where(
              (o) =>
                  o.paymentStatus == 'refunded' ||
                  o.paymentStatus == 'partially_refunded',
            )
            .toList();
      } else {
        list = list.where((o) => o.status == status).toList();
      }
    }
    if (keyword != null && keyword.trim().isNotEmpty) {
      final q = keyword.trim().toLowerCase();
      list = list
          .where(
            (o) =>
                o.orderCode.toLowerCase().contains(q) ||
                o.customerName.toLowerCase().contains(q) ||
                (o.customerPhone ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    if (startDate != null) {
      list = list
          .where(
            (o) =>
                o.createdAt.isAfter(startDate) ||
                o.createdAt.isAtSameMomentAs(startDate),
          )
          .toList();
    }
    if (endDate != null) {
      list = list
          .where(
            (o) =>
                o.createdAt.isBefore(endDate) ||
                o.createdAt.isAtSameMomentAs(endDate),
          )
          .toList();
    }
    final totalCount = list.length;
    final offset = (page - 1) * pageSize;
    final end = offset + pageSize;
    final paginated = list.sublist(offset, end > totalCount ? totalCount : end);
    return PaginationResult(
      items: paginated,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
    );
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

  @override
  Future<ProductModel> getProduct(String productId) async {
    return _buildProduct(stock: 4);
  }
}
