import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../data/dto/pagination_result.dart';
import '../../../../../data/models/order_model.dart';

abstract class CustomerOrderDataSource {
  Future<PaginationResult<OrderModel>> getActiveOrders(
    String userId, {
    String? keyword,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  });
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
  Future<PaginationResult<OrderModel>> getActiveOrders(
    String userId, {
    String? keyword,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select('*, order_items(*, products(product_images(image_url)))')
          .eq('customer_id', userId);

      if (keyword != null && keyword.trim().isNotEmpty) {
        query = query.ilike('order_code', '%${keyword.trim()}%');
      }
      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }
      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final offset = (page - 1) * pageSize;
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + pageSize - 1)
          .count(CountOption.exact);

      final data = response.data as List<dynamic>;
      return PaginationResult(
        items: data
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList(),
        totalCount: response.count,
        page: page,
        pageSize: pageSize,
      );
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
      final msg = e
          .toString()
          .replaceAll('PostgrestException: ', '')
          .replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> requestCancelOrder(String orderId, String userId) async {
    try {
      await _client.rpc(
        'request_cancel_order',
        params: {'p_order_id': orderId, 'p_user_id': userId},
      );
    } catch (e) {
      final msg = e
          .toString()
          .replaceAll('PostgrestException: ', '')
          .replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> cancelRequestCancelOrder(String orderId, String userId) async {
    try {
      await _client.rpc(
        'cancel_request_cancel_order',
        params: {'p_order_id': orderId, 'p_user_id': userId},
      );
    } catch (e) {
      final msg = e
          .toString()
          .replaceAll('PostgrestException: ', '')
          .replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> requestReturnOrder(String orderId, String userId) async {
    try {
      await _client.rpc(
        'customer_request_return_order',
        params: {'p_order_id': orderId, 'p_user_id': userId},
      );
    } catch (e) {
      final msg = e
          .toString()
          .replaceAll('PostgrestException: ', '')
          .replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> cancelRequestReturnOrder(String orderId, String userId) async {
    try {
      await _client.rpc(
        'customer_cancel_request_return_order',
        params: {'p_order_id': orderId, 'p_user_id': userId},
      );
    } catch (e) {
      final msg = e
          .toString()
          .replaceAll('PostgrestException: ', '')
          .replaceAll('Exception: ', '');
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
      final msg = e
          .toString()
          .replaceAll('PostgrestException: ', '')
          .replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }
}
