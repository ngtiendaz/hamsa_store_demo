import 'package:flutter/material.dart';
import '../repository/admin_brand_repository.dart';
import '../../../../data/models/brand_model.dart';
import '../../../../core/utils/debounce.dart';

class BrandListViewModel extends ChangeNotifier {
  final AdminBrandRepository _repository = AdminBrandRepository();
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 500));

  List<BrandModel> _brands = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _keyword = '';
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalCount = 0;

  List<BrandModel> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get keyword => _keyword;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get totalPages => _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();
  bool get hasNextPage => (_currentPage * _pageSize) < _totalCount;
  bool get hasPreviousPage => _currentPage > 1;

  BrandListViewModel() {
    loadBrands();
  }

  Future<void> loadBrands({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getBrands(
        searchQuery: _keyword,
        page: _currentPage,
        pageSize: _pageSize,
      );

      _brands = result.items;
      _totalCount = result.totalCount;
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách nhãn hàng. Vui lòng thử lại.';
      debugPrint('Error loading brands: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setKeyword(String value) {
    _keyword = value;
    _debounce.run(() {
      loadBrands(refresh: true);
    });
  }

  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      loadBrands();
    }
  }

  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      loadBrands();
    }
  }

  Future<bool> deleteBrand(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteBrand(id);
      await loadBrands();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }
}
