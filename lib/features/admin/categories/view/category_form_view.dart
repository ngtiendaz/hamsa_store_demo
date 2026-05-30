import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/category_form_view_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';

class CategoryFormView extends StatefulWidget {
  final CategoryModel? categoryToEdit;

  const CategoryFormView({super.key, this.categoryToEdit});

  @override
  State<CategoryFormView> createState() => _CategoryFormViewState();
}

class _CategoryFormViewState extends State<CategoryFormView> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.categoryToEdit?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.categoryToEdit?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CategoryFormViewModel>(
      create: (_) => CategoryFormViewModel()..init(widget.categoryToEdit),
      child: Consumer<CategoryFormViewModel>(
        builder: (context, viewModel, child) {
          final isMobile = MediaQuery.sizeOf(context).width <= 600;
          return PopScope(
            canPop: !viewModel.isChanged,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final action = await _showDiscardChangesDialog(
                context,
                viewModel,
              );
              if (action == null) return;
              if (action == false) {
                if (context.mounted) {
                  Navigator.of(context).pop(false);
                }
              } else if (action == true) {
                viewModel.setName(_nameController.text);
                viewModel.setDescription(_descriptionController.text);

                final success = await viewModel.save();
                if (success && context.mounted) {
                  AppToast.showSuccess(
                    context,
                    viewModel.isEditing
                        ? 'Cập nhật danh mục thành công!'
                        : 'Thêm danh mục mới thành công!',
                  );
                  Navigator.of(context).pop(true);
                }
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              appBar: null, // Đưa tiêu đề lên layout chính
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
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
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (isMobile)
                        Text(
                          viewModel.isEditing
                              ? 'CHI TIẾT DANH MỤC'
                              : 'THÊM MỚI DANH MỤC',
                          style: AppTextStyles.headlineMd.copyWith(
                            fontSize: 18,
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              viewModel.isEditing
                                  ? 'CHI TIẾT DANH MỤC'
                                  : 'THÊM MỚI DANH MỤC',
                              style: AppTextStyles.headlineMd.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            _buildCategoryActions(context, viewModel),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Form Body
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextField(
                              label: 'Tên danh mục *',
                              hintText: 'Nhập tên danh mục...',
                              controller: _nameController,
                              onChanged: viewModel.setName,
                              showBorder: true,
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              label: 'Mô tả',
                              hintText: 'Nhập mô tả danh mục...',
                              controller: _descriptionController,
                              onChanged: viewModel.setDescription,
                              minLines: 3,
                              maxLines: 5,
                              showBorder: true,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Trạng thái hoạt động',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Bật để cho phép danh mục được sử dụng trong hệ thống.',
                                        style: TextStyle(
                                          color: AppColors.detail,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Switch(
                                  value: viewModel.isActive,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: viewModel.setIsActive,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isMobile) ...[
                        const SizedBox(height: 24),
                        _buildCategoryActions(
                          context,
                          viewModel,
                          isMobile: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryActions(
    BuildContext context,
    CategoryFormViewModel viewModel, {
    bool isMobile = false,
  }) {
    final deleteButton = ElevatedButton(
      onPressed: viewModel.isLoading
          ? null
          : () => _confirmDelete(context, viewModel),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFEE2E2),
        foregroundColor: AppColors.error,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: viewModel.isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
              ),
            )
          : const Text(
              'Xóa danh mục',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
    );
    final saveButton = AppButton(
      text: viewModel.isEditing ? 'Cập nhật' : 'Thêm mới',
      isLoading: viewModel.isLoading,
      onPressed: (!viewModel.isChanged || viewModel.isLoading)
          ? null
          : () => _saveCategory(context, viewModel),
    );

    if (isMobile) {
      return Row(
        children: [
          if (viewModel.isEditing) ...[
            Expanded(child: deleteButton),
            const SizedBox(width: 12),
          ],
          Expanded(child: saveButton),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (viewModel.isEditing) ...[
          SizedBox(width: 200, child: deleteButton),
          const SizedBox(width: 12),
        ],
        SizedBox(width: 200, child: saveButton),
      ],
    );
  }

  Future<void> _saveCategory(
    BuildContext context,
    CategoryFormViewModel viewModel,
  ) async {
    viewModel.setName(_nameController.text);
    viewModel.setDescription(_descriptionController.text);

    final success = await viewModel.save();
    if (success && context.mounted) {
      AppToast.showSuccess(
        context,
        viewModel.isEditing
            ? 'Cập nhật danh mục thành công!'
            : 'Thêm danh mục mới thành công!',
      );
      context.pop(true);
    }
  }

  Future<bool?> _showDiscardChangesDialog(
    BuildContext context,
    CategoryFormViewModel viewModel,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi chưa được lưu'),
        content: const Text(
          'Bạn có muốn lưu các thay đổi trước khi thoát không?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(null), // Hủy thao tác thoát
            child: const Text('Hủy', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false), // Thoát không lưu
            child: const Text(
              'Thoát',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Lưu rồi thoát
            child: const Text(
              'Lưu',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CategoryFormViewModel viewModel,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa danh mục này? Tất cả sản phẩm thuộc danh mục này sẽ được tự động chuyển sang danh mục "Khác".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success = await viewModel.deleteCategory();
      if (success && context.mounted) {
        AppToast.showSuccess(context, 'Xóa danh mục thành công!');
        context.pop(true);
      } else if (context.mounted) {
        AppToast.showError(
          context,
          viewModel.errorMessage ?? 'Không thể xóa danh mục.',
        );
      }
    }
  }
}
