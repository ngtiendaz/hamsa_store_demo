import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/admin_dashboard_stats_model.dart';

abstract class AdminDashboardDataSource {
  Future<AdminDashboardStatsModel> getStats(
    String period,
    DateTime referenceDate,
  );
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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
