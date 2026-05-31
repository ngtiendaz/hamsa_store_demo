import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/profiles_model.dart';
import '../../../../data/models/wallet_model.dart';
import '../../../../data/models/wallet_transaction_model.dart';

abstract class ProfileDataSource {
  Future<ProfileModel> updateProfile({
    required String userId,
    required String name,
    String? phone,
    String? avatarUrl,
  });

  Future<String> uploadAvatar({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  });

  Future<WalletModel?> getWallet(String userId);

  Future<List<WalletTransactionModel>> getWalletTransactions(String userId);

  Future<void> processWalletTransaction({
    required String userId,
    required String type,
    required double amount,
    String? note,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  });

  Future<void> verifyCurrentPassword(String password);
}

class ProfileRepository implements ProfileDataSource {
  final SupabaseClient _client;
  final StorageService _storageService;

  ProfileRepository({SupabaseClient? client, StorageService? storageService})
    : _client = client ?? Supabase.instance.client,
      _storageService = storageService ?? StorageService(client: client);

  @override
  Future<ProfileModel> updateProfile({
    required String userId,
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    final response = await _client
        .from('profiles')
        .update({
          'name': name.trim(),
          'phone': phone?.trim().isEmpty ?? true ? null : phone!.trim(),
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();
    return ProfileModel.fromJson(response);
  }

  @override
  Future<String> uploadAvatar({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) {
    return _storageService.uploadAvatar(
      userId: userId,
      fileName: fileName,
      bytes: bytes,
    );
  }

  @override
  Future<WalletModel?> getWallet(String userId) async {
    final response = await _client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return WalletModel.fromJson(response);
  }

  @override
  Future<List<WalletTransactionModel>> getWalletTransactions(
    String userId,
  ) async {
    final response = await _client
        .from('wallet_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((json) => WalletTransactionModel.fromJson(json)).toList();
  }

  @override
  Future<void> processWalletTransaction({
    required String userId,
    required String type,
    required double amount,
    String? note,
  }) async {
    await _client.rpc(
      'process_wallet_transaction',
      params: {
        'p_user_id': userId,
        'p_type': type,
        'p_amount': amount,
        'p_note': note,
      },
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } catch (_) {
      throw Exception('Mật khẩu hiện tại không chính xác.');
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw Exception('Đổi mật khẩu thất bại: ${e.toString()}');
    }
  }

  @override
  Future<void> verifyCurrentPassword(String password) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) {
      throw Exception('Không xác định được tài khoản hiện tại.');
    }

    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (_) {
      throw Exception('Mật khẩu không chính xác.');
    }
  }
}
