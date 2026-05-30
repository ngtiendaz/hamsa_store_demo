import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/user/auth/view/login_view.dart';
import '../../features/user/auth/viewmodel/auth_viewmodel.dart';
import '../../features/admin/products/view/product_list_view.dart';
import '../../features/admin/products/view/product_form_view.dart';
import '../../features/admin/categories/view/category_list_view.dart';
import '../../features/admin/categories/view/category_form_view.dart';
import '../../features/admin/brands/view/brand_list_view.dart';
import '../../features/admin/brands/view/brand_form_view.dart';
import '../layout/main_layout.dart';
import '../../../data/models/products_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/brand_model.dart';

class AppRouter {
  static late final GoRouter router;

  static void init(AuthViewModel authViewModel) {
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final loggedIn = authViewModel.isAuthenticated;
        final loggingIn = state.matchedLocation == '/login';

        if (!loggedIn && !loggingIn) {
          return '/login';
        }
        
        if (loggedIn && loggingIn) {
          final profile = authViewModel.currentProfile;
          if (profile != null) {
            if (profile.isAdmin || profile.isEmployee) {
              return '/admin/dashboard';
            } else {
              return '/shop';
            }
          }
        }

        if (state.matchedLocation == '/admin') {
          return '/admin/dashboard';
        }
        
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginView(),
        ),
        // ShellRoute for Admin pages
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/admin/dashboard',
              builder: (context, state) => const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: Text('Trang Bảng Điều Khiển (Dashboard Mockup)')),
              ),
            ),
            GoRoute(
              path: '/admin/products',
              builder: (context, state) => const ProductListView(),
            ),
            GoRoute(
              path: '/admin/products/new',
              builder: (context, state) => const ProductFormView(),
            ),
            GoRoute(
              path: '/admin/products/edit',
              builder: (context, state) {
                final product = state.extra as ProductModel?;
                return ProductFormView(productToEdit: product);
              },
            ),
            GoRoute(
              path: '/admin/categories',
              builder: (context, state) => const CategoryListView(),
            ),
            GoRoute(
              path: '/admin/categories/new',
              builder: (context, state) => const CategoryFormView(),
            ),
            GoRoute(
              path: '/admin/categories/edit',
              builder: (context, state) {
                final category = state.extra as CategoryModel?;
                return CategoryFormView(categoryToEdit: category);
              },
            ),
            GoRoute(
              path: '/admin/brands',
              builder: (context, state) => const BrandListView(),
            ),
            GoRoute(
              path: '/admin/brands/new',
              builder: (context, state) => const BrandFormView(),
            ),
            GoRoute(
              path: '/admin/brands/edit',
              builder: (context, state) {
                final brand = state.extra as BrandModel?;
                return BrandFormView(brandToEdit: brand);
              },
            ),
            GoRoute(
              path: '/admin/orders',
              builder: (context, state) => const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: Text('Quản lý đơn hàng (Mockup)')),
              ),
            ),
            GoRoute(
              path: '/admin/users',
              builder: (context, state) => const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: Text('Quản lý người dùng (Mockup)')),
              ),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: Text('Thông tin cá nhân (Mockup)')),
              ),
            ),
          ],
        ),
        // Shop route for Customer
        GoRoute(
          path: '/shop',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              title: const Text('Hamsa Store'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await authViewModel.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
            body: const Center(
              child: Text('Trang Khách hàng (User/Customer)'),
            ),
          ),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Giỏ hàng')),
            body: const Center(child: Text('Trang Giỏ hàng (Mockup)')),
          ),
        ),
      ],
    );
  }
}
