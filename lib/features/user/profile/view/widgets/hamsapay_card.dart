import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_toast.dart';
import '../../viewmodel/profile_viewmodel.dart';
import 'wallet_history_dialog.dart';

class HamsapayCard extends StatelessWidget {
  final ProfileViewModel viewModel;

  const HamsapayCard({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final balance = viewModel.wallet?.balance ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3C72), // Blue gradient
            Color(0xFF2A5298),
            Color(0xFF122240),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3C72).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Decorative circles
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'HamsaPay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.white, size: 24),
                      tooltip: 'Lịch sử giao dịch',
                      onPressed: () => _showHistory(context),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'SỐ DƯ KHẢ DỤNG',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                viewModel.isLoadingWallet
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      )
                    : Text(
                        currencyFormat.format(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardActionButton(
                        context: context,
                        label: 'Nạp tiền',
                        icon: Icons.add_circle_outline,
                        onPressed: () => _showTransactionDialog(context, isDeposit: true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCardActionButton(
                        context: context,
                        label: 'Rút tiền',
                        icon: Icons.remove_circle_outline,
                        onPressed: () => _showTransactionDialog(context, isDeposit: false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WalletHistoryDialog(viewModel: viewModel),
    );
  }

  void _showTransactionDialog(BuildContext context, {required bool isDeposit}) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDeposit ? 'Nạp tiền HamsaPay' : 'Rút tiền HamsaPay'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isDeposit
                    ? 'Nhập số tiền bạn muốn nạp vào ví điện tử.'
                    : 'Nhập số tiền bạn muốn rút khỏi ví điện tử.',
                style: const TextStyle(color: AppColors.detail, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nhập số tiền (đ)...',
                  suffixText: '₫',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền.';
                  }
                  final amount = double.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Số tiền phải là số lớn hơn 0.';
                  }
                  if (!isDeposit) {
                    final balance = viewModel.wallet?.balance ?? 0.0;
                    if (amount > balance) {
                      return 'Số dư khả dụng không đủ.';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppColors.detail)),
          ),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final amount = double.parse(controller.text.trim());
              Navigator.of(ctx).pop();

              final success = isDeposit
                  ? await viewModel.deposit(amount)
                  : await viewModel.withdraw(amount);

              if (context.mounted) {
                if (success) {
                  AppToast.showSuccess(
                    context,
                    isDeposit
                        ? 'Đã nạp ${NumberFormat.currency(locale: "vi_VN", symbol: "₫").format(amount)} vào ví thành công!'
                        : 'Đã rút ${NumberFormat.currency(locale: "vi_VN", symbol: "₫").format(amount)} khỏi ví thành công!',
                  );
                } else if (viewModel.errorMessage != null) {
                  AppToast.showError(context, viewModel.errorMessage!);
                }
              }
            },
            child: Text(
              isDeposit ? 'Nạp tiền' : 'Rút tiền',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
