import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../user/auth/viewmodel/auth_viewmodel.dart';
import '../cart/viewmodel/customer_cart_view_model.dart';

class CustomerLayout extends StatelessWidget {
  final Widget child;

  const CustomerLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return AnimatedBuilder(
      animation: router.routerDelegate,
      builder: (context, childWidget) {
        final path = router.routeInformationProvider.value.uri.path;

        if (isDesktop) {
          return Scaffold(
            body: Row(
              children: [
                Container(
                  width: 230,
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 36),
                      const Text(
                        'HAMSA STORE',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 28),
                      Expanded(child: _CustomerNavigation(currentPath: path)),
                      const _LogoutButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _DesktopTopBar(path: path),
                      Expanded(child: childWidget ?? const SizedBox.shrink()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(_titleForPath(path)),
            centerTitle: true,
            leading: (path.startsWith('/shop/products/') || path == '/checkout' || path == '/shop/orders/detail')
                ? IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(height: 1),
            ),
          ),
          body: childWidget ?? const SizedBox.shrink(),
          bottomNavigationBar: _CustomerBottomNavigation(currentPath: path),
        );
      },
      child: child,
    );
  }
}

class _DesktopTopBar extends StatelessWidget {
  final String path;

  const _DesktopTopBar({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (path.startsWith('/shop/products/') || path == '/checkout' || path == '/shop/orders/detail') ...[
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            _titleForPath(path),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CustomerNavigation extends StatelessWidget {
  final String currentPath;

  const _CustomerNavigation({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: _items
          .map(
            (item) => ListTile(
              selected: _isSelected(item.route, currentPath),
              selectedTileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: Icon(item.icon),
              title: Text(item.label),
              trailing: item.route == '/cart' ? const _CartBadge() : null,
              onTap: () => context.go(item.route),
            ),
          )
          .toList(),
    );
  }
}

class _CustomerBottomNavigation extends StatelessWidget {
  final String currentPath;

  const _CustomerBottomNavigation({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final index = _items.indexWhere(
      (item) => _isSelected(item.route, currentPath),
    );
    final cartItemCount = context.watch<CustomerCartViewModel>().itemCount;
    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (index) => context.go(_items[index].route),
      destinations: _items
          .map(
            (item) => NavigationDestination(
              icon: item.route == '/cart'
                  ? Badge.count(
                      count: cartItemCount,
                      isLabelVisible: cartItemCount > 0,
                      child: Icon(item.icon),
                    )
                  : Icon(item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class _CartBadge extends StatelessWidget {
  const _CartBadge();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CustomerCartViewModel>().itemCount;
    if (count == 0) return const SizedBox.shrink();
    return Badge.count(count: count);
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Đăng xuất'),
        onTap: () async {
          await context.read<AuthViewModel>().logout();
          if (context.mounted) context.go('/login');
        },
      ),
    );
  }
}

class _NavigationItem {
  final String route;
  final String label;
  final IconData icon;

  const _NavigationItem(this.route, this.label, this.icon);
}

const _items = [
  _NavigationItem('/shop', 'Trang chủ', Icons.home_outlined),
  _NavigationItem('/cart', 'Giỏ hàng', Icons.shopping_cart_outlined),
  _NavigationItem('/shop/orders', 'Đơn hàng', Icons.receipt_long_outlined),
  _NavigationItem('/shop/profile', 'Cá nhân', Icons.person_outline),
];

bool _isSelected(String route, String currentPath) {
  if (route == '/shop') return currentPath == '/shop';
  if (route == '/cart' && currentPath == '/checkout') return true;
  return currentPath.startsWith(route);
}

String _titleForPath(String path) {
  if (path.startsWith('/shop/products/')) return 'Chi tiết sản phẩm';
  if (path == '/cart') return 'Giỏ hàng';
  if (path == '/checkout') return 'Thanh toán đơn hàng';
  if (path == '/shop/orders') return 'Đơn hàng';
  if (path == '/shop/orders/detail') return 'Chi tiết đơn hàng';
  if (path == '/shop/profile') return 'Cá nhân';
  return 'Hamsa Store';
}
