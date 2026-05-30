import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/dto/pagination_result.dart';

class AdminCategoryRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<PaginationResult<CategoryModel>> getCategories({
    String? searchQuery,
    required int page,
    required int pageSize,
  }) async {
    final offset = (page - 1) * pageSize;

    var query = _client.from('categories').select('*');

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      query = query.ilike('name', '%${searchQuery.trim()}%');
    }

    final response = await query
        .order('name', ascending: true)
        .range(offset, offset + pageSize - 1)
        .count(CountOption.exact);

    final List<dynamic> data = response.data;
    final int count = response.count;

    final categories =
        data.map((json) => CategoryModel.fromJson(json)).toList();

    return PaginationResult<CategoryModel>(
      items: categories,
      totalCount: count,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> createCategory(CategoryModel category) async {
    await _client.from('categories').insert({
      'name': category.name.trim(),
      'description': category.description?.trim(),
      'is_active': category.isActive,
    });
  }

  Future<void> updateCategory(CategoryModel category) async {
    await _client.from('categories').update({
      'name': category.name.trim(),
      'description': category.description?.trim(),
      'is_active': category.isActive,
    }).eq('id', category.id);
  }

  Future<void> deleteCategory(String categoryId) async {
    // 1. Tìm hoặc tự động tạo danh mục "Khác" làm mặc định
    final defaultCatQuery = await _client
        .from('categories')
        .select()
        .eq('name', 'Khác')
        .maybeSingle();

    String defaultCategoryId;
    if (defaultCatQuery == null) {
      final insertResult = await _client.from('categories').insert({
        'name': 'Khác',
        'description': 'Danh mục mặc định',
        'is_active': true,
      }).select().single();
      defaultCategoryId = insertResult['id'] as String;
    } else {
      defaultCategoryId = defaultCatQuery['id'] as String;
    }

    // Nếu danh mục muốn xóa chính là danh mục "Khác", chặn lại
    if (categoryId == defaultCategoryId) {
      throw Exception('Không thể xóa danh mục mặc định "Khác".');
    }

    // 2. Chuyển tất cả sản phẩm của danh mục cần xóa sang danh mục "Khác"
    await _client
        .from('products')
        .update({'category_id': defaultCategoryId})
        .eq('category_id', categoryId);

    // 3. Tiến hành xóa danh mục
    await _client.from('categories').delete().eq('id', categoryId);
  }
}
