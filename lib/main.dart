import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'features/login/auth/viewmodel/auth_viewmodel.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/customer/cart/viewmodel/customer_cart_view_model.dart';
import 'features/customer/checkout/viewmodel/checkout_view_model.dart';
import 'features/customer/orders/viewmodel/customer_order_list_view_model.dart';
import 'features/admin/orders/viewmodel/admin_order_list_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo kết nối Supabase
  await SupabaseService.initialize();

  // Khởi tạo AuthViewModel và AppRouter trước khi chạy app để hỗ trợ Session Persistence
  final authViewModel = AuthViewModel();
  AppRouter.init(authViewModel);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProxyProvider<AuthViewModel, CustomerCartViewModel>(
          create: (_) => CustomerCartViewModel(),
          update: (context, authViewModel, cartViewModel) {
            final viewModel = cartViewModel ?? CustomerCartViewModel();
            viewModel.syncForUser(authViewModel.currentProfile?.id);
            return viewModel;
          },
        ),
        ChangeNotifierProvider(create: (_) => CheckoutViewModel()),
        ChangeNotifierProvider(create: (_) => CustomerOrderListViewModel()),
        ChangeNotifierProvider(create: (_) => AdminOrderListViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hamsa Store',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
