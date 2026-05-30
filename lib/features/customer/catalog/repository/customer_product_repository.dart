import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/dto/pagination_result.dart';
import '../../../../data/models/brand_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/products_model.dart';

class CustomerProductRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<PaginationResult<ProductModel>> getActiveProducts({
    String? keyword,
    String? categoryId,
    String? brandId,
    int page = 1,
    int pageSize = 12,
  }) async {
    var query = _client
        .from('products')
        .select('*, product_images(image_url)')
        .eq('status', 'active')
        .isFilter('deleted_at', null);

    if (keyword != null && keyword.trim().isNotEmpty) {
      final value = '%${keyword.trim()}%';
      query = query.or(
        'internal_name.ilike.$value,trade_name.ilike.$value,barcode.ilike.$value',
      );
    }

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }

    if (brandId != null && brandId.isNotEmpty) {
      query = query.eq('brand_id', brandId);
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    final response = await query
        .order('created_at', ascending: false)
        .range(from, to)
        .count(CountOption.exact);
    final data = response.data as List<dynamic>;

    return PaginationResult<ProductModel>(
      items: data.map((json) => ProductModel.fromJson(json)).toList(),
      totalCount: response.count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<ProductModel> getActiveProduct(String id) async {
    final response = await _client
        .from('products')
        .select('*, product_images(image_url)')
        .eq('id', id)
        .eq('status', 'active')
        .isFilter('deleted_at', null)
        .single();
    return ProductModel.fromJson(response);
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('name');
    final data = response as List<dynamic>;
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<List<BrandModel>> getBrands() async {
    final response = await _client
        .from('brands')
        .select()
        .eq('is_active', true)
        .order('name');
    final data = response as List<dynamic>;
    return data.map((json) => BrandModel.fromJson(json)).toList();
  }
}
