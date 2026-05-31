import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_network_image.dart';

class AvatarPicker extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final Uint8List? pendingBytes;
  final bool isLoading;
  final VoidCallback onPickAvatar;

  const AvatarPicker({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.pendingBytes,
    required this.isLoading,
    required this.onPickAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 112,
              height: 112,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: ClipOval(child: _buildAvatar()),
            ),
            Positioned(
              right: -4,
              bottom: 4,
              child: IconButton.filled(
                onPressed: isLoading ? null : onPickAvatar,
                tooltip: 'Thay đổi ảnh đại diện',
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.photo_camera_outlined, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Chạm biểu tượng máy ảnh để đổi ảnh đại diện',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.detail, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildAvatar() {
    if (pendingBytes != null) {
      return Image.memory(pendingBytes!, fit: BoxFit.cover);
    }
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty) {
      return AppNetworkImage(
        imageUrl: avatarUrl!,
        key: ValueKey(avatarUrl),
        fit: BoxFit.cover,
        placeholder: _AvatarFallback(name: name),
        errorWidget: _AvatarFallback(name: name),
      );
    }
    return _AvatarFallback(name: name);
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;

  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();
    return Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        trimmedName.isEmpty ? 'U' : trimmedName.characters.first.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
