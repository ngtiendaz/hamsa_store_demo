import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/products_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/brand_model.dart';
import '../../../../data/dto/pagination_result.dart';

class AdminProductRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<PaginationResult<ProductModel>> getProducts({
    String? keyword,
    String? categoryId,
    String? brandId,
    int page = 1,
    int pageSize = 20,
  }) async {
    var query = _client
        .from('products')
        .select('*, product_images(image_url)');

    // Exclude hard-deleted items
    query = query.isFilter('deleted_at', null);

    if (keyword != null && keyword.trim().isNotEmpty) {
      final k = '%${keyword.trim()}%';
      query = query.or('internal_name.ilike.$k,trade_name.ilike.$k,barcode.ilike.$k');
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

    final List<dynamic> data = response.data;
    final int count = response.count;

    final products = data.map((json) => ProductModel.fromJson(json)).toList();

    return PaginationResult<ProductModel>(
      items: products,
      totalCount: count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final response = await _client.from('products').insert(data).select().single();
    return ProductModel.fromJson(response);
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _client.from('products').update(data).eq('id', id);
  }

  Future<void> deleteProduct(String id, String userId) async {
    await _client.from('products').update({
      'status': 'inactive',
      'deleted_at': DateTime.now().toIso8601String(),
      'deleted_by': userId,
    }).eq('id', id);
  }

  Future<String> uploadProductImage(String fileName, Uint8List bytes) async {
    final path = 'uploads/$fileName';
    await _client.storage.from('product-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    final publicUrl = _client.storage.from('product-images').getPublicUrl(path);
    return publicUrl;
  }

  Future<void> saveProductImage(String productId, String imageUrl) async {
    // Xóa ảnh cũ
    await _client.from('product_images').delete().eq('product_id', productId);
    // Chèn ảnh mới
    await _client.from('product_images').insert({
      'product_id': productId,
      'image_url': imageUrl,
      'sort_order': 0,
    });
  }

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .order('name');
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<List<BrandModel>> getBrands() async {
    final response = await _client
        .from('brands')
        .select()
        .eq('is_active', true)
        .order('name');
    final List<dynamic> data = response as List<dynamic>;
    return data.map((json) => BrandModel.fromJson(json)).toList();
  }
}
