import 'package:flutter/material.dart';
import '../../../../core/utils/debounce.dart';
import '../../../../data/models/profiles_model.dart';
import '../repository/admin_user_repository.dart';

class AdminUserListViewModel extends ChangeNotifier {
  final AdminUserRepository _repository = AdminUserRepository();
  final Debounce _debounce = Debounce(delay: const Duration(milliseconds: 500));

  List<ProfileModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _keyword = '';
  String? _selectedRole;
  bool? _selectedIsActive;
  int _currentPage = 1;
  final int _pageSize = 20;
  int _totalCount = 0;
  int _requestVersion = 0;

  List<ProfileModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedRole => _selectedRole;
  bool? get selectedIsActive => _selectedIsActive;
  int get currentPage => _currentPage;
  int get totalPages => _totalCount == 0 ? 1 : (_totalCount / _pageSize).ceil();
  bool get hasNextPage => _currentPage * _pageSize < _totalCount;
  bool get hasPreviousPage => _currentPage > 1;

  AdminUserListViewModel() {
    loadUsers();
  }

  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) _currentPage = 1;
    final requestVersion = ++_requestVersion;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _repository.getUsers(
        keyword: _keyword,
        role: _selectedRole,
        isActive: _selectedIsActive,
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (requestVersion != _requestVersion) return;
      _users = result.items;
      _totalCount = result.totalCount;
    } catch (error) {
      if (requestVersion == _requestVersion) {
        _errorMessage = 'Không thể tải danh sách người dùng.';
        debugPrint('Error loading users: $error');
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
    _debounce.run(() => loadUsers(refresh: true));
  }

  void selectRole(String? value) {
    _selectedRole = value;
    loadUsers(refresh: true);
  }

  void selectIsActive(bool? value) {
    _selectedIsActive = value;
    loadUsers(refresh: true);
  }

  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      loadUsers();
    }
  }

  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      loadUsers();
    }
  }

  Future<bool> deactivateUser(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deactivateUser(id);
      await loadUsers();
      return true;
    } catch (error) {
      _errorMessage = 'Không thể vô hiệu hóa người dùng.';
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
