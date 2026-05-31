import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/change_password_view_model.dart';

class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthViewModel>().currentProfile;
    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('Vui lòng đăng nhập.')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => ChangePasswordViewModel(email: profile.email),
      child: const _ChangePasswordContent(),
    );
  }
}

class _ChangePasswordContent extends StatelessWidget {
  const _ChangePasswordContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChangePasswordViewModel>();
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 32 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Container(
              padding: EdgeInsets.all(isDesktop ? 28 : 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Đổi mật khẩu',
                    style: AppTextStyles.headlineMd,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vui lòng nhập mật khẩu hiện tại và mật khẩu mới để thực hiện thay đổi.',
                    style: TextStyle(color: AppColors.detail, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'Mật khẩu hiện tại',
                    hintText: 'Nhập mật khẩu hiện tại',
                    obscureText: true,
                    showBorder: true,
                    onChanged: viewModel.setCurrentPassword,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Mật khẩu mới',
                    hintText: 'Nhập mật khẩu mới (tối thiểu 6 ký tự)',
                    obscureText: true,
                    showBorder: true,
                    onChanged: viewModel.setNewPassword,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Xác nhận mật khẩu mới',
                    hintText: 'Nhập lại mật khẩu mới',
                    obscureText: true,
                    showBorder: true,
                    onChanged: viewModel.setConfirmNewPassword,
                  ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: isDesktop ? 150 : null,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => context.pop(),
                          child: const Text('Hủy bỏ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: isDesktop ? 0 : 1,
                        child: SizedBox(
                          width: isDesktop ? 180 : null,
                          child: AppButton(
                            text: 'Cập nhật',
                            isLoading: viewModel.isLoading,
                            onPressed: () => _submit(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final viewModel = context.read<ChangePasswordViewModel>();
    final success = await viewModel.changePassword();
    if (!context.mounted) return;

    if (success) {
      AppToast.showSuccess(context, 'Đổi mật khẩu thành công.');
      context.pop();
    } else if (viewModel.errorMessage != null) {
      AppToast.showError(context, viewModel.errorMessage!);
    }
  }
}
