import 'package:flutter/material.dart';
import '../repository/admin_category_repository.dart';
import '../../../../data/models/category_model.dart';

class CategoryFormViewModel extends ChangeNotifier {
  final AdminCategoryRepository _repository = AdminCategoryRepository();

  CategoryModel? _category;
  bool _isLoading = false;
  String? _errorMessage;

  String _name = '';
  String? _description;
  bool _isActive = true;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  CategoryModel? get category => _category;
  bool get isEditing => _category != null;

  String get name => _name;
  String? get description => _description;
  bool get isActive => _isActive;

  bool get isChanged {
    if (_category == null) {
      return _name.trim().isNotEmpty || (_description != null && _description!.trim().isNotEmpty);
    }
    final nameChanged = _name.trim() != _category!.name.trim();
    final descriptionChanged = (_description ?? '').trim() != (_category!.description ?? '').trim();
    final isActiveChanged = _isActive != _category!.isActive;
    return nameChanged || descriptionChanged || isActiveChanged;
  }

  void init(CategoryModel? category) {
    _category = category;
    if (category != null) {
      _name = category.name;
      _description = category.description;
      _isActive = category.isActive;
    } else {
      _name = '';
      _description = '';
      _isActive = true;
    }
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    _isActive = value;
    notifyListeners();
  }

  Future<bool> save() async {
    if (_name.trim().isEmpty) {
      _errorMessage = 'Tên danh mục không được để trống.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final target = CategoryModel(
        id: _category?.id ?? '',
        name: _name,
        description: _description,
        isActive: _isActive,
      );

      if (isEditing) {
        await _repository.updateCategory(target);
      } else {
        await _repository.createCategory(target);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể lưu danh mục. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory() async {
    if (_category == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteCategory(_category!.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
