import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../repository/admin_product_repository.dart';
import '../../../../data/models/products_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/brand_model.dart';

class ProductImageItem {
  final String? url; // null nếu là ảnh mới
  final Uint8List? bytes; // null nếu là ảnh cũ trên server
  final String id; // unique id để phân biệt

  ProductImageItem({this.url, this.bytes, required this.id});
}

class ProductFormViewModel extends ChangeNotifier {
  final AdminProductRepository _repository = AdminProductRepository();

  ProductModel? _product;
  bool _isLoading = false;
  String? _errorMessage;
  String? _deleteResult;

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

  // Images list
  List<ProductImageItem> _images = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get deleteResult => _deleteResult;
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
  
  List<ProductImageItem> get images => _images;

  bool get isChanged {
    if (_product == null) {
      return _internalName.trim().isNotEmpty ||
          (_tradeName != null && _tradeName!.trim().isNotEmpty) ||
          (_barcode != null && _barcode!.trim().isNotEmpty) ||
          (_description != null && _description!.trim().isNotEmpty) ||
          _price > 0 ||
          _stock > 0 ||
          _images.isNotEmpty;
    }
    
    final nameChanged = _internalName.trim() != _product!.internalName.trim();
    final tradeNameChanged = (_tradeName ?? '').trim() != (_product!.tradeName ?? '').trim();
    final barcodeChanged = (_barcode ?? '').trim() != (_product!.barcode ?? '').trim();
    final descriptionChanged = (_description ?? '').trim() != (_product!.description ?? '').trim();
    final priceChanged = _price != _product!.price;
    final stockChanged = _stock != _product!.stock;
    final statusChanged = _status != _product!.status;
    final categoryChanged = _categoryId != _product!.categoryId;
    final brandChanged = _brandId != _product!.brandId;
    
    bool imagesChanged = false;
    if (_images.length != _product!.imageUrls.length) {
      imagesChanged = true;
    } else {
      for (int i = 0; i < _images.length; i++) {
        if (_images[i].url != _product!.imageUrls[i]) {
          imagesChanged = true;
          break;
        }
      }
    }
    
    return nameChanged ||
        tradeNameChanged ||
        barcodeChanged ||
        descriptionChanged ||
        priceChanged ||
        stockChanged ||
        statusChanged ||
        categoryChanged ||
        brandChanged ||
        imagesChanged;
  }

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
    _images = [];
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
      _images = product.imageUrls.map((url) => ProductImageItem(url: url, id: url)).toList();
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

  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFiles.isNotEmpty) {
        for (final file in pickedFiles) {
          final bytes = await file.readAsBytes();
          _images.add(ProductImageItem(
            bytes: bytes,
            id: '${DateTime.now().microsecondsSinceEpoch}_${file.name}',
          ));
        }
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Không thể chọn ảnh từ thiết bị: $e';
      notifyListeners();
    }
  }

  void removeImage(ProductImageItem item) {
    _images.remove(item);
    notifyListeners();
  }

  bool validate() {
    if (_internalName.trim().isEmpty) {
      _errorMessage = 'Tên nội bộ không được để trống.';
      notifyListeners();
      return false;
    }
    if ((_tradeName ?? '').trim().isEmpty) {
      _errorMessage = 'Tên thương mại không được để trống.';
      notifyListeners();
      return false;
    }
    if (_price <= 0) {
      _errorMessage = 'Đơn giá phải lớn hơn 0.';
      notifyListeners();
      return false;
    }
    if (_stock <= 0) {
      _errorMessage = 'Số lượng tồn kho phải lớn hơn 0.';
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
      'internal_name': _internalName.trim(),
      'trade_name': _tradeName!.trim(),
      'barcode': _barcode,
      'description': _description,
      'price': _price,
      'stock': _stock,
      'status': _status,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      // 1. Tải các ảnh mới chọn lên Supabase Storage
      final List<String> finalImageUrls = [];
      for (final item in _images) {
        if (item.url != null) {
          finalImageUrls.add(item.url!);
        } else if (item.bytes != null) {
          final extension = item.id.split('.').last.toLowerCase();
          final safeExtension = (extension == 'png' || extension == 'jpeg' || extension == 'webp') ? extension : 'jpg';
          final cleanUnique = UniqueKey().toString().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$cleanUnique.$safeExtension';
          final url = await _repository.uploadProductImage(fileName, item.bytes!);
          finalImageUrls.add(url);
        }
      }

      // 2. Lưu sản phẩm chính
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

      // 3. Đồng bộ lại toàn bộ danh sách hình ảnh của sản phẩm
      await _repository.saveProductImages(productId, finalImageUrls);

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
    _deleteResult = null;
    notifyListeners();
    try {
      _deleteResult = await _repository.deleteProduct(_product!.id, userId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể xóa sản phẩm này: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
