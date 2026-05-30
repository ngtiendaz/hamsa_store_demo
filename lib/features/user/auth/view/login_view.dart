import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/login_view_model.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/profiles_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  List<ProfileModel> _recentAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadRecentAccounts();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentAccounts() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final accounts = await authViewModel.getRecentAccounts();
    if (mounted) {
      setState(() {
        _recentAccounts = accounts;
      });
    }
  }

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
      constraints: const BoxConstraints(maxWidth: 950),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: AppColors.primary,
              padding: const EdgeInsets.all(40),
              height: 600,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HAMSA\nSTORE',
                    style: AppTextStyles.displayLg.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hệ thống quản lý bán hàng tối giản và hiệu quả.',
                    style: AppTextStyles.bodyLg.copyWith(
                      color: AppColors.detail,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
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
          const SizedBox(height: 20),
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
          const SizedBox(height: 30),
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
            if (_recentAccounts.isNotEmpty) ...[
              Text('TÀI KHOẢN ĐĂNG NHẬP GẦN ĐÂY', style: AppTextStyles.labelMd),
              const SizedBox(height: 12),
              ..._recentAccounts.map((account) => _buildRecentAccountItem(context, account, viewModel)),
              const SizedBox(height: 20),
            ],
            AppTextField(
              label: 'Email',
              hintText: 'Nhập địa chỉ email...',
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              onChanged: viewModel.setEmail,
              showBorder: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Mật khẩu',
              hintText: 'Nhập mật khẩu...',
              obscureText: true,
              controller: _passwordController,
              onChanged: viewModel.setPassword,
              showBorder: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: viewModel.rememberMe,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      if (val != null) {
                        viewModel.setRememberMe(val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ghi nhớ đăng nhập',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
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
                if (!context.mounted) return;
                if (success) {
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Chưa có tài khoản? ',
                  style: TextStyle(color: AppColors.detail),
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Đăng ký ngay',
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

  Widget _buildRecentAccountItem(BuildContext context, ProfileModel account, LoginViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () {
          _emailController.text = account.email;
          viewModel.setEmail(account.email);
          _passwordController.clear();
          viewModel.setPassword('');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                radius: 20,
                backgroundImage: account.avatarUrl != null && account.avatarUrl!.isNotEmpty
                    ? NetworkImage(account.avatarUrl!)
                    : null,
                child: account.avatarUrl == null || account.avatarUrl!.isEmpty
                    ? Text(account.name.isNotEmpty ? account.name[0].toUpperCase() : 'U')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      account.email,
                      style: AppTextStyles.labelMd.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.detail),
                onPressed: () async {
                  final authVM = Provider.of<AuthViewModel>(context, listen: false);
                  await authVM.removeRecentAccount(account.email);
                  _loadRecentAccounts();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
