import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/product_form_view_model.dart';
import '../../../user/auth/viewmodel/auth_viewmodel.dart';
import '../../../../data/models/products_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import 'widgets/product_image_widget.dart';

class ProductFormView extends StatefulWidget {
  final ProductModel? productToEdit;

  const ProductFormView({super.key, this.productToEdit});

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentProfile?.id ?? '';
    final isAdmin = authViewModel.currentProfile?.isAdmin ?? false;

    return ChangeNotifierProvider<ProductFormViewModel>(
      create: (_) => ProductFormViewModel()..init(widget.productToEdit),
      child: Consumer<ProductFormViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.primary),
              title: Text(
                viewModel.isEditing ? 'Sửa sản phẩm' : 'Thêm sản phẩm mới',
                style: AppTextStyles.headlineMd,
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: AppColors.surface, height: 1),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
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
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Image Selector Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ẢNH SẢN PHẨM', style: AppTextStyles.labelMd),
                            const SizedBox(height: 8),
                            Center(
                              child: Stack(
                                children: [
                                  InkWell(
                                    onTap: viewModel.pickImage,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 150,
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 1.5,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: viewModel.pickedImageBytes != null
                                          ? Image.memory(
                                              viewModel.pickedImageBytes!,
                                              fit: BoxFit.cover,
                                              width: 150,
                                              height: 150,
                                            )
                                          : viewModel.imageUrl != null
                                              ? ProductImageWidget(
                                                  imageUrl: viewModel.imageUrl,
                                                  size: 150,
                                                  borderRadius: 16,
                                                )
                                              : const Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.add_a_photo_outlined,
                                                      size: 32,
                                                      color: AppColors.detail,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'Chọn ảnh từ máy',
                                                      style: TextStyle(
                                                        color: AppColors.detail,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                    ),
                                  ),
                                  if (viewModel.pickedImageBytes != null)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: viewModel.clearPickedImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Internal Name
                        AppTextField(
                          label: 'Tên nội bộ (Bắt buộc)',
                          hintText: 'Nhập tên sử dụng nội bộ...',
                          initialValue: viewModel.internalName,
                          onChanged: viewModel.setInternalName,
                          errorText: viewModel.internalName.trim().isEmpty && viewModel.errorMessage != null
                              ? 'Tên nội bộ là bắt buộc.'
                              : null,
                        ),
                        const SizedBox(height: 20),

                        // Trade Name
                        AppTextField(
                          label: 'Tên thương mại',
                          hintText: 'Nhập tên hiển thị thương mại...',
                          initialValue: viewModel.tradeName,
                          onChanged: viewModel.setTradeName,
                        ),
                        const SizedBox(height: 20),

                        // Barcode
                        AppTextField(
                          label: 'Barcode',
                          hintText: 'Mã vạch sản phẩm...',
                          initialValue: viewModel.barcode,
                          onChanged: viewModel.setBarcode,
                        ),
                        const SizedBox(height: 20),

                        // Row for Price and Stock
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Đơn giá',
                                hintText: '0.00',
                                initialValue: viewModel.isEditing ? viewModel.price.toStringAsFixed(0) : '',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (val) => viewModel.setPrice(double.tryParse(val) ?? 0.0),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTextField(
                                label: 'Số lượng tồn kho',
                                hintText: '0',
                                initialValue: viewModel.isEditing ? viewModel.stock.toString() : '',
                                keyboardType: TextInputType.number,
                                onChanged: (val) => viewModel.setStock(int.tryParse(val) ?? 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Row for Category and Brand Dropdowns
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('DANH MỤC', style: AppTextStyles.labelMd),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: viewModel.categoryId.isEmpty ? null : viewModel.categoryId,
                                        isExpanded: true,
                                        items: viewModel.categories.map(
                                          (cat) => DropdownMenuItem(
                                            value: cat.id,
                                            child: Text(cat.name),
                                          ),
                                        ).toList(),
                                        onChanged: (val) {
                                          if (val != null) viewModel.setCategoryId(val);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('NHÃN HÀNG', style: AppTextStyles.labelMd),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: viewModel.brandId.isEmpty ? null : viewModel.brandId,
                                        isExpanded: true,
                                        items: viewModel.brands.map(
                                          (brand) => DropdownMenuItem(
                                            value: brand.id,
                                            child: Text(brand.name),
                                          ),
                                        ).toList(),
                                        onChanged: (val) {
                                          if (val != null) viewModel.setBrandId(val);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Status Selector
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TRẠNG THÁI KINH DOANH', style: AppTextStyles.labelMd),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: viewModel.status,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'active', child: Text('Đang hoạt động')),
                                    DropdownMenuItem(value: 'inactive', child: Text('Ngừng bán')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) viewModel.setStatus(val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Description
                        AppTextField(
                          label: 'Mô tả chi tiết',
                          hintText: 'Nhập mô tả sản phẩm...',
                          initialValue: viewModel.description,
                          keyboardType: TextInputType.multiline,
                          onChanged: viewModel.setDescription,
                        ),
                        const SizedBox(height: 40),

                        // Actions Row
                        Row(
                          children: [
                            if (viewModel.isEditing && isAdmin) ...[
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: viewModel.isLoading
                                      ? null
                                      : () => _confirmDelete(context, viewModel, userId),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFEE2E2), // red-100
                                    foregroundColor: AppColors.error,
                                    elevation: 0,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                  ),
                                  child: viewModel.isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.error),
                                          ),
                                        )
                                      : const Text(
                                          'Ngừng bán',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              flex: 2,
                              child: AppButton(
                                text: viewModel.isEditing ? 'Cập nhật sản phẩm' : 'Thêm sản phẩm',
                                isLoading: viewModel.isLoading,
                                onPressed: () async {
                                  final success = await viewModel.save(userId);
                                  if (success && context.mounted) {
                                    AppToast.showSuccess(
                                      context,
                                      viewModel.isEditing
                                          ? 'Cập nhật sản phẩm thành công!'
                                          : 'Thêm sản phẩm mới thành công!',
                                    );
                                    context.pop(true);
                                  }
                                },
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
        },
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    ProductFormViewModel viewModel,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xác nhận ngừng bán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn ngừng bán sản phẩm này?',
        ),
        actions: [
          TextButton(
            child: const Text('Hủy', style: TextStyle(color: AppColors.detail)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: AppColors.error),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await viewModel.deleteProduct(userId);
              if (success && context.mounted) {
                AppToast.showSuccess(
                  context,
                  'Đã chuyển trạng thái sản phẩm thành ngừng bán.',
                );
                context.pop(true); // quay lại danh sách
              } else if (context.mounted) {
                AppToast.showError(context, viewModel.errorMessage ?? 'Xóa sản phẩm thất bại.');
              }
            },
          ),
        ],
      ),
    );
  }
}
