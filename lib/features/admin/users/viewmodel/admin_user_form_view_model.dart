import 'package:flutter/material.dart';
import '../../../../data/models/profiles_model.dart';
import '../repository/admin_user_repository.dart';

class AdminUserFormViewModel extends ChangeNotifier {
  final AdminUserRepository _repository = AdminUserRepository();
  final ProfileModel? userToEdit;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdmin = false;
  bool _isActive = true;

  AdminUserFormViewModel({this.userToEdit}) {
    _isAdmin = userToEdit?.isAdmin ?? false;
    _isActive = userToEdit?.isActive ?? true;
  }

  bool get isEditing => userToEdit != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _isAdmin;
  bool get isActive => _isActive;

  void setIsAdmin(bool value) {
    _isAdmin = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    _isActive = value;
    notifyListeners();
  }

  Future<bool> save({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _errorMessage = _validate(email: email, password: password, name: name);
    if (_errorMessage != null) {
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      if (isEditing) {
        await _repository.updateUser(
          id: userToEdit!.id,
          name: name,
          phone: phone,
          avatarUrl: userToEdit!.avatarUrl,
          role: userToEdit!.role == 'customer'
              ? 'customer'
              : (_isAdmin ? 'admin' : 'employee'),
          isActive: _isActive,
        );
      } else {
        await _repository.createUser(
          email: email.trim(),
          password: password,
          name: name.trim(),
          phone: phone,
          isAdmin: _isAdmin,
        );
      }
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _validate({
    required String email,
    required String password,
    required String name,
  }) {
    if (name.trim().isEmpty) return 'Tên người dùng là bắt buộc.';
    if (!isEditing && (!email.contains('@') || email.trim().isEmpty)) {
      return 'Email không hợp lệ.';
    }
    if (!isEditing && password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự.';
    }
    return null;
  }
}
