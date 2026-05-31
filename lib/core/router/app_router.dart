import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/login/auth/view/login_view.dart';
import '../../features/login/auth/view/register_view.dart';
import '../../features/login/auth/viewmodel/auth_viewmodel.dart';
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
import '../../features/customer/checkout/view/checkout_view.dart';
import '../../features/customer/catalog/view/customer_home_view.dart';
import '../../features/customer/catalog/view/customer_product_detail_view.dart';
import '../../features/customer/layout/customer_layout.dart';
import '../../features/customer/orders/view/customer_order_list_view.dart';
import '../../features/customer/orders/view/customer_order_detail_view.dart';
import '../../features/customer/profile/view/customer_profile_view.dart';
import '../../features/login/profile/view/profile_view.dart';
import '../../features/login/profile/view/change_password_view.dart';
import '../../features/admin/orders/view/admin_order_list_view.dart';
import '../../features/admin/orders/view/order_detail_view.dart';
import '../../data/models/order_model.dart';
import '../../features/admin/users/view/admin_user_list_view.dart';
import '../../features/admin/users/view/admin_user_form_view.dart';
import '../../data/models/profiles_model.dart';
import '../../features/admin/dashboard/view/admin_dashboard_view.dart';

class AppRouter {
  static late final GoRouter router;

  static void init(AuthViewModel authViewModel) {
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: authViewModel,
      redirect: (context, state) {
        final loggedIn = authViewModel.isAuthenticated;
        final loggingIn = state.matchedLocation == '/login';
        final registering = state.matchedLocation == '/register';

        if (!loggedIn && !loggingIn && !registering) {
          return '/login';
        }

        if (loggedIn && (loggingIn || registering)) {
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

        final profile = authViewModel.currentProfile;
        if ((state.matchedLocation.startsWith('/admin/users') ||
                state.matchedLocation.startsWith('/admin/dashboard')) &&
            profile?.isAdmin != true) {
          return profile?.isCustomer == true ? '/shop' : '/admin/products';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginView()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterView(),
        ),
        // ShellRoute for Admin pages
        ShellRoute(
          builder: (context, state, child) => MainLayout(child: child),
          routes: [
            GoRoute(
              path: '/admin/dashboard',
              builder: (context, state) => const AdminDashboardView(),
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
              builder: (context, state) => AdminOrderListView(
                initialStatus: state.uri.queryParameters['status'],
              ),
            ),
            GoRoute(
              path: '/admin/orders/detail',
              redirect: (context, state) =>
                  state.extra is OrderModel ? null : '/admin/orders',
              builder: (context, state) {
                final order = state.extra as OrderModel;
                return AdminOrderDetailView(order: order);
              },
            ),
            GoRoute(
              path: '/admin/users',
              builder: (context, state) => const AdminUserListView(),
            ),
            GoRoute(
              path: '/admin/users/new',
              builder: (context, state) => const AdminUserFormView(),
            ),
            GoRoute(
              path: '/admin/users/edit',
              builder: (context, state) {
                final user = state.extra as ProfileModel?;
                return AdminUserFormView(userToEdit: user);
              },
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileView(),
            ),
            GoRoute(
              path: '/profile/change-password',
              builder: (context, state) => const ChangePasswordView(),
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
              path: '/checkout',
              builder: (context, state) => const CheckoutView(),
            ),
            GoRoute(
              path: '/shop/orders',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CustomerOrderListView()),
            ),
            GoRoute(
              path: '/shop/orders/detail',
              redirect: (context, state) =>
                  state.extra is OrderModel ? null : '/shop/orders',
              builder: (context, state) {
                final order = state.extra as OrderModel;
                return CustomerOrderDetailView(order: order);
              },
            ),
            GoRoute(
              path: '/shop/profile',
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: CustomerProfileView()),
            ),
            GoRoute(
              path: '/shop/profile/change-password',
              builder: (context, state) => const ChangePasswordView(),
            ),
          ],
        ),
      ],
    );
  }
}
