import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../data/models/order_model.dart';

abstract class AdminOrderDataSource {
  Future<List<OrderModel>> getAllOrders();
  Future<void> confirmOrder(String orderId, String adminId);
  Future<void> approveCancelOrder(String orderId, String adminId);
}

class AdminOrderRepository implements AdminOrderDataSource {
  final SupabaseClient _client;

  AdminOrderRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);
      
      final data = response as List<dynamic>;
      return data.map((json) => OrderModel.fromJson(json as Map<String, dynamic>)).toList();
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
}
