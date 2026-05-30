import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../data/models/profiles_model.dart';
import '../viewmodel/admin_user_list_view_model.dart';

class AdminUserListView extends StatelessWidget {
  const AdminUserListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminUserListViewModel(),
      child: Consumer<AdminUserListViewModel>(
        builder: (context, viewModel, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              return Scaffold(
                backgroundColor: AppColors.background,
                body: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _UserFilters(viewModel: viewModel, isDesktop: isDesktop),
                      const SizedBox(height: 24),
                      Expanded(
                        child: viewModel.isLoading
                            ? const AppLoading()
                            : viewModel.users.isEmpty
                            ? const _EmptyUsers()
                            : isDesktop
                            ? _UserTable(viewModel: viewModel)
                            : _UserCardList(viewModel: viewModel),
                      ),
                      if (viewModel.users.isNotEmpty)
                        _PaginationFooter(viewModel: viewModel),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UserFilters extends StatelessWidget {
  final AdminUserListViewModel viewModel;
  final bool isDesktop;

  const _UserFilters({required this.viewModel, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final searchField = SizedBox(
      width: isDesktop ? 300 : double.infinity,
      child: TextField(
        onChanged: viewModel.setKeyword,
        decoration: InputDecoration(
          hintText: 'Tìm theo tên hoặc email...',
          prefixIcon: const Icon(Icons.search, color: AppColors.detail),
          fillColor: AppColors.surface,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
    final roleFilter = _FilterBox(
      width: isDesktop ? 180 : double.infinity,
      child: DropdownButton<String?>(
        value: viewModel.selectedRole,
        isExpanded: true,
        items: const [
          DropdownMenuItem(value: null, child: Text('Tất cả vai trò')),
          DropdownMenuItem(value: 'employee', child: Text('Nhân viên')),
          DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
        ],
        onChanged: viewModel.selectRole,
      ),
    );
    final statusFilter = _FilterBox(
      width: isDesktop ? 180 : double.infinity,
      child: DropdownButton<bool?>(
        value: viewModel.selectedIsActive,
        isExpanded: true,
        items: const [
          DropdownMenuItem(value: null, child: Text('Tất cả trạng thái')),
          DropdownMenuItem(value: true, child: Text('Đang hoạt động')),
          DropdownMenuItem(value: false, child: Text('Đã vô hiệu hóa')),
        ],
        onChanged: viewModel.selectIsActive,
      ),
    );
    final addButton = AppButton(
      text: 'Thêm nhân viên',
      onPressed: () async {
        final result = await context.push('/admin/users/new');
        if (result == true) viewModel.loadUsers(refresh: true);
      },
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [searchField, roleFilter, statusFilter],
            ),
          ),
          const SizedBox(width: 16),
          addButton,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchField,
        const SizedBox(height: 12),
        roleFilter,
        const SizedBox(height: 12),
        statusFilter,
        const SizedBox(height: 16),
        addButton,
      ],
    );
  }
}

class _FilterBox extends StatelessWidget {
  final double width;
  final Widget child;

  const _FilterBox({required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(child: child),
    );
  }
}

class _UserTable extends StatelessWidget {
  final AdminUserListViewModel viewModel;

  const _UserTable({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surface),
          borderRadius: BorderRadius.circular(16),
        ),
        child: DataTable(
          columnSpacing: 28,
          dividerThickness: 0,
          dataRowMinHeight: 76,
          dataRowMaxHeight: 76,
          headingRowHeight: 64,
          columns: const [
            DataColumn(label: Text('NHÂN VIÊN')),
            DataColumn(label: Text('EMAIL')),
            DataColumn(label: Text('VAI TRÒ')),
            DataColumn(label: Text('TRẠNG THÁI')),
            DataColumn(label: Text('THAO TÁC')),
          ],
          rows: viewModel.users
              .map((user) => _buildRow(context, user))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, ProfileModel user) {
    return DataRow(
      cells: [
        DataCell(_UserIdentity(user: user)),
        DataCell(Text(user.email)),
        DataCell(_RoleChip(role: user.role)),
        DataCell(_StatusChip(isActive: user.isActive)),
        DataCell(_UserActions(user: user, viewModel: viewModel)),
      ],
    );
  }
}

class _UserCardList extends StatelessWidget {
  final AdminUserListViewModel viewModel;

  const _UserCardList({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: viewModel.users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = viewModel.users[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserIdentity(user: user),
              const SizedBox(height: 8),
              Text(user.email, style: const TextStyle(color: AppColors.detail)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _RoleChip(role: user.role),
                  _StatusChip(isActive: user.isActive),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: _UserActions(user: user, viewModel: viewModel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserIdentity extends StatelessWidget {
  final ProfileModel user;

  const _UserIdentity({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.primary,
          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Text(
                  user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            user.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return _Chip(
      text: role == 'admin' ? 'Quản trị viên' : 'Nhân viên',
      color: role == 'admin'
          ? const Color(0xFF5B21B6)
          : const Color(0xFF1D4ED8),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return _Chip(
      text: isActive ? 'Đang hoạt động' : 'Đã vô hiệu hóa',
      color: isActive ? const Color(0xFF0F8644) : AppColors.error,
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final Color color;

  const _Chip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}

class _UserActions extends StatelessWidget {
  final ProfileModel user;
  final AdminUserListViewModel viewModel;

  const _UserActions({required this.user, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Sửa',
          icon: const Icon(Icons.edit_outlined),
          onPressed: () async {
            final result = await context.push('/admin/users/edit', extra: user);
            if (result == true) viewModel.loadUsers();
          },
        ),
      ],
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  final AdminUserListViewModel viewModel;

  const _PaginationFooter({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          onPressed: viewModel.hasPreviousPage ? viewModel.previousPage : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Trang ${viewModel.currentPage}/${viewModel.totalPages}'),
        IconButton(
          onPressed: viewModel.hasNextPage ? viewModel.nextPage : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  const _EmptyUsers();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: AppColors.detail),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy nhân viên nào',
            style: AppTextStyles.headlineMd.copyWith(color: AppColors.detail),
          ),
        ],
      ),
    );
  }
}
