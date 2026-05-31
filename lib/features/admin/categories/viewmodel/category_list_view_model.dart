import 'package:flutter/material.dart';
import '../repository/admin_category_repository.dart';
import '../../../../data/models/category_model.dart';
import '../../../../core/utils/debounce.dart';

class CategoryListViewModel extends ChangeNotifier {
  final AdminCategoryRepository _repository = AdminCategoryRepository();
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 500));

  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  String _keyword = '';
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalCount = 0;
  int _requestVersion = 0;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get keyword => _keyword;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get totalPages => _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();
  bool get hasNextPage => (_currentPage * _pageSize) < _totalCount;
  bool get hasPreviousPage => _currentPage > 1;

  CategoryListViewModel() {
    loadCategories();
  }

  Future<void> loadCategories({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }

    final requestVersion = ++_requestVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getCategories(
        searchQuery: _keyword,
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (requestVersion != _requestVersion) return;

      _categories = result.items;
      _totalCount = result.totalCount;
    } catch (e) {
      if (requestVersion == _requestVersion) {
        _errorMessage = 'Không thể tải danh sách danh mục. Vui lòng thử lại.';
        debugPrint('Error loading categories: $e');
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
      loadCategories(refresh: true);
    });
  }

  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      loadCategories();
    }
  }

  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      loadCategories();
    }
  }

  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteCategory(id);
      await loadCategories();
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
    _requestVersion++;
    _debounce.dispose();
    super.dispose();
  }
}
