import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/wallet_transaction_model.dart';
import '../../viewmodel/profile_viewmodel.dart';

class WalletHistoryDialog extends StatelessWidget {
  final ProfileViewModel viewModel;

  const WalletHistoryDialog({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lịch sử giao dịch',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: viewModel.transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có giao dịch nào được ghi nhận.',
                          style: TextStyle(
                            color: AppColors.detail,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: viewModel.transactions.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, index) {
                          final tx = viewModel.transactions[index];
                          final isAdd = tx.isAdd;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTransactionIcon(tx.type),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.type.label,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (tx.note != null &&
                                          tx.note!.isNotEmpty) ...[
                                        Text(
                                          tx.note!,
                                          style: const TextStyle(
                                            color: AppColors.detail,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                      ],
                                      Text(
                                        dateFormat.format(tx.createdAt),
                                        style: const TextStyle(
                                          color: AppColors.detail,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${isAdd ? '+' : '-'}${currencyFormat.format(tx.amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isAdd
                                        ? const Color(0xFF0F8644)
                                        : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(WalletTransactionType type) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (type) {
      case WalletTransactionType.deposit:
        icon = Icons.add;
        color = const Color(0xFF0F8644);
        bgColor = const Color(0xFFE2FBE9);
        break;
      case WalletTransactionType.payment:
        icon = Icons.shopping_bag_outlined;
        color = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.1);
        break;
      case WalletTransactionType.refund:
        icon = Icons.keyboard_return;
        color = Colors.orange;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case WalletTransactionType.manualAdjustment:
        icon = Icons.remove;
        color = AppColors.error;
        bgColor = const Color(0xFFFEE2E2);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
