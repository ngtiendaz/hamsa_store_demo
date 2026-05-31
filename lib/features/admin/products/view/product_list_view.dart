import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../viewmodel/product_list_view_model.dart';
import '../../../login/auth/viewmodel/auth_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import 'widgets/product_image_widget.dart';

class ProductListView extends StatefulWidget {
  const ProductListView({super.key});

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isAdmin = authViewModel.currentProfile?.isAdmin ?? false;

    return ChangeNotifierProvider<ProductListViewModel>(
      create: (_) => ProductListViewModel(),
      child: Consumer<ProductListViewModel>(
        builder: (context, viewModel, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header & Filters
                      _buildHeaderAndFilters(
                        context,
                        viewModel,
                        isAdmin,
                        isDesktop,
                      ),
                      const SizedBox(height: 24),
                      // Product Table/List
                      Expanded(
                        child: viewModel.isLoading
                            ? const AppLoading()
                            : viewModel.products.isEmpty
                            ? _buildEmptyState()
                            : isDesktop
                            ? _buildProductTable(context, viewModel, isAdmin)
                            : _buildProductCardList(
                                context,
                                viewModel,
                                isAdmin,
                              ),
                      ),
                      // Pagination Footer
                      if (viewModel.products.isNotEmpty)
                        _buildPaginationFooter(viewModel),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderAndFilters(
    BuildContext context,
    ProductListViewModel viewModel,
    bool isAdmin,
    bool isDesktop,
  ) {
    final searchField = Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 300 : double.infinity),
      child: TextField(
        onChanged: viewModel.setKeyword,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tên, barcode...',
          prefixIcon: const Icon(Icons.search, color: AppColors.detail),
          fillColor: AppColors.surface,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );

    final categoryFilter = Container(
      width: isDesktop ? 200 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: viewModel.selectedCategoryId,
          hint: const Text('Tất cả Danh mục', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tất cả Danh mục', style: TextStyle(fontSize: 14)),
            ),
            ...viewModel.categories.map(
              (cat) => DropdownMenuItem<String?>(
                value: cat.id,
                child: Text(cat.name, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
          onChanged: viewModel.selectCategory,
        ),
      ),
    );

    final brandFilter = Container(
      width: isDesktop ? 200 : double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: viewModel.selectedBrandId,
          hint: const Text('Tất cả Nhãn hàng', style: TextStyle(fontSize: 14)),
          isExpanded: true,
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tất cả Nhãn hàng', style: TextStyle(fontSize: 14)),
            ),
            ...viewModel.brands.map(
              (brand) => DropdownMenuItem<String?>(
                value: brand.id,
                child: Text(brand.name, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
          onChanged: viewModel.selectBrand,
        ),
      ),
    );

    final addButton = isAdmin
        ? AppButton(
            text: 'Thêm sản phẩm',
            onPressed: () async {
              final result = await context.push('/admin/products/new');
              if (result == true) {
                viewModel.loadProducts(refresh: true);
              }
            },
          )
        : const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 768) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [searchField, categoryFilter, brandFilter],
                ),
              ),
              if (isAdmin) ...[const SizedBox(width: 16), addButton],
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              const SizedBox(height: 12),
              categoryFilter,
              const SizedBox(height: 12),
              brandFilter,
              if (isAdmin) ...[const SizedBox(height: 16), addButton],
            ],
          );
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.detail,
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy sản phẩm nào',
            style: AppTextStyles.headlineMd.copyWith(color: AppColors.detail),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTable(
    BuildContext context,
    ProductListViewModel viewModel,
    bool isAdmin,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.surface, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Table Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              vertical: 16.0,
              horizontal: 12.0,
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Center(
                    child: Text(
                      'ẢNH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.detail,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'TÊN SẢN PHẨM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.detail,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'BARCODE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.detail,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'ĐƠN GIÁ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.detail,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Center(
                    child: Text(
                      'TỒN KHO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.detail,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: Center(
                    child: Text(
                      'TRẠNG THÁI',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.detail,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          Flexible(
            child: ListView.builder(
              itemCount: viewModel.products.length,
              itemBuilder: (context, index) {
                final product = viewModel.products[index];
                return InkWell(
                  onTap: () async {
                    final result = await context.push(
                      '/admin/products/edit',
                      extra: product,
                    );
                    if (result == true) {
                      viewModel.loadProducts(refresh: true);
                    }
                  },
                  hoverColor: AppColors.surface.withValues(alpha: 0.5),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.surface, width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 12.0,
                    ),
                    child: Row(
                      children: [
                        // Image (centered)
                        SizedBox(
                          width: 80,
                          child: Center(
                            child: ProductImageWidget(
                              imageUrl: product.imageUrls.isNotEmpty
                                  ? product.imageUrls.first
                                  : null,
                              size: 50,
                            ),
                          ),
                        ),
                        // Name (left aligned)
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (product.tradeName != null)
                                  Text(
                                    product.internalName,
                                    style: const TextStyle(
                                      color: AppColors.detail,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // Barcode (centered)
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              product.barcode ?? '-',
                              style: AppTextStyles.labelMd,
                            ),
                          ),
                        ),
                        // Price (centered)
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              currencyFormat.format(product.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        // Stock (centered)
                        SizedBox(
                          width: 100,
                          child: Center(
                            child: Text(
                              '${product.stock}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: product.stock < 5
                                    ? AppColors.error
                                    : AppColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                        // Status (centered)
                        SizedBox(
                          width: 130,
                          child: Center(
                            child: _buildStatusBadge(product.isActive),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCardList(
    BuildContext context,
    ProductListViewModel viewModel,
    bool isAdmin,
  ) {
    return ListView.builder(
      itemCount: viewModel.products.length,
      itemBuilder: (context, index) {
        final product = viewModel.products[index];
        return Card(
          color: AppColors.surface,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            onTap: () async {
              final result = await context.push(
                '/admin/products/edit',
                extra: product,
              );
              if (result == true) {
                viewModel.loadProducts(refresh: true);
              }
            },
            leading: ProductImageWidget(
              imageUrl: product.imageUrls.isNotEmpty
                  ? product.imageUrls.first
                  : null,
              size: 60,
            ),
            title: Text(
              product.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(product.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tồn: ${product.stock}',
                  style: TextStyle(
                    fontSize: 12,
                    color: product.stock < 5
                        ? AppColors.error
                        : AppColors.detail,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE2FBE9) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Hoạt động' : 'Ngừng bán',
        style: TextStyle(
          color: isActive ? const Color(0xFF0F8644) : AppColors.detail,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(ProductListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: viewModel.hasPreviousPage
                ? viewModel.previousPage
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            'Trang ${viewModel.currentPage} / ${viewModel.totalPages}  (Tổng: ${viewModel.totalCount} sản phẩm)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: viewModel.hasNextPage ? viewModel.nextPage : null,
          ),
        ],
      ),
    );
  }
}
