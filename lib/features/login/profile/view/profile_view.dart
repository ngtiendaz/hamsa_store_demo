import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'widgets/profile_form.dart';

class ProfileView extends StatelessWidget {
  final bool showLogout;

  const ProfileView({super.key, this.showLogout = false});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthViewModel>().currentProfile;
    if (profile == null) return const SizedBox.shrink();

    return ChangeNotifierProvider(
      key: ValueKey(profile.id),
      create: (_) => ProfileViewModel(profile: profile),
      child: _ProfileContent(showLogout: showLogout),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final bool showLogout;

  const _ProfileContent({required this.showLogout});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final form = ProfileForm(
          viewModel: viewModel,
          onSave: () => _save(context),
          onLogout: showLogout ? () => _logout(context) : null,
        );
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 32 : 20),
          child: isDesktop
              ? form
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: form,
                  ),
                ),
        );
      },
    );
  }

  Future<void> _save(BuildContext context) async {
    final viewModel = context.read<ProfileViewModel>();
    final success = await viewModel.save();
    if (!context.mounted) return;

    if (success) {
      context.read<AuthViewModel>().updateProfile(viewModel.profile);
      AppToast.showSuccess(context, 'Đã cập nhật thông tin cá nhân.');
    } else if (viewModel.errorMessage != null) {
      AppToast.showError(context, viewModel.errorMessage!);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthViewModel>().logout();
    if (context.mounted) context.go('/login');
  }
}
