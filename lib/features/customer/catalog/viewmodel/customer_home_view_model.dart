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
  String? _errorMessage;
  String _keyword = '';
  String? _selectedCategoryId;
  String? _selectedBrandId;
  int _currentPage = 1;
  int _totalCount = 0;
  int _requestVersion = 0;

  List<ProductModel> get products => List.unmodifiable(_products);
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedBrandId => _selectedBrandId;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get totalPages => _totalCount == 0
      ? 1
      : (_totalCount / CustomerProductRepository.pageSize).ceil();
  bool get hasPreviousPage => _currentPage > 1;
  bool get hasNextPage => _currentPage < totalPages;

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
    if (_isLoading && !refresh) return;
    final requestVersion = ++_requestVersion;

    if (refresh) {
      _currentPage = 1;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getActiveProducts(
        keyword: _keyword,
        categoryId: _selectedCategoryId,
        brandId: _selectedBrandId,
        page: _currentPage,
      );
      if (requestVersion != _requestVersion) return;

      _products
        ..clear()
        ..addAll(result.items);
      _totalCount = result.totalCount;
    } catch (_) {
      if (requestVersion == _requestVersion) {
        _errorMessage = 'Không thể tải danh sách sản phẩm. Vui lòng thử lại.';
      }
    } finally {
      if (requestVersion == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> nextPage() async {
    if (!hasNextPage || _isLoading) return;
    _currentPage++;
    await loadProducts();
  }

  Future<void> previousPage() async {
    if (!hasPreviousPage || _isLoading) return;
    _currentPage--;
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
