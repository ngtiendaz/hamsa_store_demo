import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/models/profiles_model.dart';
import '../../../../data/models/wallet_model.dart';
import '../../../../data/models/wallet_transaction_model.dart';
import '../repository/profile_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileDataSource _repository;
  final ImagePicker _imagePicker;

  ProfileModel _profile;
  String _name;
  String _phone;
  Uint8List? _pendingAvatarBytes;
  String? _pendingAvatarFileName;
  bool _isSaving = false;
  bool _isPickingAvatar = false;
  String? _errorMessage;

  // Wallet states
  WalletModel? _wallet;
  List<WalletTransactionModel> _transactions = [];
  bool _isLoadingWallet = false;
  bool _isProcessingWallet = false;

  ProfileViewModel({
    required ProfileModel profile,
    ProfileDataSource? repository,
    ImagePicker? imagePicker,
  }) : _profile = profile,
       _name = profile.name,
       _phone = profile.phone ?? '',
       _repository = repository ?? ProfileRepository(),
       _imagePicker = imagePicker ?? ImagePicker() {
    loadWalletInfo();
  }

  ProfileModel get profile => _profile;
  String get name => _name;
  String get phone => _phone;
  Uint8List? get pendingAvatarBytes => _pendingAvatarBytes;
  bool get isSaving => _isSaving;
  bool get isPickingAvatar => _isPickingAvatar;
  String? get errorMessage => _errorMessage;

  WalletModel? get wallet => _wallet;
  List<WalletTransactionModel> get transactions => _transactions;
  bool get isLoadingWallet => _isLoadingWallet;
  bool get isProcessingWallet => _isProcessingWallet;

  void setName(String value) {
    _name = value;
  }

  void setPhone(String value) {
    _phone = value;
  }

  Future<void> pickAvatar() async {
    if (_isPickingAvatar || _isSaving) return;
    _isPickingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (file == null) return;
      _pendingAvatarBytes = await file.readAsBytes();
      _pendingAvatarFileName = file.name;
    } catch (_) {
      _errorMessage = 'Không thể chọn ảnh đại diện từ thiết bị.';
    } finally {
      _isPickingAvatar = false;
      notifyListeners();
    }
  }

  Future<bool> save() async {
    if (_isSaving) return false;
    if (_name.trim().isEmpty) {
      _errorMessage = 'Họ tên không được để trống.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var avatarUrl = _profile.avatarUrl;
      if (_pendingAvatarBytes != null && _pendingAvatarFileName != null) {
        avatarUrl = await _repository.uploadAvatar(
          userId: _profile.id,
          fileName: _pendingAvatarFileName!,
          bytes: _pendingAvatarBytes!,
        );
      }

      _profile = await _repository.updateProfile(
        userId: _profile.id,
        name: _name,
        phone: _phone,
        avatarUrl: avatarUrl,
      );
      _pendingAvatarBytes = null;
      _pendingAvatarFileName = null;
      return true;
    } catch (_) {
      _errorMessage =
          'Không thể cập nhật thông tin. Kiểm tra bucket avatars và quyền truy cập Supabase.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> loadWalletInfo() async {
    if (!_profile.isCustomer) return;
    _isLoadingWallet = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final w = await _repository.getWallet(_profile.id);
      _wallet = w ?? WalletModel(
        id: '',
        userId: _profile.id,
        balance: 0.0,
        currency: 'VND',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _transactions = await _repository.getWalletTransactions(_profile.id);
    } catch (e) {
      _errorMessage = 'Không thể tải thông tin ví. Vui lòng thử lại.';
      debugPrint('Error loading wallet: $e');
    } finally {
      _isLoadingWallet = false;
      notifyListeners();
    }
  }

  Future<bool> deposit(double amount, String password) async {
    if (amount <= 0) {
      _errorMessage = 'Số tiền nạp phải lớn hơn 0.';
      notifyListeners();
      return false;
    }
    if (amount > 10000000) {
      _errorMessage = 'Số tiền nạp tối đa mỗi lần là 10.000.000₫.';
      notifyListeners();
      return false;
    }

    _isProcessingWallet = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isPasswordValid = await _verifyPassword(password);
      if (!isPasswordValid) {
        _errorMessage = 'Mật khẩu xác nhận không chính xác.';
        notifyListeners();
        return false;
      }

      await _repository.processWalletTransaction(
        userId: _profile.id,
        type: 'deposit',
        amount: amount,
        note: 'Nạp tiền vào ví HamsaPay',
      );
      await loadWalletInfo();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isProcessingWallet = false;
      notifyListeners();
    }
  }

  Future<bool> withdraw(double amount, String password) async {
    if (amount <= 0) {
      _errorMessage = 'Số tiền rút phải lớn hơn 0.';
      notifyListeners();
      return false;
    }
    if (amount > 10000000) {
      _errorMessage = 'Số tiền rút tối đa mỗi lần là 10.000.000₫.';
      notifyListeners();
      return false;
    }
    if (_wallet == null || _wallet!.balance < amount) {
      _errorMessage = 'Số dư ví không đủ để thực hiện giao dịch.';
      notifyListeners();
      return false;
    }

    _isProcessingWallet = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isPasswordValid = await _verifyPassword(password);
      if (!isPasswordValid) {
        _errorMessage = 'Mật khẩu xác nhận không chính xác.';
        notifyListeners();
        return false;
      }

      await _repository.processWalletTransaction(
        userId: _profile.id,
        type: 'manual_adjustment',
        amount: amount,
        note: 'Rút tiền khỏi ví HamsaPay',
      );
      await loadWalletInfo();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isProcessingWallet = false;
      notifyListeners();
    }
  }

  Future<bool> _verifyPassword(String password) async {
    try {
      final client = Supabase.instance.client;
      await client.auth.signInWithPassword(email: _profile.email, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }
}
