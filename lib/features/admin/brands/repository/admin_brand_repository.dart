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
    // 1. Tìm hoặc tự động tạo nhãn hàng "Khác" làm mặc định
    final defaultBrandQuery = await _client
        .from('brands')
        .select()
        .eq('name', 'Khác')
        .maybeSingle();

    String defaultBrandId;
    if (defaultBrandQuery == null) {
      final insertResult = await _client
          .from('brands')
          .insert({
            'name': 'Khác',
            'description': 'Nhãn hàng mặc định',
            'is_active': true,
          })
          .select()
          .single();
      defaultBrandId = insertResult['id'] as String;
    } else {
      defaultBrandId = defaultBrandQuery['id'] as String;
    }

    // Nếu nhãn hàng muốn xóa chính là nhãn hàng "Khác", chặn lại
    if (brandId == defaultBrandId) {
      throw Exception('Không thể xóa nhãn hàng mặc định "Khác".');
    }

    // 2. Chuyển tất cả sản phẩm của nhãn hàng cần xóa sang nhãn hàng "Khác"
    await _client
        .from('products')
        .update({'brand_id': defaultBrandId})
        .eq('brand_id', brandId);

    // 3. Tiến hành xóa nhãn hàng
    await _client.from('brands').delete().eq('id', brandId);
  }
}
