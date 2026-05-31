import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../viewmodel/customer_cart_view_model.dart';

class CustomerCartView extends StatefulWidget {
  const CustomerCartView({super.key});

  @override
  State<CustomerCartView> createState() => _CustomerCartViewState();
}

class _CustomerCartViewState extends State<CustomerCartView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerCartViewModel>().loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerCartViewModel>(
      builder: (context, viewModel, child) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: viewModel.isLoading
              ? const AppLoading(key: ValueKey('cart-loading'))
              : _CartContent(
                  key: const ValueKey('cart-content'),
                  viewModel: viewModel,
                ),
        );
      },
    );
  }
}

class _CartContent extends StatelessWidget {
  final CustomerCartViewModel viewModel;

  const _CartContent({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: viewModel.loadCart,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (viewModel.errorMessage != null)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          if (viewModel.entries.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: _EmptyCart())
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.separated(
                itemCount: viewModel.entries.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = viewModel.entries[index];
                  return _CartItemCard(entry: entry, viewModel: viewModel);
                },
              ),
            ),
          if (viewModel.entries.isNotEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _CartSummary(viewModel: viewModel),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CustomerCartEntry entry;
  final CustomerCartViewModel viewModel;

  const _CartItemCard({required this.entry, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final isPending = viewModel.isProductPending(entry.product.id);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isPending ? 0.65 : 1,
      child: Card(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: viewModel.isProductSelected(entry.product.id),
                  onChanged: isPending
                      ? null
                      : (value) => viewModel.toggleProductSelection(
                          entry.product.id,
                          value,
                        ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 4),
              _CartImage(
                imageUrl: entry.product.imageUrls.isEmpty
                    ? null
                    : entry.product.imageUrls.first,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.product.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatPrice(entry.product.price),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        IconButton(
                          onPressed: isPending
                              ? null
                              : () => _decreaseQuantity(context),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: Text(
                            '${entry.quantity}',
                            key: ValueKey(entry.quantity),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          onPressed: isPending
                              ? null
                              : () => _increaseQuantity(context),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        if (isPending)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: isPending ? null : () => _removeProduct(context),
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _increaseQuantity(BuildContext context) async {
    final result = await viewModel.addProduct(entry.product);
    if (context.mounted && result == CartMutationResult.outOfStock) {
      AppToast.showError(context, 'Số lượng trong giỏ đã đạt tồn kho.');
    }
  }

  Future<void> _decreaseQuantity(BuildContext context) async {
    final result = await viewModel.decreaseQuantity(entry.product);
    if (context.mounted && result == CartMutationResult.failed) {
      AppToast.showError(context, 'Không thể cập nhật số lượng sản phẩm.');
    }
  }

  Future<void> _removeProduct(BuildContext context) async {
    final result = await viewModel.removeProduct(entry.product.id);
    if (context.mounted && result == CartMutationResult.failed) {
      AppToast.showError(context, 'Không thể xóa sản phẩm khỏi giỏ hàng.');
    }
  }
}

class _CartSummary extends StatelessWidget {
  final CustomerCartViewModel viewModel;

  const _CartSummary({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final hasSelection = viewModel.selectedItemCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${viewModel.selectedItemCount}/${viewModel.itemCount} sản phẩm đã chọn',
                    style: const TextStyle(
                      color: AppColors.detail,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: !hasSelection
                        ? const Text(
                            'Chọn sản phẩm để tính tổng',
                            key: ValueKey('empty-selection'),
                            style: TextStyle(
                              color: AppColors.detail,
                              fontSize: 14,
                            ),
                          )
                        : Text(
                            _formatPrice(viewModel.selectedTotalAmount),
                            key: ValueKey(viewModel.selectedTotalAmount),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            if (hasSelection) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: AppButton(
                  text: 'Thanh toán',
                  onPressed: () => context.push('/checkout'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 56, color: AppColors.detail),
          SizedBox(height: 12),
          Text('Giỏ hàng của bạn đang trống.'),
          SizedBox(height: 4),
          Text(
            'Kéo xuống để đồng bộ lại giỏ hàng.',
            style: TextStyle(color: AppColors.detail),
          ),
        ],
      ),
    );
  }
}

class _CartImage extends StatelessWidget {
  final String? imageUrl;

  const _CartImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 80,
      height: 80,
      color: AppColors.background,
      child: const Icon(Icons.shopping_bag_outlined, color: AppColors.detail),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return placeholder;
    return AppNetworkImage(
      imageUrl: imageUrl!,
      width: 80,
      height: 80,
      borderRadius: 8,
      fit: BoxFit.cover,
      placeholder: placeholder,
      errorWidget: placeholder,
    );
  }
}

String _formatPrice(double value) {
  return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(value);
}
