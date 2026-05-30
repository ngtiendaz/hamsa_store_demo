import 'package:flutter/material.dart';
import '../../../../data/models/profiles_model.dart';
import '../../../user/profile/repository/profile_repository.dart';
import '../../cart/viewmodel/customer_cart_view_model.dart';
import '../../orders/repository/customer_order_repository.dart';

class CheckoutViewModel extends ChangeNotifier {
  final CustomerOrderDataSource _orderRepository;
  final ProfileDataSource _profileRepository;

  String _customerName = '';
  String _customerPhone = '';
  String _customerAddress = '';
  String _note = '';
  String _paymentMethod = 'wallet'; // 'wallet' or 'cash'
  
  bool _isLoading = false;
  bool _isLoadingWallet = false;
  double _walletBalance = 0.0;
  String? _errorMessage;
  String? _successOrderId;

  CheckoutViewModel({
    CustomerOrderDataSource? orderRepository,
    ProfileDataSource? profileRepository,
  })  : _orderRepository = orderRepository ?? CustomerOrderRepository(),
        _profileRepository = profileRepository ?? ProfileRepository();

  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  String get customerAddress => _customerAddress;
  String get note => _note;
  String get paymentMethod => _paymentMethod;
  
  bool get isLoading => _isLoading;
  bool get isLoadingWallet => _isLoadingWallet;
  double get walletBalance => _walletBalance;
  String? get errorMessage => _errorMessage;
  String? get successOrderId => _successOrderId;

  void initFromProfile(ProfileModel profile) {
    _customerName = profile.name;
    _customerPhone = profile.phone ?? '';
    _customerAddress = '';
    _note = '';
    _paymentMethod = 'wallet';
    _errorMessage = null;
    _successOrderId = null;
    _isLoading = false;
    _walletBalance = 0.0;
    
    // Tải số dư ví
    loadWalletBalance(profile.id);
  }

  Future<void> loadWalletBalance(String userId) async {
    _isLoadingWallet = true;
    notifyListeners();
    try {
      final wallet = await _profileRepository.getWallet(userId);
      _walletBalance = wallet?.balance ?? 0.0;
    } catch (_) {
      _walletBalance = 0.0;
    } finally {
      _isLoadingWallet = false;
      notifyListeners();
    }
  }

  void setCustomerName(String value) {
    _customerName = value;
    notifyListeners();
  }

  void setCustomerPhone(String value) {
    _customerPhone = value;
    notifyListeners();
  }

  void setCustomerAddress(String value) {
    _customerAddress = value;
    notifyListeners();
  }

  void setNote(String value) {
    _note = value;
    notifyListeners();
  }

  void setPaymentMethod(String value) {
    _paymentMethod = value;
    notifyListeners();
  }

  Future<bool> submitOrder({
    required String userId,
    required List<CustomerCartEntry> selectedEntries,
  }) async {
    if (_customerName.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập họ và tên người nhận.';
      notifyListeners();
      return false;
    }
    if (_customerPhone.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập số điện thoại người nhận.';
      notifyListeners();
      return false;
    }
    if (_customerAddress.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập địa chỉ giao hàng.';
      notifyListeners();
      return false;
    }

    final totalAmount = selectedEntries.fold<double>(
      0.0,
      (sum, entry) => sum + entry.subtotal,
    );

    if (_paymentMethod == 'wallet' && _walletBalance < totalAmount) {
      _errorMessage = 'Số dư ví HamsaPay không đủ để thanh toán.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _successOrderId = null;
    notifyListeners();

    try {
      final cartItemIds = selectedEntries.map((e) => e.id).toList();
      final orderCode = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

      final orderId = await _orderRepository.createOrder(
        userId: userId,
        customerName: _customerName,
        customerPhone: _customerPhone,
        customerAddress: _customerAddress,
        note: _note,
        paymentMethod: _paymentMethod,
        cartItemIds: cartItemIds,
        orderCode: orderCode,
      );

      _successOrderId = orderId;
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
