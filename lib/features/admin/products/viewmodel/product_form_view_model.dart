import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../repository/admin_product_repository.dart';
import '../../../../data/models/products_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/brand_model.dart';

class ProductFormViewModel extends ChangeNotifier {
  final AdminProductRepository _repository = AdminProductRepository();

  ProductModel? _product;
  bool _isLoading = false;
  String? _errorMessage;

  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];

  // Form fields
  String _internalName = '';
  String? _tradeName;
  String? _barcode;
  String? _description;
  double _price = 0.0;
  int _stock = 0;
  String _status = 'active'; // 'active', 'inactive'
  String _categoryId = '';
  String _brandId = '';
  String? _imageUrl;

  // Local picked image state
  Uint8List? _pickedImageBytes;
  String? _pickedImageName;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditing => _product != null;

  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;

  // Getters for form fields
  String get internalName => _internalName;
  String? get tradeName => _tradeName;
  String? get barcode => _barcode;
  String? get description => _description;
  double get price => _price;
  int get stock => _stock;
  String get status => _status;
  String get categoryId => _categoryId;
  String get brandId => _brandId;
  String? get imageUrl => _imageUrl;

  Uint8List? get pickedImageBytes => _pickedImageBytes;
  String? get pickedImageName => _pickedImageName;

  ProductFormViewModel() {
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    try {
      _categories = await _repository.getCategories();
      _brands = await _repository.getBrands();
      // If we have categories/brands, set default selected ids
      if (_categoryId.isEmpty && _categories.isNotEmpty) {
        _categoryId = _categories.first.id;
      }
      if (_brandId.isEmpty && _brands.isNotEmpty) {
        _brandId = _brands.first.id;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  void init(ProductModel? product) {
    _product = product;
    if (product != null) {
      _internalName = product.internalName;
      _tradeName = product.tradeName;
      _barcode = product.barcode;
      _description = product.description;
      _price = product.price;
      _stock = product.stock;
      _status = product.status;
      _categoryId = product.categoryId;
      _brandId = product.brandId;
      _imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;
    }
    notifyListeners();
  }

  // Setters
  void setInternalName(String value) { _internalName = value; notifyListeners(); }
  void setTradeName(String value) { _tradeName = value.trim().isEmpty ? null : value; notifyListeners(); }
  void setBarcode(String value) { _barcode = value.trim().isEmpty ? null : value; notifyListeners(); }
  void setDescription(String value) { _description = value.trim().isEmpty ? null : value; notifyListeners(); }
  void setPrice(double value) { _price = value; notifyListeners(); }
  void setStock(int value) { _stock = value; notifyListeners(); }
  void setStatus(String value) { _status = value; notifyListeners(); }
  void setCategoryId(String value) { _categoryId = value; notifyListeners(); }
  void setBrandId(String value) { _brandId = value; notifyListeners(); }
  void setImageUrl(String value) { _imageUrl = value.trim().isEmpty ? null : value; notifyListeners(); }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        _pickedImageBytes = await image.readAsBytes();
        _pickedImageName = image.name;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Không thể chọn ảnh từ thiết bị: $e';
      notifyListeners();
    }
  }

  void clearPickedImage() {
    _pickedImageBytes = null;
    _pickedImageName = null;
    notifyListeners();
  }

  bool validate() {
    if (_internalName.trim().isEmpty) {
      _errorMessage = 'Tên nội bộ không được để trống.';
      notifyListeners();
      return false;
    }
    if (_price < 0) {
      _errorMessage = 'Giá sản phẩm phải lớn hơn hoặc bằng 0.';
      notifyListeners();
      return false;
    }
    if (_stock < 0) {
      _errorMessage = 'Số lượng tồn kho phải lớn hơn hoặc bằng 0.';
      notifyListeners();
      return false;
    }
    if (_categoryId.isEmpty) {
      _errorMessage = 'Vui lòng chọn danh mục sản phẩm.';
      notifyListeners();
      return false;
    }
    if (_brandId.isEmpty) {
      _errorMessage = 'Vui lòng chọn nhãn hàng.';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> save(String userId) async {
    if (!validate()) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final data = {
      'category_id': _categoryId,
      'brand_id': _brandId,
      'internal_name': _internalName,
      'trade_name': _tradeName,
      'barcode': _barcode,
      'description': _description,
      'price': _price,
      'stock': _stock,
      'status': _status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      // 1. Tải ảnh lên Supabase Storage nếu có ảnh mới được chọn
      String? uploadedImageUrl;
      if (_pickedImageBytes != null && _pickedImageName != null) {
        final extension = _pickedImageName!.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
        uploadedImageUrl = await _repository.uploadProductImage(fileName, _pickedImageBytes!);
      }

      // 2. Lưu sản phẩm
      String productId;
      if (isEditing) {
        productId = _product!.id;
        data['updated_by'] = userId;
        await _repository.updateProduct(productId, data);
      } else {
        data['created_by'] = userId;
        data['created_at'] = DateTime.now().toIso8601String();
        final newProduct = await _repository.createProduct(data);
        productId = newProduct.id;
      }

      // 3. Cập nhật bảng product_images nếu có ảnh mới
      if (uploadedImageUrl != null) {
        await _repository.saveProductImage(productId, uploadedImageUrl);
        _imageUrl = uploadedImageUrl;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể lưu sản phẩm. Vui lòng kiểm tra lại: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String userId) async {
    if (!isEditing) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteProduct(_product!.id, userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa (ngừng bán) sản phẩm này: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
