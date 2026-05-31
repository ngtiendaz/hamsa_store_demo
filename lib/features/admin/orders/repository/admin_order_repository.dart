import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../data/models/order_model.dart';
import '../../../../../data/dto/pagination_result.dart';

abstract class AdminOrderDataSource {
  Future<PaginationResult<OrderModel>> getAllOrders({
    String? keyword,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    required int pageSize,
  });
  Future<void> confirmOrder(String orderId, String adminId);
  Future<void> approveCancelOrder(String orderId, String adminId);
  Future<void> deliverOrderSuccess(String orderId, String adminId);
  Future<void> deliverOrderFailed(String orderId, String adminId);
  Future<void> approveReturnOrder(String orderId, String adminId);
  Future<void> cancelPendingOrder(String orderId, String adminId);
  Future<void> rejectCancelOrder(String orderId, String adminId);
}

class AdminOrderRepository implements AdminOrderDataSource {
  final SupabaseClient _client;

  AdminOrderRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<PaginationResult<OrderModel>> getAllOrders({
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
          .select('*, order_items(*, products(*, product_images(image_url)))');

      if (status != null && status != 'all') {
        if (status == 'refunded') {
          query = query.inFilter('payment_status', ['refunded', 'partially_refunded']);
        } else {
          query = query.eq('status', status);
        }
      }

      if (keyword != null && keyword.trim().isNotEmpty) {
        final val = keyword.trim();
        query = query.or('order_code.ilike.%$val%,customer_name.ilike.%$val%,customer_phone.ilike.%$val%');
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
      final orders = data
          .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return PaginationResult(
        items: orders,
        totalCount: response.count,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      throw Exception('Không thể tải danh sách đơn hàng của hệ thống.');
    }
  }

  @override
  Future<void> confirmOrder(String orderId, String adminId) async {
    try {
      await _client.rpc(
        'admin_confirm_order',
        params: {
          'p_order_id': orderId,
          'p_admin_id': adminId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> approveCancelOrder(String orderId, String adminId) async {
    try {
      await _client.rpc(
        'admin_approve_cancel_order',
        params: {
          'p_order_id': orderId,
          'p_admin_id': adminId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> deliverOrderSuccess(String orderId, String adminId) async {
    try {
      await _client.rpc(
        'admin_deliver_order_success',
        params: {
          'p_order_id': orderId,
          'p_admin_id': adminId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> deliverOrderFailed(String orderId, String adminId) async {
    try {
      await _client.rpc(
        'admin_deliver_order_failed',
        params: {
          'p_order_id': orderId,
          'p_admin_id': adminId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> approveReturnOrder(String orderId, String adminId) async {
    try {
      await _client.rpc(
        'admin_approve_return_order',
        params: {
          'p_order_id': orderId,
          'p_admin_id': adminId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> cancelPendingOrder(String orderId, String adminId) async {
    try {
      await _client.rpc(
        'admin_cancel_pending_order',
        params: {
          'p_order_id': orderId,
          'p_admin_id': adminId,
        },
      );
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  @override
  Future<void> rejectCancelOrder(String orderId, String adminId) async {
    try {
      await _client
          .from('orders')
          .update({
            'status': 'pending_confirmation',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
    } catch (e) {
      final msg = e.toString().replaceAll('PostgrestException: ', '').replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }
}
