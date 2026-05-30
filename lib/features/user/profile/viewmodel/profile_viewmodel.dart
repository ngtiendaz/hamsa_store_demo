import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/profiles_model.dart';
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

  ProfileViewModel({
    required ProfileModel profile,
    ProfileDataSource? repository,
    ImagePicker? imagePicker,
  }) : _profile = profile,
       _name = profile.name,
       _phone = profile.phone ?? '',
       _repository = repository ?? ProfileRepository(),
       _imagePicker = imagePicker ?? ImagePicker();

  ProfileModel get profile => _profile;
  String get name => _name;
  String get phone => _phone;
  Uint8List? get pendingAvatarBytes => _pendingAvatarBytes;
  bool get isSaving => _isSaving;
  bool get isPickingAvatar => _isPickingAvatar;
  String? get errorMessage => _errorMessage;

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
}
