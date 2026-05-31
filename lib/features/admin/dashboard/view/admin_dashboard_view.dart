import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../data/models/admin_dashboard_stats_model.dart';
import '../viewmodel/admin_dashboard_view_model.dart';
import 'widgets/dashboard_product_list.dart';
import 'widgets/dashboard_summary_card.dart';

class AdminDashboardView extends StatelessWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminDashboardViewModel()..loadStats(),
      child: const _AdminDashboardBody(),
    );
  }
}

class _AdminDashboardBody extends StatelessWidget {
  const _AdminDashboardBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AdminDashboardViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.stats == null) {
            return const AppLoading();
          }

          if (viewModel.stats == null) {
            return _DashboardError(
              message: viewModel.errorMessage ?? 'Không thể tải dashboard.',
              onRetry: viewModel.loadStats,
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.loadStats,
            child: _DashboardContent(
              stats: viewModel.stats!,
              viewModel: viewModel,
            ),
          );
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final AdminDashboardStatsModel stats;
  final AdminDashboardViewModel viewModel;

  const _DashboardContent({required this.stats, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final inclusiveEndAt = stats.endAt.subtract(const Duration(days: 1));
    final periodText =
        '${formatVietnamDateTime(stats.startAt, pattern: 'dd/MM/yyyy')} - '
        '${formatVietnamDateTime(inclusiveEndAt, pattern: 'dd/MM/yyyy')}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final columns = contentWidth >= 1250
            ? 4
            : contentWidth >= 720
            ? 2
            : 1;
        final cardWidth = (contentWidth - 32 - (columns - 1) * 14) / columns;
        final useTwoColumns = contentWidth >= 1050;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _DashboardHeader(
              period: viewModel.period,
              referenceDate: viewModel.referenceDate,
              periodText: periodText,
              isLoading: viewModel.isLoading,
              onPeriodChanged: viewModel.changePeriod,
              onReferenceDateChanged: viewModel.changeReferenceDate,
              onMonthChanged: viewModel.changeMonth,
              onYearChanged: viewModel.changeYear,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: DashboardSummaryCard(
                    label: 'Doanh thu',
                    value: currency.format(stats.revenue),
                    detail: 'Doanh thu ròng từ đơn đã giao',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF1B8A5A),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardSummaryCard(
                    label: 'Đang giao',
                    value: '${stats.shippingCount}',
                    detail: 'Đơn hàng đang vận chuyển',
                    icon: Icons.local_shipping_outlined,
                    color: const Color(0xFF2878D0),
                    onTap: () => context.go('/admin/orders?status=shipping'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardSummaryCard(
                    label: 'Giao thành công',
                    value: '${stats.deliveredCount}',
                    detail: 'Đơn hàng đã giao',
                    icon: Icons.task_alt_outlined,
                    color: const Color(0xFF3A9A54),
                    onTap: () => context.go('/admin/orders?status=delivered'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardSummaryCard(
                    label: 'Đã hủy',
                    value: '${stats.cancelledCount}',
                    detail: 'Đơn hàng đã hủy',
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFFC33D3D),
                    onTap: () => context.go('/admin/orders?status=cancelled'),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: DashboardSummaryCard(
                    label: 'Đã hoàn tiền',
                    value: '${stats.refundedCount}',
                    detail: currency.format(stats.refundedAmount),
                    icon: Icons.currency_exchange_outlined,
                    color: const Color(0xFF9A6A18),
                    onTap: () => context.go('/admin/orders?status=refunded'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, ratioConstraints) {
                final width = ratioConstraints.maxWidth;
                final itemWidth = width >= 720 ? (width - 14) / 2 : width;

                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _RatioCard(
                        label: 'Tỷ lệ giao hàng thành công',
                        value: stats.deliverySuccessRate,
                        detail: 'Tính trên đơn đã có kết quả giao hàng',
                        color: const Color(0xFF3A9A54),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _RatioCard(
                        label: 'Tỷ lệ hoàn đơn',
                        value: stats.returnRate,
                        detail: 'Tính trên tổng đơn đã giao và hoàn trả',
                        color: const Color(0xFFC47820),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            if (useTwoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DashboardProductList(
                      title: 'Sản phẩm sắp hết hàng',
                      subtitle: 'Sản phẩm đang kinh doanh có tồn kho dưới 5',
                      icon: Icons.inventory_2_outlined,
                      products: stats.lowStockProducts,
                      showStock: true,
                      onProductTap: (product) =>
                          _openProductForEditing(context, product),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: DashboardProductList(
                      title: 'Top 5 sản phẩm bán chạy',
                      subtitle: 'Xếp hạng theo số lượng mua trong kỳ',
                      icon: Icons.trending_up_outlined,
                      products: stats.topSellingProducts,
                      showStock: false,
                    ),
                  ),
                ],
              )
            else ...[
              DashboardProductList(
                title: 'Sản phẩm sắp hết hàng',
                subtitle: 'Sản phẩm đang kinh doanh có tồn kho dưới 5',
                icon: Icons.inventory_2_outlined,
                products: stats.lowStockProducts,
                showStock: true,
                onProductTap: (product) =>
                    _openProductForEditing(context, product),
              ),
              const SizedBox(height: 14),
              DashboardProductList(
                title: 'Top 5 sản phẩm bán chạy',
                subtitle: 'Xếp hạng theo số lượng mua trong kỳ',
                icon: Icons.trending_up_outlined,
                products: stats.topSellingProducts,
                showStock: false,
              ),
            ],
            if (viewModel.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                viewModel.errorMessage!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openProductForEditing(
    BuildContext context,
    DashboardProductStatModel product,
  ) async {
    final fullProduct = await viewModel.getProductForEditing(product.id);
    if (!context.mounted) return;

    if (fullProduct == null) {
      AppToast.showError(
        context,
        viewModel.errorMessage ?? 'Không thể tải chi tiết sản phẩm.',
      );
      return;
    }

    await context.push('/admin/products/edit', extra: fullProduct);
    await viewModel.loadStats();
  }
}

class _DashboardHeader extends StatelessWidget {
  final DashboardPeriod period;
  final DateTime referenceDate;
  final String periodText;
  final bool isLoading;
  final ValueChanged<DashboardPeriod> onPeriodChanged;
  final ValueChanged<DateTime> onReferenceDateChanged;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const _DashboardHeader({
    required this.period,
    required this.referenceDate,
    required this.periodText,
    required this.isLoading,
    required this.onPeriodChanged,
    required this.onReferenceDateChanged,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final filter = SegmentedButton<DashboardPeriod>(
          segments: DashboardPeriod.values
              .map(
                (item) => ButtonSegment(value: item, label: Text(item.label)),
              )
              .toList(),
          selected: {period},
          onSelectionChanged: isLoading
              ? null
              : (value) => onPeriodChanged(value.first),
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        );
        final periodSelector = _buildPeriodSelector(context);

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng quan kinh doanh',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Dữ liệu theo kỳ $periodText',
              style: const TextStyle(color: AppColors.detail, fontSize: 13),
            ),
          ],
        );

        if (constraints.maxWidth >= 820) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: title),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [filter, const SizedBox(height: 10), periodSelector],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const SizedBox(height: 14),
            filter,
            const SizedBox(height: 10),
            periodSelector,
          ],
        );
      },
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 2019,
      (index) => currentYear - index,
    );

    if (period == DashboardPeriod.week) {
      return OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: referenceDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(currentYear, 12, 31),
                  helpText: 'Chọn ngày thuộc tuần cần xem',
                );
                if (date != null) {
                  onReferenceDateChanged(date);
                }
              },
        icon: const Icon(Icons.calendar_month_outlined, size: 18),
        label: Text(
          'Tuần có ngày ${DateFormat('dd/MM/yyyy').format(referenceDate)}',
        ),
      );
    }

    final selectors = <Widget>[];
    if (period == DashboardPeriod.month) {
      selectors.add(
        _FilterDropdown<int>(
          value: referenceDate.month,
          items: List.generate(12, (index) => index + 1),
          labelBuilder: (month) => 'Tháng $month',
          onChanged: isLoading ? null : onMonthChanged,
        ),
      );
    }
    selectors.add(
      _FilterDropdown<int>(
        value: referenceDate.year,
        items: years,
        labelBuilder: (year) => 'Năm $year',
        onChanged: isLoading ? null : onYearChanged,
      ),
    );

    return Wrap(spacing: 10, runSpacing: 10, children: selectors);
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T>? onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.65)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          onChanged: onChanged == null
              ? null
              : (newValue) {
                  if (newValue != null) onChanged!(newValue);
                },
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _RatioCard extends StatelessWidget {
  final String label;
  final double value;
  final String detail;
  final Color color;

  const _RatioCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: color,
              backgroundColor: AppColors.surface,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            detail,
            style: const TextStyle(color: AppColors.detail, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
