import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/admin_dashboard_stats_model.dart';
import '../../../../data/models/products_model.dart';

abstract class AdminDashboardDataSource {
  Future<AdminDashboardStatsModel> getStats(
    String period,
    DateTime referenceDate,
  );
  Future<ProductModel> getProduct(String productId);
}

class AdminDashboardRepository implements AdminDashboardDataSource {
  final SupabaseClient _client;

  AdminDashboardRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  @override
  Future<AdminDashboardStatsModel> getStats(
    String period,
    DateTime referenceDate,
  ) async {
    try {
      final response = await _client.rpc(
        'admin_get_dashboard_stats',
        params: {
          'p_period': period,
          'p_reference_date': _formatDate(referenceDate),
        },
      );

      return AdminDashboardStatsModel.fromJson(
        response as Map<String, dynamic>,
      );
    } catch (e) {
      final message = e
          .toString()
          .replaceAll('PostgrestException: ', '')
          .replaceAll('Exception: ', '');
      throw Exception(message);
    }
  }

  @override
  Future<ProductModel> getProduct(String productId) async {
    try {
      final response = await _client
          .from('products')
          .select('*, product_images(image_url)')
          .eq('id', productId)
          .single();
      return ProductModel.fromJson(response);
    } catch (e) {
      throw Exception('Không thể tải chi tiết sản phẩm.');
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
