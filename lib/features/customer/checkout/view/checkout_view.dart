import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../login/auth/viewmodel/auth_viewmodel.dart';
import '../viewmodel/checkout_view_model.dart';
import '../../cart/viewmodel/customer_cart_view_model.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthViewModel>().currentProfile;
    final checkoutVM = context.read<CheckoutViewModel>();
    if (profile != null) {
      checkoutVM.initFromProfile(profile);
    }
    _nameController = TextEditingController(text: checkoutVM.customerName);
    _phoneController = TextEditingController(text: checkoutVM.customerPhone);
    _addressController = TextEditingController(
      text: checkoutVM.customerAddress,
    );
    _noteController = TextEditingController(text: checkoutVM.note);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer3<AuthViewModel, CustomerCartViewModel, CheckoutViewModel>(
        builder: (context, authVM, cartVM, checkoutVM, child) {
          final profile = authVM.currentProfile;
          if (profile == null) {
            return const Center(child: Text('Vui lòng đăng nhập lại.'));
          }

          final selectedEntries = cartVM.selectedEntries;
          if (selectedEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shopping_cart_checkout,
                    size: 64,
                    color: AppColors.detail,
                  ),
                  const SizedBox(height: 12),
                  const Text('Không có sản phẩm nào được chọn thanh toán.'),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Quay lại giỏ hàng',
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            );
          }

          final totalAmount = cartVM.selectedTotalAmount;
          final totalQty = selectedEntries.fold<int>(
            0,
            (sum, e) => sum + e.quantity,
          );

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: 120,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;

                    final contentWidgets = [
                      // 1. Tóm tắt sản phẩm
                      _SectionContainer(
                        title: 'Sản phẩm thanh toán ($totalQty)',
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: selectedEntries.length,
                          separatorBuilder: (_, _) => const Divider(height: 20),
                          itemBuilder: (context, index) {
                            final entry = selectedEntries[index];
                            return Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AppNetworkImage(
                                    imageUrl: entry.product.imageUrls.isEmpty
                                        ? ''
                                        : entry.product.imageUrls.first,
                                    width: 60,
                                    height: 60,
                                    borderRadius: 8,
                                    fit: BoxFit.cover,
                                    placeholder: Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.surface,
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: AppColors.detail,
                                      ),
                                    ),
                                    errorWidget: Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.surface,
                                      child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        color: AppColors.detail,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.product.displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Số lượng: ${entry.quantity}',
                                        style: const TextStyle(
                                          color: AppColors.detail,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  currencyFormat.format(entry.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // 2. Thông tin giao hàng
                      _SectionContainer(
                        title: 'Thông tin giao hàng',
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                label: 'Họ và tên người nhận *',
                                controller: _nameController,
                                hintText: 'Nhập họ và tên...',
                                onChanged: checkoutVM.setCustomerName,
                                showBorder: true,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Số điện thoại *',
                                controller: _phoneController,
                                hintText: 'Nhập số điện thoại...',
                                keyboardType: TextInputType.phone,
                                onChanged: checkoutVM.setCustomerPhone,
                                showBorder: true,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Địa chỉ nhận hàng *',
                                controller: _addressController,
                                hintText:
                                    'Nhập địa chỉ nhà, tên đường, phường/xã, quận/huyện...',
                                onChanged: checkoutVM.setCustomerAddress,
                                showBorder: true,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Ghi chú (Tùy chọn)',
                                controller: _noteController,
                                hintText:
                                    'Lưu ý cho shipper, thời gian nhận hàng...',
                                maxLines: 3,
                                onChanged: checkoutVM.setNote,
                                showBorder: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. Phương thức thanh toán
                      _SectionContainer(
                        title: 'Phương thức thanh toán',
                        child: RadioGroup<String>(
                          groupValue: checkoutVM.paymentMethod,
                          onChanged: (value) {
                            if (value != null) {
                              checkoutVM.setPaymentMethod(value);
                            }
                          },
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                value: 'wallet',
                                activeColor: AppColors.primary,
                                title: const Text(
                                  'Ví điện tử HamsaPay',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: checkoutVM.isLoadingWallet
                                    ? const Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Số dư khả dụng: ${currencyFormat.format(checkoutVM.walletBalance)}',
                                        style: TextStyle(
                                          color:
                                              checkoutVM.walletBalance <
                                                  totalAmount
                                              ? AppColors.error
                                              : AppColors.detail,
                                          fontWeight:
                                              checkoutVM.walletBalance <
                                                  totalAmount
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                              ),
                              if (checkoutVM.paymentMethod == 'wallet' &&
                                  !checkoutVM.isLoadingWallet &&
                                  checkoutVM.walletBalance < totalAmount)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 24,
                                    right: 16,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    'Số dư ví không đủ để thanh toán. Vui lòng nạp thêm tiền hoặc chọn phương thức thanh toán COD.',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              const Divider(height: 1),
                              RadioListTile<String>(
                                value: 'cash',
                                activeColor: AppColors.primary,
                                title: const Text(
                                  'Thanh toán sau khi nhận hàng (COD)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: const Text(
                                  'Thanh toán bằng tiền mặt khi shipper giao hàng.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ];

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: Column(
                              children: [
                                contentWidgets[0], // Sản phẩm
                                const SizedBox(height: 20),
                                contentWidgets[1], // Giao hàng
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 4,
                            child: contentWidgets[2], // Thanh toán
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        contentWidgets[0],
                        const SizedBox(height: 20),
                        contentWidgets[1],
                        const SizedBox(height: 20),
                        contentWidgets[2],
                      ],
                    );
                  },
                ),
              ),

              // Bottom Action Bar
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                    border: const Border(
                      top: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final buttonWidth = constraints.maxWidth < 520
                            ? constraints.maxWidth * 0.48
                            : 220.0;

                        return Row(
                          children: [
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TỔNG THANH TOÁN',
                                    style: TextStyle(
                                      color: AppColors.detail,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        currencyFormat.format(totalAmount),
                                        maxLines: 1,
                                        style: const TextStyle(
                                          color: AppColors.error,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: buttonWidth,
                              child: AppButton(
                                text: 'Xác nhận đặt hàng',
                                isLoading: checkoutVM.isLoading,
                                onPressed:
                                    (checkoutVM.paymentMethod == 'wallet' &&
                                        checkoutVM.walletBalance < totalAmount)
                                    ? null
                                    : () => _onOrderSubmit(
                                        context,
                                        checkoutVM,
                                        profile.id,
                                        selectedEntries,
                                        cartVM,
                                      ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              if (checkoutVM.isLoading)
                const Opacity(
                  opacity: 0.3,
                  child: ModalBarrier(dismissible: false, color: Colors.black),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onOrderSubmit(
    BuildContext context,
    CheckoutViewModel checkoutVM,
    String userId,
    List<CustomerCartEntry> selectedEntries,
    CustomerCartViewModel cartVM,
  ) async {
    // Copy controller values to VM
    checkoutVM.setCustomerName(_nameController.text);
    checkoutVM.setCustomerPhone(_phoneController.text);
    checkoutVM.setCustomerAddress(_addressController.text);
    checkoutVM.setNote(_noteController.text);

    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    String? walletPassword;
    if (checkoutVM.paymentMethod == 'wallet') {
      walletPassword = await _showWalletPasswordDialog(context);
      if (!context.mounted || walletPassword == null) return;
    }

    final success = await checkoutVM.submitOrder(
      userId: userId,
      selectedEntries: selectedEntries,
      walletPassword: walletPassword,
    );

    if (!context.mounted) return;

    if (success) {
      // Reload giỏ hàng để xóa những items đã thanh toán
      await cartVM.loadCart();
      if (!context.mounted) return;

      // Hiển thị thông báo thành công dialog
      _showSuccessDialog(context);
    } else if (checkoutVM.errorMessage != null) {
      AppToast.showError(context, checkoutVM.errorMessage!);
    }
  }

  Future<String?> _showWalletPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    String? errorText;

    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Xác nhận thanh toán HamsaPay'),
              content: TextField(
                controller: passwordController,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu tài khoản',
                  hintText: 'Nhập mật khẩu để tiếp tục',
                  errorText: errorText,
                ),
                onSubmitted: (_) {
                  final value = passwordController.text;
                  if (value.isEmpty) {
                    setDialogState(() {
                      errorText = 'Vui lòng nhập mật khẩu.';
                    });
                    return;
                  }
                  Navigator.of(dialogContext).pop(value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = passwordController.text;
                    if (value.isEmpty) {
                      setDialogState(() {
                        errorText = 'Vui lòng nhập mật khẩu.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    return password;
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF0F8644), size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đặt hàng thành công',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Đơn hàng của bạn đã được tiếp nhận và đang chờ xác nhận.',
            style: TextStyle(fontSize: 15),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _closeDialogAndGo(
                      context,
                      dialogContext,
                      '/shop/orders',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Đi đến đơn hàng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _closeDialogAndGo(context, dialogContext, '/shop'),
                  child: const Text(
                    'Tiếp tục mua sắm',
                    style: TextStyle(
                      color: AppColors.detail,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _closeDialogAndGo(
    BuildContext context,
    BuildContext dialogContext,
    String location,
  ) {
    Navigator.of(dialogContext).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.go(location);
      }
    });
  }
}

class _SectionContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
