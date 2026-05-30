import 'package:flutter/material.dart';
import '../repository/auth_repository.dart';
import '../../../../data/models/profiles_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();

  ProfileModel? _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentProfile != null;

  AuthViewModel() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentProfile = await _repository.getCurrentProfile();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.login(email, password);
      if (user == null) {
        _errorMessage = 'Đăng nhập thất bại. Vui lòng kiểm tra lại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final profile = await _repository.getProfile(user.id);
      if (profile == null) {
        _errorMessage = 'Tài khoản chưa được cấu hình thông tin cá nhân.';
        await _repository.logout();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!profile.isActive) {
        _errorMessage = 'Tài khoản đã bị vô hiệu hóa.';
        await _repository.logout();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentProfile = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Sai tài khoản hoặc mật khẩu.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.logout();
      _currentProfile = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateProfile(ProfileModel updatedProfile) {
    _currentProfile = updatedProfile;
    notifyListeners();
  }
}
