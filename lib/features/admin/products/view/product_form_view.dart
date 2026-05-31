import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/product_form_view_model.dart';
import '../../../login/auth/viewmodel/auth_viewmodel.dart';
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
  late final TextEditingController _internalNameController;
  late final TextEditingController _tradeNameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final p = widget.productToEdit;
    _internalNameController = TextEditingController(
      text: p?.internalName ?? '',
    );
    _tradeNameController = TextEditingController(text: p?.tradeName ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _priceController = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toString() : '',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
  }

  @override
  void dispose() {
    _internalNameController.dispose();
    _tradeNameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final userId = authViewModel.currentProfile?.id ?? '';
    final isAdmin = authViewModel.currentProfile?.isAdmin ?? false;

    return ChangeNotifierProvider<ProductFormViewModel>(
      create: (_) => ProductFormViewModel()..init(widget.productToEdit),
      child: Consumer<ProductFormViewModel>(
        builder: (context, viewModel, child) {
          final isMobile = MediaQuery.sizeOf(context).width <= 600;
          return PopScope(
            canPop: !viewModel.isChanged,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              final action = await _showDiscardChangesDialog(
                context,
                viewModel,
                userId,
              );
              if (action == null) return;
              if (action == false) {
                if (context.mounted) {
                  Navigator.of(context).pop(false);
                }
              } else if (action == true) {
                viewModel.setInternalName(_internalNameController.text);
                viewModel.setTradeName(_tradeNameController.text);
                viewModel.setBarcode(_barcodeController.text);
                viewModel.setPrice(
                  double.tryParse(_priceController.text) ?? 0.0,
                );
                viewModel.setStock(int.tryParse(_stockController.text) ?? 0);
                viewModel.setDescription(_descriptionController.text);

                final success = await viewModel.save(userId);
                if (success && context.mounted) {
                  AppToast.showSuccess(
                    context,
                    viewModel.isEditing
                        ? 'Cập nhật sản phẩm thành công!'
                        : 'Thêm sản phẩm mới thành công!',
                  );
                  Navigator.of(context).pop(true);
                }
              }
            },
            child: Scaffold(
              backgroundColor: AppColors.background,
              // Đã loại bỏ appBar phụ để đưa nút quay lại và tiêu đề lên layout chính
              appBar: null,
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

                      // Web giữ nút trên header; mobile đưa nút xuống cuối form.
                      if (isMobile)
                        Text(
                          viewModel.isEditing
                              ? 'THÔNG TIN CHI TIẾT'
                              : 'THÊM MỚI SẢN PHẨM',
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
                                  ? 'THÔNG TIN CHI TIẾT'
                                  : 'THÊM MỚI SẢN PHẨM',
                              style: AppTextStyles.headlineMd.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            _buildProductActions(
                              context,
                              viewModel,
                              userId,
                              isAdmin,
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Lưới hiển thị nhiều ảnh
                      _buildImageSelector(viewModel),
                      const SizedBox(height: 24),

                      // Internal Name
                      AppTextField(
                        label: 'Tên nội bộ (Bắt buộc)',
                        hintText: 'Nhập tên sử dụng nội bộ...',
                        controller: _internalNameController,
                        onChanged: viewModel.setInternalName,
                        errorText:
                            viewModel.internalName.trim().isEmpty &&
                                viewModel.errorMessage != null
                            ? 'Tên nội bộ là bắt buộc.'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Trade Name
                      AppTextField(
                        label: 'Tên thương mại (Bắt buộc)',
                        hintText: 'Nhập tên hiển thị thương mại...',
                        controller: _tradeNameController,
                        onChanged: viewModel.setTradeName,
                        errorText:
                            (viewModel.tradeName ?? '').trim().isEmpty &&
                                viewModel.errorMessage != null
                            ? 'Tên thương mại là bắt buộc.'
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Barcode
                      AppTextField(
                        label: 'Barcode',
                        hintText: 'Mã vạch sản phẩm...',
                        controller: _barcodeController,
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
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: (val) => viewModel.setPrice(
                                double.tryParse(val) ?? 0.0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Số lượng tồn kho',
                              hintText: '0',
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              onChanged: (val) =>
                                  viewModel.setStock(int.tryParse(val) ?? 0),
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
                                const Text(
                                  'DANH MỤC',
                                  style: AppTextStyles.labelMd,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: viewModel.categoryId.isEmpty
                                          ? null
                                          : viewModel.categoryId,
                                      isExpanded: true,
                                      items: viewModel.categories
                                          .map(
                                            (cat) => DropdownMenuItem(
                                              value: cat.id,
                                              child: Text(cat.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          viewModel.setCategoryId(val);
                                        }
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
                                const Text(
                                  'NHÃN HÀNG',
                                  style: AppTextStyles.labelMd,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: viewModel.brandId.isEmpty
                                          ? null
                                          : viewModel.brandId,
                                      isExpanded: true,
                                      items: viewModel.brands
                                          .map(
                                            (brand) => DropdownMenuItem(
                                              value: brand.id,
                                              child: Text(brand.name),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          viewModel.setBrandId(val);
                                        }
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
                          const Text(
                            'TRẠNG THÁI KINH DOANH',
                            style: AppTextStyles.labelMd,
                          ),
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
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Đang hoạt động'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'inactive',
                                    child: Text('Ngừng bán'),
                                  ),
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
                        controller: _descriptionController,
                        keyboardType: TextInputType.multiline,
                        minLines: 5,
                        onChanged: viewModel.setDescription,
                      ),
                      if (isMobile) ...[
                        const SizedBox(height: 24),
                        _buildProductActions(
                          context,
                          viewModel,
                          userId,
                          isAdmin,
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

  Widget _buildImageSelector(ProductFormViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ẢNH SẢN PHẨM', style: AppTextStyles.labelMd),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // List of images
            ...viewModel.images.map((item) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.bytes != null
                        ? Image.memory(
                            item.bytes!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                          )
                        : ProductImageWidget(
                            imageUrl: item.url,
                            size: 100,
                            borderRadius: 12,
                          ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: () => viewModel.removeImage(item),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
            // Card "Thêm ảnh"
            InkWell(
              onTap: viewModel.pickImages,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 24,
                      color: AppColors.detail,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Thêm ảnh',
                      style: TextStyle(
                        color: AppColors.detail,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductActions(
    BuildContext context,
    ProductFormViewModel viewModel,
    String userId,
    bool isAdmin, {
    bool isMobile = false,
  }) {
    final deleteButton = ElevatedButton(
      onPressed: viewModel.isLoading
          ? null
          : () => _confirmDelete(context, viewModel, userId),
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
              'Xóa sản phẩm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
    );
    final saveButton = AppButton(
      text: viewModel.isEditing ? 'Cập nhật' : 'Thêm sản phẩm',
      isLoading: viewModel.isLoading,
      onPressed: (!viewModel.isChanged || viewModel.isLoading)
          ? null
          : () => _saveProduct(context, viewModel, userId),
    );

    if (isMobile) {
      return Row(
        children: [
          if (viewModel.isEditing && isAdmin) ...[
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
        if (viewModel.isEditing && isAdmin) ...[
          SizedBox(width: 200, child: deleteButton),
          const SizedBox(width: 12),
        ],
        SizedBox(width: 200, child: saveButton),
      ],
    );
  }

  Future<void> _saveProduct(
    BuildContext context,
    ProductFormViewModel viewModel,
    String userId,
  ) async {
    viewModel.setInternalName(_internalNameController.text);
    viewModel.setTradeName(_tradeNameController.text);
    viewModel.setBarcode(_barcodeController.text);
    viewModel.setPrice(double.tryParse(_priceController.text) ?? 0.0);
    viewModel.setStock(int.tryParse(_stockController.text) ?? 0);
    viewModel.setDescription(_descriptionController.text);

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
          'Xác nhận xóa sản phẩm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Nếu sản phẩm đã có trong giỏ hàng hoặc đơn hàng, hệ thống chỉ chuyển sang ngừng bán. Nếu chưa có dữ liệu liên quan, sản phẩm sẽ bị xóa vĩnh viễn.',
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
                  viewModel.deleteResult == 'deleted'
                      ? 'Đã xóa sản phẩm vĩnh viễn.'
                      : 'Sản phẩm đã có dữ liệu liên quan nên chỉ được chuyển sang ngừng bán.',
                );
                context.pop(true); // quay lại danh sách
              } else if (context.mounted) {
                AppToast.showError(
                  context,
                  viewModel.errorMessage ?? 'Xóa sản phẩm thất bại.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDiscardChangesDialog(
    BuildContext context,
    ProductFormViewModel viewModel,
    String userId,
  ) async {
    return showDialog<bool?>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Thay đổi chưa được lưu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn đã thay đổi thông tin sản phẩm. Bạn có muốn lưu các thay đổi này không?',
        ),
        actions: [
          TextButton(
            child: const Text('Hủy', style: TextStyle(color: AppColors.detail)),
            onPressed: () => Navigator.pop(ctx, null),
          ),
          TextButton(
            child: const Text(
              'Không lưu',
              style: TextStyle(color: AppColors.error),
            ),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
  }
}
