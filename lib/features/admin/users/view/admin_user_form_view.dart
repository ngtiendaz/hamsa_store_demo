import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../data/models/profiles_model.dart';
import '../../../user/auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/admin_user_form_view_model.dart';

class AdminUserFormView extends StatefulWidget {
  final ProfileModel? userToEdit;

  const AdminUserFormView({super.key, this.userToEdit});

  @override
  State<AdminUserFormView> createState() => _AdminUserFormViewState();
}

class _AdminUserFormViewState extends State<AdminUserFormView> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = widget.userToEdit;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminUserFormViewModel(userToEdit: widget.userToEdit),
      child: Consumer<AdminUserFormViewModel>(
        builder: (context, viewModel, child) {
          final isMobile = MediaQuery.sizeOf(context).width <= 600;
          final isCurrentUser =
              context.read<AuthViewModel>().currentProfile?.id ==
              widget.userToEdit?.id;
          final isCustomer = widget.userToEdit?.role == 'customer';
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (viewModel.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        viewModel.errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (isMobile)
                    Text(
                      viewModel.isEditing
                          ? (isCustomer ? 'THÔNG TIN KHÁCH HÀNG' : 'THÔNG TIN NGƯỜI DÙNG')
                          : 'THÊM NGƯỜI DÙNG',
                      style: AppTextStyles.headlineMd.copyWith(fontSize: 18),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          viewModel.isEditing
                              ? (isCustomer ? 'THÔNG TIN KHÁCH HÀNG' : 'THÔNG TIN NGƯỜI DÙNG')
                              : 'THÊM NGƯỜI DÙNG',
                          style: AppTextStyles.headlineMd.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        _SaveButton(
                          viewModel: viewModel,
                          onSave: () => _save(context, viewModel),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  isCustomer
                      ? _ReadOnlyField(
                          label: 'HỌ VÀ TÊN',
                          controller: _nameController,
                          hintText: 'Nhập họ tên...',
                          readOnly: true,
                        )
                      : AppTextField(
                          label: 'Tên người dùng (Bắt buộc)',
                          hintText: 'Nhập họ tên...',
                          controller: _nameController,
                          showBorder: true,
                        ),
                  const SizedBox(height: 20),
                  _ReadOnlyField(
                    label: 'EMAIL',
                    controller: _emailController,
                    hintText: 'name@example.com',
                    readOnly: viewModel.isEditing,
                  ),
                  if (!viewModel.isEditing) ...[
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Mật khẩu ban đầu (Bắt buộc)',
                      hintText: 'Tối thiểu 6 ký tự...',
                      controller: _passwordController,
                      obscureText: true,
                      showBorder: true,
                    ),
                  ],
                  const SizedBox(height: 20),
                  isCustomer
                      ? _ReadOnlyField(
                          label: 'SỐ ĐIỆN THOẠI',
                          controller: _phoneController,
                          hintText: 'Chưa cập nhật số điện thoại',
                          readOnly: true,
                        )
                      : AppTextField(
                          label: 'Số điện thoại',
                          hintText: 'Nhập số điện thoại...',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          showBorder: true,
                        ),
                  if (!isCustomer) ...[
                    const SizedBox(height: 20),
                    _OptionTile(
                      title: 'Quyền quản trị viên',
                      subtitle: viewModel.isAdmin
                          ? 'Tài khoản sẽ có quyền admin.'
                          : 'Mặc định tài khoản là employee.',
                      value: viewModel.isAdmin,
                      enabled: !isCurrentUser,
                      onChanged: viewModel.setIsAdmin,
                    ),
                  ],
                  if (viewModel.isEditing) ...[
                    const SizedBox(height: 12),
                    _StatusDropdown(
                      value: viewModel.isActive,
                      enabled: !isCurrentUser,
                      onChanged: viewModel.setIsActive,
                    ),
                  ],
                  if (isMobile) ...[
                    const SizedBox(height: 24),
                    _SaveButton(
                      viewModel: viewModel,
                      onSave: () => _save(context, viewModel),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    AdminUserFormViewModel viewModel,
  ) async {
    final success = await viewModel.save(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
      phone: _phoneController.text,
    );
    if (!context.mounted || !success) return;
    AppToast.showSuccess(
      context,
      viewModel.isEditing
          ? 'Cập nhật người dùng thành công.'
          : 'Thêm người dùng thành công.',
    );
    context.pop(true);
  }
}

class _SaveButton extends StatelessWidget {
  final AdminUserFormViewModel viewModel;
  final VoidCallback onSave;

  const _SaveButton({required this.viewModel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: viewModel.isEditing ? 'Cập nhật' : 'Thêm người dùng',
      isLoading: viewModel.isLoading,
      onPressed: onSave,
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool readOnly;

  const _ReadOnlyField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.readOnly,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMd),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: hintText,
            filled: readOnly,
            fillColor: readOnly ? AppColors.surface : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.value,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        value: value,
        onChanged: enabled ? (checked) => onChanged(checked ?? false) : null,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _StatusDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TRẠNG THÁI TÀI KHOẢN', style: AppTextStyles.labelMd),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<bool>(
              value: value,
              isExpanded: true,
              onChanged: enabled
                  ? (selected) {
                      if (selected != null) onChanged(selected);
                    }
                  : null,
              items: const [
                DropdownMenuItem(value: true, child: Text('Đang hoạt động')),
                DropdownMenuItem(value: false, child: Text('Vô hiệu hóa')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
