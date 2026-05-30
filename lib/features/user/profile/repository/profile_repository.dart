import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../data/models/profiles_model.dart';

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
}
