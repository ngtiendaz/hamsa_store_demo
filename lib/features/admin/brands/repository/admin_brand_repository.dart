import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/brand_model.dart';
import '../../../../data/dto/pagination_result.dart';

class AdminBrandRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<PaginationResult<BrandModel>> getBrands({
    String? searchQuery,
    required int page,
    required int pageSize,
  }) async {
    final offset = (page - 1) * pageSize;

    var query = _client.from('brands').select('*');

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.ilike('name', '%${searchQuery.trim()}%');
    }

    final response = await query
        .order('name', ascending: true)
        .range(offset, offset + pageSize - 1)
        .count(CountOption.exact);

    final List<dynamic> data = response.data;
    final int count = response.count;

    final brands = data.map((json) => BrandModel.fromJson(json)).toList();

    return PaginationResult<BrandModel>(
      items: brands,
      totalCount: count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> createBrand(BrandModel brand) async {
    await _client.from('brands').insert({
      'name': brand.name.trim(),
      'description': brand.description?.trim(),
      'logo_url': brand.logoUrl?.trim(),
      'is_active': brand.isActive,
    });
  }

  Future<void> updateBrand(BrandModel brand) async {
    await _client
        .from('brands')
        .update({
          'name': brand.name.trim(),
          'description': brand.description?.trim(),
          'logo_url': brand.logoUrl?.trim(),
          'is_active': brand.isActive,
        })
        .eq('id', brand.id);
  }

  Future<void> deleteBrand(String brandId) async {
    await _client.rpc(
      'admin_delete_brand',
      params: {'p_brand_id': brandId},
    );
  }
}
