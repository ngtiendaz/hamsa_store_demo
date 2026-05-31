import 'package:flutter/material.dart';
import '../repository/admin_product_repository.dart';
import '../../../../data/models/products_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/brand_model.dart';
import '../../../../core/utils/debounce.dart';

class ProductListViewModel extends ChangeNotifier {
  final AdminProductRepository _repository = AdminProductRepository();
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 500));

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Search & Filter state
  String _keyword = '';
  String? _selectedCategoryId;
  String? _selectedBrandId;

  // Pagination state
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalCount = 0;
  int _requestVersion = 0;

  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get keyword => _keyword;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedBrandId => _selectedBrandId;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get totalPages => _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();
  bool get hasNextPage => (_currentPage * _pageSize) < _totalCount;
  bool get hasPreviousPage => _currentPage > 1;

  ProductListViewModel() {
    loadFilters();
    loadProducts();
  }

  Future<void> loadFilters() async {
    try {
      final cats = await _repository.getCategories();
      final brs = await _repository.getBrands();
      _categories = cats;
      _brands = brs;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    final requestVersion = ++_requestVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getProducts(
        keyword: _keyword,
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (requestVersion != _requestVersion) return;

      _products = result.items;
      _totalCount = result.totalCount;
    } catch (e) {
      if (requestVersion == _requestVersion) {
        _errorMessage = 'Không thể tải danh sách sản phẩm. Vui lòng thử lại.';
        debugPrint('Error loading products: $e');
      }
    } finally {
      if (requestVersion == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setKeyword(String value) {
    _keyword = value;
    _debounce.run(() {
      loadProducts(refresh: true);
    });
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    loadProducts(refresh: true);
  }

  void selectBrand(String? brandId) {
    _selectedBrandId = brandId;
    loadProducts(refresh: true);
  }

  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      loadProducts();
    }
  }

  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      loadProducts();
    }
  }

  Future<bool> deleteProduct(String id, String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteProduct(id, userId);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa sản phẩm.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _requestVersion++;
    _debounce.dispose();
    super.dispose();
  }
}
