import 'package:flutter/material.dart';
import '../repository/admin_brand_repository.dart';
import '../../../../data/models/brand_model.dart';

class BrandFormViewModel extends ChangeNotifier {
  final AdminBrandRepository _repository = AdminBrandRepository();

  BrandModel? _brand;
  bool _isLoading = false;
  String? _errorMessage;

  String _name = '';
  String? _description;
  String? _logoUrl;
  bool _isActive = true;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  BrandModel? get brand => _brand;
  bool get isEditing => _brand != null;

  String get name => _name;
  String? get description => _description;
  String? get logoUrl => _logoUrl;
  bool get isActive => _isActive;

  bool get isChanged {
    if (_brand == null) {
      return _name.trim().isNotEmpty ||
          (_description != null && _description!.trim().isNotEmpty) ||
          (_logoUrl != null && _logoUrl!.trim().isNotEmpty);
    }
    final nameChanged = _name.trim() != _brand!.name.trim();
    final descriptionChanged =
        (_description ?? '').trim() != (_brand!.description ?? '').trim();
    final logoUrlChanged =
        (_logoUrl ?? '').trim() != (_brand!.logoUrl ?? '').trim();
    final isActiveChanged = _isActive != _brand!.isActive;
    return nameChanged || descriptionChanged || logoUrlChanged || isActiveChanged;
  }

  void init(BrandModel? brand) {
    _brand = brand;
    if (brand != null) {
      _name = brand.name;
      _description = brand.description;
      _logoUrl = brand.logoUrl;
      _isActive = brand.isActive;
    } else {
      _name = '';
      _description = '';
      _logoUrl = '';
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

  void setLogoUrl(String value) {
    _logoUrl = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    _isActive = value;
    notifyListeners();
  }

  Future<bool> save() async {
    if (_name.trim().isEmpty) {
      _errorMessage = 'Tên nhãn hàng không được để trống.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final target = BrandModel(
        id: _brand?.id ?? '',
        name: _name,
        description: _description,
        logoUrl: _logoUrl,
        isActive: _isActive,
      );

      if (isEditing) {
        await _repository.updateBrand(target);
      } else {
        await _repository.createBrand(target);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể lưu nhãn hàng. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBrand() async {
    if (_brand == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteBrand(_brand!.id);
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
