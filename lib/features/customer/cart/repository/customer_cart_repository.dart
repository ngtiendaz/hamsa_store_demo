import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/cart_model.dart';
import '../../../../data/models/products_model.dart';

abstract class CustomerCartDataSource {
  Future<CartModel?> getActiveCart(String userId);

  Future<void> addProduct({
    required String userId,
    required ProductModel product,
    required int quantity,
  });

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  });

  Future<void> deleteCartItem(String cartItemId);
}

class CustomerCartRepository implements CustomerCartDataSource {
  final SupabaseClient _client;

  CustomerCartRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<CartModel?> getActiveCart(String userId) async {
    final response = await _client
        .from('carts')
        .select('*, cart_items(*, products(*, product_images(image_url)))')
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();
    if (response == null) return null;
    return CartModel.fromJson(response);
  }

  @override
  Future<void> addProduct({
    required String userId,
    required ProductModel product,
    required int quantity,
  }) async {
    final cartId = await _getOrCreateActiveCartId(userId);
    final existingItem = await _client
        .from('cart_items')
        .select('id')
        .eq('cart_id', cartId)
        .eq('product_id', product.id)
        .maybeSingle();

    if (existingItem == null) {
      await _client.from('cart_items').insert({
        'cart_id': cartId,
        'product_id': product.id,
        'quantity': quantity,
        'price_snapshot': product.price,
      });
      return;
    }

    await _client
        .from('cart_items')
        .update({'quantity': quantity, 'price_snapshot': product.price})
        .eq('id', existingItem['id'] as String);
  }

  @override
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    await _client
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  @override
  Future<void> deleteCartItem(String cartItemId) async {
    await _client.from('cart_items').delete().eq('id', cartItemId);
  }

  Future<String> _getOrCreateActiveCartId(String userId) async {
    final currentCart = await _client
        .from('carts')
        .select('id')
        .eq('user_id', userId)
        .eq('status', 'active')
        .maybeSingle();
    if (currentCart != null) return currentCart['id'] as String;

    try {
      final response = await _client
          .from('carts')
          .insert({'user_id': userId, 'status': 'active'})
          .select('id')
          .single();
      return response['id'] as String;
    } catch (_) {
      final existingCart = await _client
          .from('carts')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();
      if (existingCart != null) return existingCart['id'] as String;
      rethrow;
    }
  }
}
