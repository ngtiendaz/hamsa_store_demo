import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../viewmodel/profile_viewmodel.dart';
import 'avatar_picker.dart';

class ProfileForm extends StatelessWidget {
  final ProfileViewModel viewModel;
  final VoidCallback onSave;
  final VoidCallback? onLogout;

  const ProfileForm({
    super.key,
    required this.viewModel,
    required this.onSave,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(viewModel: viewModel),
            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(isDesktop ? 28 : 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Thông tin cá nhân',
                    style: AppTextStyles.headlineMd,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cập nhật thông tin liên hệ để tài khoản của bạn luôn chính xác.',
                    style: TextStyle(color: AppColors.detail),
                  ),
                  const SizedBox(height: 24),
                  _EditableFields(viewModel: viewModel, isDesktop: isDesktop),
                  const SizedBox(height: 20),
                  _ReadonlyInfo(
                    label: 'Email đăng nhập',
                    value: viewModel.profile.email,
                    icon: Icons.mail_outline,
                  ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _ProfileActions(
                    isDesktop: isDesktop,
                    isSaving: viewModel.isSaving,
                    onSave: onSave,
                    onLogout: onLogout,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EditableFields extends StatelessWidget {
  final ProfileViewModel viewModel;
  final bool isDesktop;

  const _EditableFields({required this.viewModel, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final nameField = AppTextField(
      label: 'Họ và tên',
      initialValue: viewModel.name,
      hintText: 'Nhập họ và tên',
      onChanged: viewModel.setName,
      showBorder: true,
    );
    final phoneField = AppTextField(
      label: 'Số điện thoại',
      initialValue: viewModel.phone,
      hintText: 'Nhập số điện thoại',
      keyboardType: TextInputType.phone,
      onChanged: viewModel.setPhone,
      showBorder: true,
    );
    if (!isDesktop) {
      return Column(
        children: [nameField, const SizedBox(height: 20), phoneField],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: nameField),
        const SizedBox(width: 20),
        Expanded(child: phoneField),
      ],
    );
  }
}

class _ProfileActions extends StatelessWidget {
  final bool isDesktop;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback? onLogout;

  const _ProfileActions({
    required this.isDesktop,
    required this.isSaving,
    required this.onSave,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final saveButton = AppButton(
      text: 'Lưu thay đổi',
      isLoading: isSaving,
      onPressed: onSave,
    );
    if (onLogout == null || !isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          saveButton,
          if (onLogout != null) ...[
            const SizedBox(height: 12),
            AppButton(text: 'Đăng xuất', isGhost: true, onPressed: onLogout),
          ],
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 220,
          child: AppButton(
            text: 'Đăng xuất',
            isGhost: true,
            onPressed: onLogout,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 220, child: saveButton),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileViewModel viewModel;

  const _ProfileHeader({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final avatar = AvatarPicker(
            name: viewModel.name,
            avatarUrl: viewModel.profile.avatarUrl,
            pendingBytes: viewModel.pendingAvatarBytes,
            isLoading: viewModel.isPickingAvatar,
            onPickAvatar: viewModel.pickAvatar,
          );
          final description = Column(
            crossAxisAlignment: constraints.maxWidth < 520
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.name.trim().isEmpty ? 'Người dùng' : viewModel.name,
                textAlign: constraints.maxWidth < 520
                    ? TextAlign.center
                    : TextAlign.start,
                style: AppTextStyles.headlineMd.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              _RoleBadge(role: viewModel.profile.role),
              const SizedBox(height: 8),
              Text(
                viewModel.profile.email,
                textAlign: constraints.maxWidth < 520
                    ? TextAlign.center
                    : TextAlign.start,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          );
          if (constraints.maxWidth < 520) {
            return Column(
              children: [avatar, const SizedBox(height: 16), description],
            );
          }
          return Row(
            children: [
              avatar,
              const SizedBox(width: 28),
              Expanded(child: description),
            ],
          );
        },
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        _roleLabel(role),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReadonlyInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReadonlyInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.detail),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AppTextStyles.labelMd),
                const SizedBox(height: 4),
                Text(value, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, color: AppColors.detail, size: 18),
        ],
      ),
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'admin':
      return 'Quản trị viên';
    case 'employee':
      return 'Nhân viên';
    default:
      return 'Khách hàng';
  }
}
