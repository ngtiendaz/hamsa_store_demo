import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../features/user/auth/viewmodel/auth_viewmodel.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isDesktop = mediaQuery.size.width > 900;
    final authViewModel = Provider.of<AuthViewModel>(context);
    final profile = authViewModel.currentProfile;

    final menuItems = _getMenuItems(profile?.role ?? 'customer');
    final router = GoRouter.of(context);

    return AnimatedBuilder(
      animation: router.routerDelegate,
      builder: (context, childWidget) {
        final currentRoute = router.routeInformationProvider.value.uri.path;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                // Sidebar
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: AppColors.surface, width: 1.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'HAMSA STORE',
                        style: AppTextStyles.headlineMd.copyWith(
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Expanded(
                        child: ListView.builder(
                          itemCount: menuItems.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final item = menuItems[index];
                            final isSelected = currentRoute.startsWith(
                              item.route,
                            );

                            return _buildMenuItemTile(
                              context: context,
                              item: item,
                              isSelected: isSelected,
                            );
                          },
                        ),
                      ),
                      // User Profile Box
                      _buildProfileBox(context, profile, authViewModel),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Bar
                      Container(
                        height: 70,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.surface,
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (currentRoute == '/admin/products/new' ||
                                currentRoute == '/admin/products/edit' ||
                                currentRoute == '/admin/categories/new' ||
                                currentRoute == '/admin/categories/edit' ||
                                currentRoute == '/admin/brands/new' ||
                                currentRoute == '/admin/brands/edit' ||
                                currentRoute == '/admin/orders/detail' ||
                                currentRoute == '/admin/users/new' ||
                                currentRoute == '/admin/users/edit' ||
                                currentRoute == '/profile/change-password') ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    if (currentRoute.contains('/products')) {
                                      context.go('/admin/products');
                                    } else if (currentRoute.contains(
                                      '/categories',
                                    )) {
                                      context.go('/admin/categories');
                                    } else if (currentRoute.contains(
                                      '/brands',
                                    )) {
                                      context.go('/admin/brands');
                                    } else if (currentRoute.contains(
                                      '/users',
                                    )) {
                                      context.go('/admin/users');
                                    } else {
                                      context.go('/profile');
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _getPageTitle(currentRoute),
                              style: AppTextStyles.headlineMd,
                            ),
                          ],
                        ),
                      ),
                      // Main Body
                      Expanded(child: childWidget ?? const SizedBox.shrink()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile layout
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading:
                (currentRoute == '/admin/products/new' ||
                    currentRoute == '/admin/products/edit' ||
                    currentRoute == '/admin/categories/new' ||
                    currentRoute == '/admin/categories/edit' ||
                    currentRoute == '/admin/brands/new' ||
                    currentRoute == '/admin/brands/edit' ||
                    currentRoute == '/admin/orders/detail' ||
                    currentRoute == '/admin/users/new' ||
                    currentRoute == '/admin/users/edit' ||
                    currentRoute == '/profile/change-password')
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        if (currentRoute.contains('/products')) {
                          context.go('/admin/products');
                        } else if (currentRoute.contains('/categories')) {
                          context.go('/admin/categories');
                        } else if (currentRoute.contains('/brands')) {
                          context.go('/admin/brands');
                        } else if (currentRoute.contains('/users')) {
                          context.go('/admin/users');
                        } else {
                          context.go('/profile');
                        }
                      }
                    },
                  )
                : null,
            title: Text(
              _getPageTitle(currentRoute),
              style: AppTextStyles.headlineMd.copyWith(fontSize: 20),
            ),
            backgroundColor: AppColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.primary),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.surface, height: 1),
            ),
          ),
          drawer: Drawer(
            backgroundColor: AppColors.background,
            child: Column(
              children: [
                const SizedBox(height: 60),
                Text(
                  'HAMSA STORE',
                  style: AppTextStyles.headlineMd.copyWith(letterSpacing: -1),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView.builder(
                    itemCount: menuItems.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isSelected = currentRoute.startsWith(item.route);

                      return _buildMenuItemTile(
                        context: context,
                        item: item,
                        isSelected: isSelected,
                        onTap: () => Navigator.pop(context),
                      );
                    },
                  ),
                ),
                _buildProfileBox(context, profile, authViewModel),
                const SizedBox(height: 20),
              ],
            ),
          ),
          body: childWidget ?? const SizedBox.shrink(),
        );
      },
      child: child,
    );
  }

  Widget _buildMenuItemTile({
    required BuildContext context,
    required _MenuItem item,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          item.icon,
          color: isSelected ? AppColors.primary : AppColors.detail,
          size: 20,
        ),
        title: Text(
          item.title,
          style: AppTextStyles.bodyMd.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.onSurface,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (onTap != null) onTap();
          context.go(item.route);
        },
      ),
    );
  }

  Widget _buildProfileBox(
    BuildContext context,
    dynamic profile,
    AuthViewModel authViewModel,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 18,
            child: Text(
              (profile?.name ?? 'U').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile?.name ?? 'Người dùng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  profile?.role == 'admin'
                      ? 'Quản trị viên'
                      : (profile?.role == 'employee'
                            ? 'Nhân viên'
                            : 'Khách hàng'),
                  style: const TextStyle(color: AppColors.detail, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18, color: AppColors.error),
            onPressed: () async {
              await authViewModel.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  List<_MenuItem> _getMenuItems(String role) {
    if (role == 'admin') {
      return [
        _MenuItem('Dashboard', '/admin/dashboard', Icons.dashboard_outlined),
        _MenuItem('Sản phẩm', '/admin/products', Icons.shopping_bag_outlined),
        _MenuItem('Danh mục', '/admin/categories', Icons.category_outlined),
        _MenuItem('Nhãn hàng', '/admin/brands', Icons.stars_outlined),
        _MenuItem('Đơn hàng', '/admin/orders', Icons.receipt_long_outlined),
        _MenuItem('Người dùng', '/admin/users', Icons.people_outline),
        _MenuItem('Trang cá nhân', '/profile', Icons.person_outline),
      ];
    } else if (role == 'employee') {
      return [
        _MenuItem('Sản phẩm', '/admin/products', Icons.shopping_bag_outlined),
        _MenuItem('Đơn hàng', '/admin/orders', Icons.receipt_long_outlined),
        _MenuItem('Trang cá nhân', '/profile', Icons.person_outline),
      ];
    } else {
      return [
        _MenuItem('Sản phẩm', '/shop', Icons.shopping_bag_outlined),
        _MenuItem('Giỏ hàng', '/cart', Icons.shopping_cart_outlined),
        _MenuItem('Trang cá nhân', '/profile', Icons.person_outline),
      ];
    }
  }

  String _getPageTitle(String route) {
    if (route.startsWith('/admin/dashboard')) return 'Dashboard';
    if (route.startsWith('/admin/products/new')) return 'Thêm sản phẩm';
    if (route.startsWith('/admin/products/edit')) return 'Chi tiết sản phẩm';
    if (route.startsWith('/admin/products')) return 'Quản lý sản phẩm';
    if (route.startsWith('/admin/categories/new')) return 'Thêm danh mục';
    if (route.startsWith('/admin/categories/edit')) return 'Chi tiết danh mục';
    if (route.startsWith('/admin/categories')) return 'Quản lý danh mục';
    if (route.startsWith('/admin/brands/new')) return 'Thêm nhãn hàng';
    if (route.startsWith('/admin/brands/edit')) return 'Chi tiết nhãn hàng';
    if (route.startsWith('/admin/brands')) return 'Quản lý nhãn hàng';
    if (route.startsWith('/admin/orders/detail')) return 'Chi tiết đơn hàng';
    if (route.startsWith('/admin/orders')) return 'Quản lý đơn hàng';
    if (route.startsWith('/admin/users/new')) return 'Thêm người dùng';
    if (route.startsWith('/admin/users/edit')) return 'Chi tiết người dùng';
    if (route.startsWith('/admin/users')) return 'Quản lý người dùng';
    if (route.startsWith('/profile/change-password')) return 'Đổi mật khẩu';
    if (route.startsWith('/profile')) return 'Trang cá nhân';
    return 'Hamsa Store';
  }
}

class _MenuItem {
  final String title;
  final String route;
  final IconData icon;

  _MenuItem(this.title, this.route, this.icon);
}
