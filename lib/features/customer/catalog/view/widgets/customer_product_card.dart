import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../../../../data/models/products_model.dart';
import '../../../cart/viewmodel/customer_cart_view_model.dart';

class CustomerProductCard extends StatelessWidget {
  final ProductModel product;
  final CustomerCartViewModel cartViewModel;

  const CustomerProductCard({
    super.key,
    required this.product,
    required this.cartViewModel,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = cartViewModel.isProductPending(product.id);
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/shop/products/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ProductImage(
                imageUrl: product.imageUrls.isEmpty
                    ? null
                    : product.imageUrls.first,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(product.price),
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: product.stock <= 0 || isPending
                          ? null
                          : () => _addToCart(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: isPending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_shopping_cart, size: 16),
                      label: Text(
                        product.stock <= 0
                            ? 'Hết hàng'
                            : isPending
                            ? 'Đang thêm...'
                            : 'Thêm giỏ hàng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    final result = await cartViewModel.addProduct(product);
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

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: AppColors.detail,
        size: 44,
      ),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}

String _formatPrice(double value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(value);
}
