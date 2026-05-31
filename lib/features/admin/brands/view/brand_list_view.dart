import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/brand_list_view_model.dart';
import '../../../user/auth/viewmodel/auth_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_network_image.dart';

class BrandListView extends StatefulWidget {
  const BrandListView({super.key});

  @override
  State<BrandListView> createState() => _BrandListViewState();
}

class _BrandListViewState extends State<BrandListView> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isAdmin = authViewModel.currentProfile?.isAdmin ?? false;

    return ChangeNotifierProvider<BrandListViewModel>(
      create: (_) => BrandListViewModel(),
      child: Consumer<BrandListViewModel>(
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
                      // List / Table
                      Expanded(
                        child: viewModel.isLoading
                            ? const AppLoading()
                            : viewModel.brands.isEmpty
                            ? _buildEmptyState()
                            : isDesktop
                            ? _buildBrandTable(context, viewModel, isAdmin)
                            : _buildBrandCardList(context, viewModel, isAdmin),
                      ),
                      // Pagination
                      if (viewModel.brands.isNotEmpty)
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
    BrandListViewModel viewModel,
    bool isAdmin,
    bool isDesktop,
  ) {
    final searchField = Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 300 : double.infinity),
      child: TextField(
        onChanged: viewModel.setKeyword,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tên nhãn hàng...',
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

    if (isDesktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          searchField,
          if (isAdmin)
            SizedBox(
              width: 220,
              child: AppButton(
                text: 'Thêm nhãn hàng',
                onPressed: () async {
                  final result = await context.push('/admin/brands/new');
                  if (result == true) {
                    viewModel.loadBrands(refresh: true);
                  }
                },
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchField,
        if (isAdmin) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await context.push('/admin/brands/new');
                if (result == true) {
                  viewModel.loadBrands(refresh: true);
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Thêm nhãn hàng'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBrandTable(
    BuildContext context,
    BrandListViewModel viewModel,
    bool isAdmin,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'TÊN NHÃN HÀNG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.detail,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: Text(
                    'MÔ TẢ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.detail,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.background),
          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: viewModel.brands.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.background),
              itemBuilder: (context, index) {
                final brand = viewModel.brands[index];
                return Material(
                  color: AppColors.surface,
                  child: InkWell(
                    onTap: () async {
                      final result = await context.push(
                        '/admin/brands/edit',
                        extra: brand,
                      );
                      if (result == true) {
                        viewModel.loadBrands();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                if (brand.logoUrl != null &&
                                    brand.logoUrl!.trim().isNotEmpty) ...[
                                  AppNetworkImage(
                                    imageUrl: brand.logoUrl!,
                                    width: 28,
                                    height: 28,
                                    borderRadius: 4,
                                    fit: BoxFit.cover,
                                    placeholder: const Icon(
                                      Icons.stars,
                                      size: 28,
                                      color: AppColors.detail,
                                    ),
                                    errorWidget: const Icon(
                                      Icons.stars,
                                      size: 28,
                                      color: AppColors.detail,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Text(
                                    brand.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: Text(
                              brand.description ?? '-',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.detail),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildBrandCardList(
    BuildContext context,
    BrandListViewModel viewModel,
    bool isAdmin,
  ) {
    return ListView.builder(
      itemCount: viewModel.brands.length,
      itemBuilder: (context, index) {
        final brand = viewModel.brands[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          borderOnForeground: false,
          child: SizedBox(
            height: 112,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final result = await context.push(
                  '/admin/brands/edit',
                  extra: brand,
                );
                if (result == true) {
                  viewModel.loadBrands();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (brand.logoUrl != null &&
                                                            brand.logoUrl!.trim().isNotEmpty) ...[
                          AppNetworkImage(
                            imageUrl: brand.logoUrl!,
                            width: 24,
                            height: 24,
                            borderRadius: 4,
                            fit: BoxFit.cover,
                            placeholder: const Icon(
                              Icons.stars,
                              size: 24,
                              color: AppColors.detail,
                            ),
                            errorWidget: const Icon(
                              Icons.stars,
                              size: 24,
                              color: AppColors.detail,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            brand.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      brand.description ?? 'Không có mô tả',
                      style: const TextStyle(
                        color: AppColors.detail,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationFooter(BrandListViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Trang ${viewModel.currentPage}/${viewModel.totalPages} (Tổng số: ${viewModel.totalCount})',
            style: const TextStyle(color: AppColors.detail, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: viewModel.hasPreviousPage
                    ? viewModel.previousPage
                    : null,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: viewModel.hasNextPage ? viewModel.nextPage : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'Không tìm thấy nhãn hàng nào.',
        style: TextStyle(color: AppColors.detail, fontSize: 16),
      ),
    );
  }
}
