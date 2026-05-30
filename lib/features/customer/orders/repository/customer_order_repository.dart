import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../data/models/order_model.dart';

abstract class CustomerOrderDataSource {
  Future<List<OrderModel>> getActiveOrders(String userId);
  Future<String> createOrder({
    required String userId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? note,
    required String paymentMethod,
    required List<String> cartItemIds,
    required String orderCode,
  });
  Future<void> requestCancelOrder(String orderId, String userId);
  Future<void> cancelRequestCancelOrder(String orderId, String userId);
  Future<void> requestReturnOrder(String orderId, String userId);
  Future<void> cancelRequestReturnOrder(String orderId, String userId);
  Future<void> updateOrderInfo({
    required String orderId,
    required String userId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? note,
  });
}

class CustomerOrderRepository implements CustomerOrderDataSource {
  final SupabaseClient _client;

  CustomerOrderRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<OrderModel>> getActiveOrders(String userId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*, products(*, product_images(image_url)))')
          .eq('customer_id', userId)
          .order('created_at', ascending: false);
      
      final data = response as List<dynamic>;
      return data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Không thể tải lịch sử đơn hàng của bạn.');
    }
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
    try {
      final response = await _client.rpc(
        'create_order',
        params: {
          'p_user_id': userId,
          'p_customer_name': customerName,
          'p_customer_phone': customerPhone,
          'p_customer_address': customerAddress,
          'p_note': note ?? '',
          'p_payment_method': paymentMethod,
          'p_cart_item_ids': cartItemIds,
          'p_order_code': orderCode,
        },
      );
      return response as String;
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> requestCancelOrder(String orderId, String userId) async {
    try {
      await _client.rpc(
        'request_cancel_order',
        params: {
          'p_order_id': orderId,
          'p_user_id': userId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> cancelRequestCancelOrder(String orderId, String userId) async {
    try {
      await _client.rpc(
        'cancel_request_cancel_order',
        params: {
          'p_order_id': orderId,
          'p_user_id': userId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> requestReturnOrder(String orderId, String userId) async {
    try {
      await _client.rpc(
        'customer_request_return_order',
        params: {
          'p_order_id': orderId,
          'p_user_id': userId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> cancelRequestReturnOrder(String orderId, String userId) async {
    try {
      await _client.rpc(
        'customer_cancel_request_return_order',
        params: {
          'p_order_id': orderId,
          'p_user_id': userId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
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
    try {
      await _client
          .from('orders')
          .update({
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'customer_address': customerAddress,
            'note': note ?? '',
          })
          .eq('id', orderId)
          .eq('customer_id', userId);
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }
}
