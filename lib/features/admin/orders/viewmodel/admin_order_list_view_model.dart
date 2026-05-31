import 'package:flutter/material.dart';
import '../../../../data/models/order_model.dart';
import '../../../../data/dto/pagination_result.dart';
import '../../../../core/utils/debounce.dart';
import '../repository/admin_order_repository.dart';

class AdminOrderListViewModel extends ChangeNotifier {
  final AdminOrderDataSource _orderRepository;
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 500));

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalCount = 0;
  String _keyword = '';
  String _status = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  int _requestVersion = 0;

  AdminOrderListViewModel({AdminOrderDataSource? orderRepository})
    : _orderRepository = orderRepository ?? AdminOrderRepository();

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get totalPages => _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();
  bool get hasNextPage => _currentPage * _pageSize < _totalCount;
  bool get hasPreviousPage => _currentPage > 1;
  String get keyword => _keyword;
  String get status => _status;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  void setKeyword(String value) {
    _keyword = value;
    _debounce.run(() => loadOrders(refresh: true));
  }

  void selectStatus(String value) {
    _status = value;
    loadOrders(refresh: true);
  }

  void initFilters({String? status, String? keyword}) {
    _status = status ?? 'all';
    _keyword = keyword ?? '';
    _startDate = null;
    _endDate = null;
    _currentPage = 1;
    loadOrders();
  }

  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    loadOrders(refresh: true);
  }

  void clearDateRange() {
    _startDate = null;
    _endDate = null;
    loadOrders(refresh: true);
  }

  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      loadOrders();
    }
  }

  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      loadOrders();
    }
  }

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
    }
    final requestVersion = ++_requestVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final PaginationResult<OrderModel> result = await _orderRepository
          .getAllOrders(
            keyword: _keyword.trim(),
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

  Future<bool> confirmOrder(String orderId, String adminId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.confirmOrder(orderId, adminId);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveCancel(String orderId, String adminId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.approveCancelOrder(orderId, adminId);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deliverOrderSuccess(String orderId, String adminId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.deliverOrderSuccess(orderId, adminId);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deliverOrderFailed(String orderId, String adminId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.deliverOrderFailed(orderId, adminId);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveReturn(String orderId, String adminId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.approveReturnOrder(orderId, adminId);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelPending(String orderId, String adminId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.cancelPendingOrder(orderId, adminId);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> rejectCancel(String orderId, String adminId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.rejectCancelOrder(orderId, adminId);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _requestVersion++;
    _debounce.dispose();
    super.dispose();
  }
}
