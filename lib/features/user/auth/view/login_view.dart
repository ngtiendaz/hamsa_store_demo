import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/login_view_model.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return ChangeNotifierProvider<LoginViewModel>(
      create: (_) => LoginViewModel(authViewModel: authViewModel),
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
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(40),
              height: 500,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HAMSA\nSTORE',
                    style: AppTextStyles.displayLg.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hệ thống quản lý bán hàng tối giản và hiệu quả.',
                    style: AppTextStyles.bodyLg.copyWith(color: AppColors.detail),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: _buildLoginForm(context),
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
          const SizedBox(height: 40),
          const Text(
            'HAMSA STORE',
            style: AppTextStyles.headlineLg,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Đăng nhập hệ thống bán hàng',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.detail),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildLoginForm(context),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Email',
              hintText: 'Nhập địa chỉ email...',
              keyboardType: TextInputType.emailAddress,
              onChanged: viewModel.setEmail,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Mật khẩu',
              hintText: 'Nhập mật khẩu...',
              obscureText: true,
              onChanged: viewModel.setPassword,
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
              text: 'Đăng nhập',
              isLoading: viewModel.isLoading,
              onPressed: () async {
                final success = await viewModel.login();
                if (success && mounted) {
                  final profile = viewModel.authViewModel.currentProfile;
                  if (profile != null) {
                    if (profile.isAdmin || profile.isEmployee) {
                      context.go('/admin/dashboard');
                    } else {
                      context.go('/shop');
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
