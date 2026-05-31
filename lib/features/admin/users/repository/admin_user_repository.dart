import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/dto/pagination_result.dart';
import '../../../../data/models/profiles_model.dart';

class AdminUserRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<PaginationResult<ProfileModel>> getUsers({
    String? keyword,
    String? role,
    bool? isActive,
    required int page,
    required int pageSize,
  }) async {
    final offset = (page - 1) * pageSize;
    var query = _client.from('profiles').select('*');

    if (keyword != null && keyword.trim().isNotEmpty) {
      final value = keyword.trim();
      query = query.or('name.ilike.%$value%,email.ilike.%$value%');
    }
    if (role != null) {
      query = query.eq('role', role);
    }
    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + pageSize - 1)
        .count(CountOption.exact);
    final users = (response.data as List<dynamic>)
        .map((json) => ProfileModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return PaginationResult(
      items: users,
      totalCount: response.count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? avatarUrl,
    required bool isAdmin,
  }) async {
    final response = await _client.functions.invoke(
      'admin-create-user',
      body: {
        'email': email,
        'password': password,
        'name': name,
        'phone': phone,
        'avatar_url': avatarUrl,
        'is_admin': isAdmin,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      final data = response.data;
      throw Exception(
        data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Không thể thêm nhân viên.',
      );
    }
  }

  Future<void> updateUser({
    required String id,
    required String name,
    String? phone,
    String? avatarUrl,
    required String role,
    required bool isActive,
  }) async {
    await _client
        .from('profiles')
        .update({
          'name': name.trim(),
          'phone': _nullIfEmpty(phone),
          'avatar_url': _nullIfEmpty(avatarUrl),
          'role': role,
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deactivateUser(String id) async {
    await _client
        .from('profiles')
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
