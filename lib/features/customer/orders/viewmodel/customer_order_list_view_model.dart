import 'package:flutter/material.dart';
import '../../../../data/models/order_model.dart';
import '../repository/customer_order_repository.dart';

class CustomerOrderListViewModel extends ChangeNotifier {
  final CustomerOrderDataSource _orderRepository;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  CustomerOrderListViewModel({CustomerOrderDataSource? orderRepository})
      : _orderRepository = orderRepository ?? CustomerOrderRepository();

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderRepository.getActiveOrders(userId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestCancel(String orderId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.requestCancelOrder(orderId, userId);
      await loadOrders(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelRequestCancel(String orderId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.cancelRequestCancelOrder(orderId, userId);
      await loadOrders(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> requestReturn(String orderId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.requestReturnOrder(orderId, userId);
      await loadOrders(userId);
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
