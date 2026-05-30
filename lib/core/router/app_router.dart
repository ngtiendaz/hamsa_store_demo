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
import '../../features/customer/cart/view/customer_cart_view.dart';
import '../../features/customer/catalog/view/customer_home_view.dart';
import '../../features/customer/catalog/view/customer_product_detail_view.dart';
import '../../features/customer/layout/customer_layout.dart';
import '../../features/customer/orders/view/customer_order_list_view.dart';
import '../../features/customer/profile/view/customer_profile_view.dart';
import '../../features/user/profile/view/profile_view.dart';

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
        GoRoute(path: '/login', builder: (context, state) => const LoginView()),
        // ShellRoute for Admin pages
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/admin/dashboard',
              builder: (context, state) => const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Text('Trang Bảng Điều Khiển (Dashboard Mockup)'),
                ),
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
              builder: (context, state) => const ProfileView(),
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) => CustomerLayout(child: child),
          routes: [
            GoRoute(
              path: '/shop',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CustomerHomeView()),
            ),
            GoRoute(
              path: '/shop/products/:id',
              pageBuilder: (context, state) => CustomTransitionPage(
                transitionDuration: const Duration(milliseconds: 180),
                reverseTransitionDuration: const Duration(milliseconds: 140),
                child: CustomerProductDetailView(
                  productId: state.pathParameters['id']!,
                ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
              ),
            ),
            GoRoute(
              path: '/cart',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CustomerCartView()),
            ),
            GoRoute(
              path: '/shop/orders',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CustomerOrderListView()),
            ),
            GoRoute(
              path: '/shop/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CustomerProfileView()),
            ),
          ],
        ),
      ],
    );
  }
}
