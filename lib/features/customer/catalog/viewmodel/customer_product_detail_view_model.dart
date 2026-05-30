import 'package:flutter/material.dart';
import '../../../../data/models/products_model.dart';
import '../repository/customer_product_repository.dart';

class CustomerProductDetailViewModel extends ChangeNotifier {
  final CustomerProductRepository _repository = CustomerProductRepository();

  ProductModel? _product;
  bool _isLoading = false;
  String? _errorMessage;

  ProductModel? get product => _product;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProduct(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _product = await _repository.getActiveProduct(id);
    } catch (_) {
      _errorMessage = 'Không thể tải thông tin sản phẩm.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
