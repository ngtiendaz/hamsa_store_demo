import 'package:flutter/material.dart';
import 'auth_viewmodel.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthViewModel authViewModel;

  String _email = '';
  String _name = '';
  String _password = '';
  String _confirmPassword = '';
  bool _isLoading = false;
  String? _errorMessage;

  String get email => _email;
  String get name => _name;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage ?? authViewModel.errorMessage;

  RegisterViewModel({required this.authViewModel});

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }

  bool validate() {
    if (_email.trim().isEmpty) {
      _errorMessage = 'Email không được để trống.';
      notifyListeners();
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_email.trim())) {
      _errorMessage = 'Email không đúng định dạng.';
      notifyListeners();
      return false;
    }
    if (_password.isEmpty) {
      _errorMessage = 'Mật khẩu không được để trống.';
      notifyListeners();
      return false;
    }
    if (_password.length < 6) {
      _errorMessage = 'Mật khẩu phải chứa ít nhất 6 ký tự.';
      notifyListeners();
      return false;
    }
    if (_confirmPassword.isEmpty) {
      _errorMessage = 'Vui lòng xác nhận lại mật khẩu.';
      notifyListeners();
      return false;
    }
    if (_password != _confirmPassword) {
      _errorMessage = 'Mật khẩu xác nhận không khớp.';
      notifyListeners();
      return false;
    }
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> register() async {
    if (!validate()) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // If name is empty, default it to email local-part
      final displayName = _name.trim().isNotEmpty
          ? _name.trim()
          : _email.trim().split('@')[0];

      final success = await authViewModel.register(
        _email.trim(),
        _password,
        displayName,
      );
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Đã có lỗi xảy ra trong quá trình đăng ký.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
