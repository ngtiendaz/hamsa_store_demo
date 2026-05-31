import 'package:flutter/material.dart';
import '../repository/profile_repository.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  final ProfileDataSource _repository;
  final String _email;

  String _currentPassword = '';
  String _newPassword = '';
  String _confirmNewPassword = '';
  bool _isLoading = false;
  String? _errorMessage;

  ChangePasswordViewModel({
    required String email,
    ProfileDataSource? repository,
  }) : _email = email,
       _repository = repository ?? ProfileRepository();

  String get currentPassword => _currentPassword;
  String get newPassword => _newPassword;
  String get confirmNewPassword => _confirmNewPassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setCurrentPassword(String value) {
    _currentPassword = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setNewPassword(String value) {
    _newPassword = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setConfirmNewPassword(String value) {
    _confirmNewPassword = value;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> changePassword() async {
    if (_currentPassword.isEmpty || _newPassword.isEmpty || _confirmNewPassword.isEmpty) {
      _errorMessage = 'Vui lòng điền đầy đủ tất cả các trường.';
      notifyListeners();
      return false;
    }

    if (_newPassword.length < 6) {
      _errorMessage = 'Mật khẩu mới phải có tối thiểu 6 ký tự.';
      notifyListeners();
      return false;
    }

    if (_newPassword != _confirmNewPassword) {
      _errorMessage = 'Xác nhận mật khẩu mới không khớp.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.changePassword(
        currentPassword: _currentPassword,
        newPassword: _newPassword,
        email: _email,
      );
      _currentPassword = '';
      _newPassword = '';
      _confirmNewPassword = '';
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
