import 'package:flutter_test/flutter_test.dart';
import 'package:hamsa_store_demo/data/models/cart_item_model.dart';
import 'package:hamsa_store_demo/data/models/cart_model.dart';
import 'package:hamsa_store_demo/data/models/products_model.dart';
import 'package:hamsa_store_demo/features/customer/cart/repository/customer_cart_repository.dart';
import 'package:hamsa_store_demo/features/customer/cart/viewmodel/customer_cart_view_model.dart';

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
