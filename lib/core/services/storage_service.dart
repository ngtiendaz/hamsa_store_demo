import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static const String avatarBucket = 'avatars';

  final SupabaseClient _client;

  StorageService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  Future<String> uploadAvatar({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final extension = _fileExtension(fileName);
    final path = '$userId/avatar.$extension';
    final version = DateTime.now().microsecondsSinceEpoch;
    await _client.storage
        .from(avatarBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            cacheControl: '0',
            contentType: _contentType(extension),
          ),
        );
    final publicUrl = _client.storage.from(avatarBucket).getPublicUrl(path);
    return '$publicUrl?v=$version';
  }

  String _fileExtension(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    return allowedExtensions.contains(extension) ? extension : 'jpg';
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
