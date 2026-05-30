import 'package:flutter/material.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../data/models/brand_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/products_model.dart';
import '../repository/customer_product_repository.dart';

class CustomerHomeViewModel extends ChangeNotifier {
  final CustomerProductRepository _repository = CustomerProductRepository();
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 400));

  final List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  String _keyword = '';
  String? _selectedCategoryId;
  String? _selectedBrandId;
  int _currentPage = 1;
  int _totalCount = 0;
  int _requestVersion = 0;
  static const int _pageSize = 12;

  List<ProductModel> get products => List.unmodifiable(_products);
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedBrandId => _selectedBrandId;
  bool get hasMore => _products.length < _totalCount;

  CustomerHomeViewModel() {
    loadFilters();
    loadProducts(refresh: true);
  }

  Future<void> loadFilters() async {
    try {
      final result = await Future.wait([
        _repository.getCategories(),
        _repository.getBrands(),
      ]);
      _categories = result[0] as List<CategoryModel>;
      _brands = result[1] as List<BrandModel>;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Không thể tải bộ lọc sản phẩm.';
      notifyListeners();
    }
  }

  Future<void> loadProducts({bool refresh = false}) async {
    if (!refresh && (_isLoading || _isLoadingMore)) return;
    final requestVersion = ++_requestVersion;

    if (refresh) {
      _currentPage = 1;
      _isLoading = true;
      _isLoadingMore = false;
    } else {
      if (!hasMore) return;
      _isLoadingMore = true;
    }
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getActiveProducts(
        keyword: _keyword,
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (requestVersion != _requestVersion) return;

      if (refresh) {
        _products
          ..clear()
          ..addAll(result.items);
      } else {
        _products.addAll(result.items);
      }
      _totalCount = result.totalCount;
    } catch (_) {
      if (requestVersion == _requestVersion) {
        _errorMessage = 'Không thể tải danh sách sản phẩm. Vui lòng thử lại.';
      }
    } finally {
      if (requestVersion == _requestVersion) {
        _isLoading = false;
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || _isLoading || _isLoadingMore) return;
    _currentPage++;
    await loadProducts();
  }

  void setKeyword(String value) {
    _keyword = value;
    _debounce.run(() => loadProducts(refresh: true));
  }

  void setCategory(String? value) {
    _selectedCategoryId = value;
    loadProducts(refresh: true);
  }

  void setBrand(String? value) {
    _selectedBrandId = value;
    loadProducts(refresh: true);
  }

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }
}
