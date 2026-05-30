import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../data/models/products_model.dart';
import '../../cart/viewmodel/customer_cart_view_model.dart';
import '../viewmodel/customer_product_detail_view_model.dart';

class CustomerProductDetailView extends StatelessWidget {
  final String productId;

  const CustomerProductDetailView({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerProductDetailViewModel()..loadProduct(productId),
      child: Consumer<CustomerProductDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) return const AppLoading();
          if (viewModel.errorMessage != null || viewModel.product == null) {
            return Center(
              child: Text(viewModel.errorMessage ?? 'Không tìm thấy sản phẩm.'),
            );
          }

          final product = viewModel.product!;
          final cartViewModel = context.watch<CustomerCartViewModel>();
          final isPending = cartViewModel.isProductPending(product.id);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 760;
                    final image = _ProductGallery(imageUrls: product.imageUrls);
                    final info = _ProductInformation(
                      name: product.displayName,
                      internalName: product.internalName,
                      barcode: product.barcode,
                      description: product.description,
                      price: product.price,
                      stock: product.stock,
                      isPending: isPending,
                      onAddToCart: product.stock <= 0 || isPending
                          ? null
                          : () => _addToCart(context, product),
                    );
                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: image),
                          const SizedBox(width: 32),
                          Expanded(child: info),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [image, const SizedBox(height: 20), info],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _addToCart(BuildContext context, ProductModel product) async {
    final result = await context.read<CustomerCartViewModel>().addProduct(
      product,
    );
    if (!context.mounted) return;
    switch (result) {
      case CartMutationResult.success:
        AppToast.showSuccess(context, 'Đã thêm sản phẩm vào giỏ hàng.');
      case CartMutationResult.outOfStock:
        AppToast.showError(context, 'Số lượng trong giỏ đã đạt tồn kho.');
      case CartMutationResult.unauthenticated:
        AppToast.showError(context, 'Vui lòng đăng nhập để thêm sản phẩm.');
      case CartMutationResult.failed:
        AppToast.showError(
          context,
          'Không thể thêm sản phẩm. Vui lòng thử lại.',
        );
      case CartMutationResult.busy:
        break;
    }
  }
}

class _ProductGallery extends StatelessWidget {
  final List<String> imageUrls;

  const _ProductGallery({required this.imageUrls});

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrls.isEmpty ? null : imageUrls.first;
    final placeholder = Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.shopping_bag_outlined,
        size: 72,
        color: AppColors.detail,
      ),
    );

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl == null
            ? placeholder
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}

class _ProductInformation extends StatelessWidget {
  final String name;
  final String internalName;
  final String? barcode;
  final String? description;
  final double price;
  final int stock;
  final bool isPending;
  final VoidCallback? onAddToCart;

  const _ProductInformation({
    required this.name,
    required this.internalName,
    required this.barcode,
    required this.description,
    required this.price,
    required this.stock,
    required this.isPending,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price),
          style: const TextStyle(
            color: AppColors.error,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        _DetailRow(label: 'Tên nội bộ', value: internalName),
        _DetailRow(label: 'Barcode', value: barcode ?? '-'),
        _DetailRow(label: 'Tồn kho', value: '$stock sản phẩm'),
        const SizedBox(height: 16),
        const Text(
          'Mô tả sản phẩm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(description?.trim().isNotEmpty == true ? description! : '-'),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onAddToCart,
            icon: isPending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_shopping_cart),
            label: Text(
              stock <= 0
                  ? 'Sản phẩm đã hết hàng'
                  : isPending
                  ? 'Đang thêm vào giỏ...'
                  : 'Thêm vào giỏ hàng',
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: AppColors.detail)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
