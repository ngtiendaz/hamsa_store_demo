import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../viewmodel/category_list_view_model.dart';
import '../../../user/auth/viewmodel/auth_viewmodel.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';

class CategoryListView extends StatefulWidget {
  const CategoryListView({super.key});

  @override
  State<CategoryListView> createState() => _CategoryListViewState();
}

class _CategoryListViewState extends State<CategoryListView> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isAdmin = authViewModel.currentProfile?.isAdmin ?? false;

    return ChangeNotifierProvider<CategoryListViewModel>(
      create: (_) => CategoryListViewModel(),
      child: Consumer<CategoryListViewModel>(
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
                            : viewModel.categories.isEmpty
                                ? _buildEmptyState()
                                : isDesktop
                                    ? _buildCategoryTable(context, viewModel, isAdmin)
                                    : _buildCategoryCardList(context, viewModel, isAdmin),
                      ),
                      // Pagination
                      if (viewModel.categories.isNotEmpty)
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
    CategoryListViewModel viewModel,
    bool isAdmin,
    bool isDesktop,
  ) {
    final searchField = Container(
      constraints: BoxConstraints(maxWidth: isDesktop ? 300 : double.infinity),
      child: TextField(
        onChanged: viewModel.setKeyword,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tên danh mục...',
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
                text: 'Thêm danh mục',
                onPressed: () async {
                  final result = await context.push('/admin/categories/new');
                  if (result == true) {
                    viewModel.loadCategories(refresh: true);
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
          AppButton(
            text: 'Thêm danh mục',
            onPressed: () async {
              final result = await context.push('/admin/categories/new');
              if (result == true) {
                viewModel.loadCategories(refresh: true);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryTable(
    BuildContext context,
    CategoryListViewModel viewModel,
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
                    'TÊN DANH MỤC',
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
              itemCount: viewModel.categories.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.background),
              itemBuilder: (context, index) {
                final cat = viewModel.categories[index];
                return Material(
                  color: AppColors.surface,
                  child: InkWell(
                    onTap: () async {
                      final result = await context.push('/admin/categories/edit', extra: cat);
                      if (result == true) {
                        viewModel.loadCategories();
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
                            child: Text(
                              cat.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: Text(
                              cat.description ?? '-',
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

  Widget _buildCategoryCardList(
    BuildContext context,
    CategoryListViewModel viewModel,
    bool isAdmin,
  ) {
    return ListView.builder(
      itemCount: viewModel.categories.length,
      itemBuilder: (context, index) {
        final cat = viewModel.categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          borderOnForeground: false,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final result = await context.push('/admin/categories/edit', extra: cat);
              if (result == true) {
                viewModel.loadCategories();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.description ?? 'Không có mô tả',
                    style: const TextStyle(color: AppColors.detail, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Trạng thái hoạt động đã được lược bỏ theo yêu cầu

  Widget _buildPaginationFooter(CategoryListViewModel viewModel) {
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
                onPressed: viewModel.hasPreviousPage ? viewModel.previousPage : null,
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
        'Không tìm thấy danh mục nào.',
        style: TextStyle(color: AppColors.detail, fontSize: 16),
      ),
    );
  }
}

class WidthBox extends StatelessWidget {
  final double width;
  const WidthBox(this.width, {super.key});
  @override
  Widget build(BuildContext context) => SizedBox(width: width);
}
