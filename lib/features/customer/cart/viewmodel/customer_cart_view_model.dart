import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../data/models/cart_model.dart';
import '../../../../data/models/products_model.dart';
import '../repository/customer_cart_repository.dart';

enum CartMutationResult { success, unauthenticated, outOfStock, busy, failed }

class CustomerCartEntry {
  final String id;
  final ProductModel product;
  final int quantity;

  const CustomerCartEntry({
    required this.id,
    required this.product,
    required this.quantity,
  });

  double get subtotal => product.price * quantity;

  CustomerCartEntry copyWith({String? id, int? quantity}) {
    return CustomerCartEntry(
      id: id ?? this.id,
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CustomerCartViewModel extends ChangeNotifier {
  final CustomerCartDataSource _repository;
  final Map<String, CustomerCartEntry> _entries = {};
  final Set<String> _pendingProductIds = {};
  final Set<String> _selectedProductIds = {};

  String? _userId;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  CustomerCartViewModel({CustomerCartDataSource? repository})
    : _repository = repository ?? CustomerCartRepository();

  List<CustomerCartEntry> get entries => _entries.values.toList();
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  int get itemCount => _entries.length;
  int get totalQuantity =>
      _entries.values.fold(0, (sum, entry) => sum + entry.quantity);
  double get totalAmount =>
      _entries.values.fold(0, (sum, entry) => sum + entry.subtotal);
  int get selectedItemCount => _selectedProductIds.length;
  double get selectedTotalAmount => _entries.entries
      .where((entry) => _selectedProductIds.contains(entry.key))
      .fold(0, (sum, entry) => sum + entry.value.subtotal);

  bool isProductPending(String productId) {
    return _pendingProductIds.contains(productId);
  }

  bool isProductSelected(String productId) {
    return _selectedProductIds.contains(productId);
  }

  void toggleProductSelection(String productId, bool? isSelected) {
    if (!_entries.containsKey(productId)) return;

    if (isSelected ?? false) {
      _selectedProductIds.add(productId);
    } else {
      _selectedProductIds.remove(productId);
    }
    notifyListeners();
  }

  void syncForUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _selectedProductIds.clear();
    scheduleMicrotask(() {
      if (userId == null) {
        _entries.clear();
        _pendingProductIds.clear();
        _selectedProductIds.clear();
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = null;
        notifyListeners();
      } else {
        loadCart(showLoading: true);
      }
    });
  }

  Future<void> loadCart({bool showLoading = false}) async {
    final userId = _userId;
    if (userId == null) return;
    if (_isLoading || _isRefreshing) return;

    if (showLoading && _entries.isEmpty) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final cart = await _repository.getActiveCart(userId);
      if (_userId != userId) return;
      _replaceEntries(cart);
    } catch (_) {
      if (_userId == userId) {
        _errorMessage = 'Không thể đồng bộ giỏ hàng. Vui lòng thử lại.';
      }
    } finally {
      if (_userId == userId) {
        _isLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  Future<CartMutationResult> addProduct(ProductModel product) async {
    final userId = _userId;
    if (userId == null) return CartMutationResult.unauthenticated;
    if (isProductPending(product.id)) return CartMutationResult.busy;

    final previousEntry = _entries[product.id];
    final quantity = (previousEntry?.quantity ?? 0) + 1;
    if (quantity > product.stock) return CartMutationResult.outOfStock;

    _pendingProductIds.add(product.id);
    _entries[product.id] = CustomerCartEntry(
      id: previousEntry?.id ?? 'pending-${product.id}',
      product: product,
      quantity: quantity,
    );
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addProduct(
        userId: userId,
        product: product,
        quantity: quantity,
      );
      await _reloadAfterMutation(userId);
      return CartMutationResult.success;
    } catch (_) {
      _restoreEntry(product.id, previousEntry);
      _errorMessage = 'Không thể thêm sản phẩm vào giỏ hàng.';
      return CartMutationResult.failed;
    } finally {
      _pendingProductIds.remove(product.id);
      notifyListeners();
    }
  }

  Future<CartMutationResult> decreaseQuantity(ProductModel product) async {
    final entry = _entries[product.id];
    if (entry == null) return CartMutationResult.failed;
    if (isProductPending(product.id)) return CartMutationResult.busy;

    final wasSelected = isProductSelected(product.id);
    _pendingProductIds.add(product.id);
    if (entry.quantity <= 1) {
      _entries.remove(product.id);
      _selectedProductIds.remove(product.id);
    } else {
      _entries[product.id] = entry.copyWith(quantity: entry.quantity - 1);
    }
    _errorMessage = null;
    notifyListeners();

    try {
      if (entry.quantity <= 1) {
        await _repository.deleteCartItem(entry.id);
      } else {
        await _repository.updateQuantity(
          cartItemId: entry.id,
          quantity: entry.quantity - 1,
        );
      }
      return CartMutationResult.success;
    } catch (_) {
      _entries[product.id] = entry;
      if (wasSelected) _selectedProductIds.add(product.id);
      _errorMessage = 'Không thể cập nhật số lượng sản phẩm.';
      return CartMutationResult.failed;
    } finally {
      _pendingProductIds.remove(product.id);
      notifyListeners();
    }
  }

  Future<CartMutationResult> removeProduct(String productId) async {
    final entry = _entries[productId];
    if (entry == null) return CartMutationResult.failed;
    if (isProductPending(productId)) return CartMutationResult.busy;

    final wasSelected = isProductSelected(productId);
    _pendingProductIds.add(productId);
    _entries.remove(productId);
    _selectedProductIds.remove(productId);
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCartItem(entry.id);
      return CartMutationResult.success;
    } catch (_) {
      _entries[productId] = entry;
      if (wasSelected) _selectedProductIds.add(productId);
      _errorMessage = 'Không thể xóa sản phẩm khỏi giỏ hàng.';
      return CartMutationResult.failed;
    } finally {
      _pendingProductIds.remove(productId);
      notifyListeners();
    }
  }

  Future<void> _reloadAfterMutation(String userId) async {
    final cart = await _repository.getActiveCart(userId);
    if (_userId == userId) _replaceEntries(cart);
  }

  void _replaceEntries(CartModel? cart) {
    _entries.clear();
    for (final item in cart?.items ?? const []) {
      if (item.product == null) continue;
      _entries[item.productId] = CustomerCartEntry(
        id: item.id,
        product: item.product!,
        quantity: item.quantity,
      );
    }
    _selectedProductIds.removeWhere(
      (productId) => !_entries.containsKey(productId),
    );
  }

  void _restoreEntry(String productId, CustomerCartEntry? entry) {
    if (entry == null) {
      _entries.remove(productId);
    } else {
      _entries[productId] = entry;
    }
  }
}
