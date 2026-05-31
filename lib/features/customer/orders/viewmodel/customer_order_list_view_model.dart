import 'package:flutter/material.dart';
import '../../../../data/dto/pagination_result.dart';
import '../../../../data/models/order_model.dart';
import '../repository/customer_order_repository.dart';

class CustomerOrderListViewModel extends ChangeNotifier {
  final CustomerOrderDataSource _orderRepository;

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  DateTime? _startDate;
  DateTime? _endDate;
  String _keyword = '';
  String _status = 'all';
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalCount = 0;
  int _requestVersion = 0;

  CustomerOrderListViewModel({CustomerOrderDataSource? orderRepository})
    : _orderRepository = orderRepository ?? CustomerOrderRepository();

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String get keyword => _keyword;
  String get status => _status;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get totalPages => _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();
  bool get hasNextPage => _currentPage * _pageSize < _totalCount;
  bool get hasPreviousPage => _currentPage > 1;

  void setDateRange(DateTime start, DateTime end, String userId) {
    _startDate = start;
    _endDate = end;
    loadOrders(userId, refresh: true);
  }

  void clearDateRange(String userId) {
    _startDate = null;
    _endDate = null;
    loadOrders(userId, refresh: true);
  }

  void setKeyword(String value, String userId) {
    _keyword = value;
    loadOrders(userId, refresh: true);
  }

  void selectStatus(String value, String userId) {
    _status = value;
    loadOrders(userId, refresh: true);
  }

  void nextPage(String userId) {
    if (hasNextPage && !_isLoading) {
      _currentPage++;
      loadOrders(userId);
    }
  }

  void previousPage(String userId) {
    if (hasPreviousPage && !_isLoading) {
      _currentPage--;
      loadOrders(userId);
    }
  }

  Future<void> loadOrders(String userId, {bool refresh = false}) async {
    if (refresh) _currentPage = 1;
    final requestVersion = ++_requestVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final PaginationResult<OrderModel> result = await _orderRepository
          .getActiveOrders(
            userId,
            keyword: _keyword,
            status: _status,
            startDate: _startDate,
            endDate: _endDate,
            page: _currentPage,
            pageSize: _pageSize,
          );
      if (requestVersion != _requestVersion) return;
      _orders = result.items;
      _totalCount = result.totalCount;
    } catch (e) {
      if (requestVersion == _requestVersion) {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      }
    } finally {
      if (requestVersion == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
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

  Future<bool> cancelRequestReturn(String orderId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.cancelRequestReturnOrder(orderId, userId);
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

  Future<bool> updateOrderInfo({
    required String orderId,
    required String userId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.updateOrderInfo(
        orderId: orderId,
        userId: userId,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        note: note,
      );
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
