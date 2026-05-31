import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final prefs = await SharedPreferences.getInstance();
      final rememberMe = prefs.getBool('remember_me') ?? false;
      if (!rememberMe) {
        await _repository.logout();
        _currentProfile = null;
      } else {
        _currentProfile = await _repository.getCurrentProfile();
      }
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

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _repository.register(
        email: email,
        password: password,
        name: name,
      );

      if (user == null) {
        _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final profile = await _repository.getProfile(user.id);
      if (profile == null) {
        _errorMessage = 'Đăng ký thành công nhưng không thể tải hồ sơ cá nhân.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentProfile = profile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('already') || errStr.contains('exists')) {
        _errorMessage = 'Email này đã được đăng ký.';
      } else {
        String cleanMessage = e.toString();
        if (e is FunctionException) {
          final details = e.details;
          if (details is Map && details['error'] != null) {
            cleanMessage = details['error'].toString();
          }
        }
        _errorMessage = 'Đăng ký thất bại: $cleanMessage';
      }
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

  // --- Recent Accounts Logic ---
  Future<void> saveRecentAccount(ProfileModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentStringList = prefs.getStringList('recent_accounts') ?? [];

      List<Map<String, dynamic>> accounts = recentStringList
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .toList();

      accounts.removeWhere((acc) => acc['email'] == profile.email);

      accounts.insert(0, {
        'id': profile.id,
        'email': profile.email,
        'name': profile.name,
        'role': profile.role,
        'avatar_url': profile.avatarUrl,
      });

      if (accounts.length > 3) {
        accounts = accounts.sublist(0, 3);
      }

      final updatedList = accounts.map((acc) => jsonEncode(acc)).toList();
      await prefs.setStringList('recent_accounts', updatedList);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving recent account: $e');
    }
  }

  Future<List<ProfileModel>> getRecentAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentStringList = prefs.getStringList('recent_accounts') ?? [];
      return recentStringList.map((s) {
        final data = jsonDecode(s) as Map<String, dynamic>;
        return ProfileModel(
          id: data['id'] ?? '',
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          role: data['role'] ?? 'customer',
          avatarUrl: data['avatar_url'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting recent accounts: $e');
      return [];
    }
  }

  Future<void> removeRecentAccount(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentStringList = prefs.getStringList('recent_accounts') ?? [];
      List<Map<String, dynamic>> accounts = recentStringList
          .map((s) => jsonDecode(s) as Map<String, dynamic>)
          .toList();

      accounts.removeWhere((acc) => acc['email'] == email);

      final updatedList = accounts.map((acc) => jsonEncode(acc)).toList();
      await prefs.setStringList('recent_accounts', updatedList);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing recent account: $e');
    }
  }
}
