import 'package:flutter/material.dart';
import 'auth_viewmodel.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthViewModel authViewModel;

  String _email = '';
  String _password = '';
  bool _isLoading = false;
  String? _errorMessage;

  String get email => _email;
  String get password => _password;
  bool get isLoading => _isLoading || authViewModel.isLoading;
  String? get errorMessage => _errorMessage ?? authViewModel.errorMessage;

  LoginViewModel({required this.authViewModel});

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
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
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> login() async {
    if (!validate()) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await authViewModel.login(_email.trim(), _password);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
