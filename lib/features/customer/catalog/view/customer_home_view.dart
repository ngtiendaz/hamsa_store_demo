import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../customer/cart/viewmodel/customer_cart_view_model.dart';
import '../viewmodel/customer_home_view_model.dart';
import 'widgets/customer_product_card.dart';

class CustomerHomeView extends StatefulWidget {
  const CustomerHomeView({super.key});

  @override
  State<CustomerHomeView> createState() => _CustomerHomeViewState();
}

class _CustomerHomeViewState extends State<CustomerHomeView> {
  final ScrollController _scrollController = ScrollController();
  late final CustomerHomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CustomerHomeViewModel();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _changePage(Future<void> Function() action) async {
    await action();
    if (!mounted || !_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer2<CustomerHomeViewModel, CustomerCartViewModel>(
        builder: (context, viewModel, cartViewModel, child) {
          return RefreshIndicator(
            onRefresh: () => viewModel.loadProducts(refresh: true),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(viewModel)),
                if (viewModel.isLoading && viewModel.products.isEmpty)
                  const SliverFillRemaining(child: AppLoading())
                else if (viewModel.errorMessage != null &&
                    viewModel.products.isEmpty)
                  SliverFillRemaining(
                    child: _MessageState(
                      message: viewModel.errorMessage!,
                      onRetry: () => viewModel.loadProducts(refresh: true),
                    ),
                  )
                else if (viewModel.products.isEmpty)
                  const SliverFillRemaining(
                    child: _MessageState(
                      message: 'Không tìm thấy sản phẩm phù hợp.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final crossAxisCount = width >= 1100
                            ? 5
                            : width >= 800
                            ? 4
                            : width >= 560
                            ? 3
                            : 2;
                        return SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => CustomerProductCard(
                              product: viewModel.products[index],
                              cartViewModel: cartViewModel,
                            ),
                            childCount: viewModel.products.length,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: width < 560 ? 0.58 : 0.68,
                              ),
                        );
                      },
                    ),
                  ),
                if (viewModel.products.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _PaginationBar(
                      currentPage: viewModel.currentPage,
                      totalPages: viewModel.totalPages,
                      totalCount: viewModel.totalCount,
                      isLoading: viewModel.isLoading,
                      onPrevious: viewModel.hasPreviousPage
                          ? () => _changePage(viewModel.previousPage)
                          : null,
                      onNext: viewModel.hasNextPage
                          ? () => _changePage(viewModel.nextPage)
                          : null,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(CustomerHomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: viewModel.setKeyword,
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm sản phẩm...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final filters = [
                _FilterDropdown(
                  value: viewModel.selectedCategoryId,
                  hint: 'Danh mục',
                  items: viewModel.categories
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: viewModel.setCategory,
                ),
                _FilterDropdown(
                  value: viewModel.selectedBrandId,
                  hint: 'Nhãn hàng',
                  items: viewModel.brands
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: viewModel.setBrand,
                ),
              ];
              if (constraints.maxWidth < 560) {
                return Row(
                  children: [
                    Expanded(child: filters[0]),
                    const SizedBox(width: 12),
                    Expanded(child: filters[1]),
                  ],
                );
              }
              return Row(
                children: [
                  SizedBox(width: 240, child: filters[0]),
                  const SizedBox(width: 12),
                  SizedBox(width: 240, child: filters[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'Sản phẩm nổi bật',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final bool isLoading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: isLoading ? null : onPrevious,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Trước'),
          ),
          Text(
            'Trang $currentPage/$totalPages ($totalCount sản phẩm)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onNext,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Sau'),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(contentPadding: EdgeInsets.all(14)),
      hint: Text(hint),
      items: [
        DropdownMenuItem(value: '', child: Text('Tất cả $hint')),
        ...items,
      ],
      onChanged: onChanged,
    );
  }
}

class _MessageState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _MessageState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.detail,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ],
        ),
      ),
    );
  }
}
