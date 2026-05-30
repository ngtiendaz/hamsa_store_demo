import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/register_view_model.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return ChangeNotifierProvider<RegisterViewModel>(
      create: (_) => RegisterViewModel(authViewModel: authViewModel),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWeb = constraints.maxWidth > 800;
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: isWeb
                      ? _buildWebLayout(context)
                      : _buildMobileLayout(context),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(40),
              height: 580,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THAM GIA\nHAMSA',
                    style: AppTextStyles.displayLg.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Đăng ký tài khoản để khám phá trải nghiệm mua sắm tuyệt vời cùng chúng tôi.',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: AppColors.detail,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: _buildRegisterForm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'ĐĂNG KÝ',
            style: AppTextStyles.headlineLg,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo tài khoản khách hàng mới',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.detail),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildRegisterForm(context),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return Consumer<RegisterViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Họ và tên',
              hintText: 'Nhập họ và tên...',
              onChanged: viewModel.setName,
              showBorder: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Email',
              hintText: 'Nhập địa chỉ email...',
              keyboardType: TextInputType.emailAddress,
              onChanged: viewModel.setEmail,
              showBorder: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Mật khẩu',
              hintText: 'Nhập mật khẩu (tối thiểu 6 ký tự)...',
              obscureText: true,
              onChanged: viewModel.setPassword,
              showBorder: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Xác nhận mật khẩu',
              hintText: 'Nhập lại mật khẩu...',
              obscureText: true,
              onChanged: viewModel.setConfirmPassword,
              showBorder: true,
            ),
            const SizedBox(height: 12),
            if (viewModel.errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Đăng ký',
              isLoading: viewModel.isLoading,
              onPressed: () async {
                final success = await viewModel.register();
                if (!context.mounted) return;
                if (success) {
                  context.go('/shop');
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Đã có tài khoản? ',
                  style: TextStyle(color: AppColors.detail),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Đăng nhập ngay',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
