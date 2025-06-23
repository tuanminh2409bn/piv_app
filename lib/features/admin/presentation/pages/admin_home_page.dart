import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_products_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_categories_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_product_form_page.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AdminHomePage());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AdminOrdersCubit>()..fetchAllOrders()),
        BlocProvider(create: (_) => sl<AdminProductsCubit>()..fetchAllProducts()),
        BlocProvider(create: (_) => sl<AdminCategoriesCubit>()..fetchAllCategories()),
        BlocProvider(create: (_) => sl<AdminUsersCubit>()..fetchAllUsers()),
      ],
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Trang Quản trị'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Đăng xuất',
                onPressed: () => context.read<AuthBloc>().add(AuthLogoutRequested()),
              ),
            ],
            bottom: const TabBar(
              // --- SỬA LỖI TABBAR DỨT ĐIỂM ---
              labelPadding: EdgeInsets.symmetric(horizontal: 4.0), // Giảm padding
              tabs: [
                Tab(child: Text('Đơn hàng', textAlign: TextAlign.center)),
                Tab(child: Text('Sản phẩm', textAlign: TextAlign.center)),
                Tab(child: Text('Danh mục', textAlign: TextAlign.center)),
                Tab(child: Text('Tài khoản', textAlign: TextAlign.center)),
              ],
              // --------------------------
            ),
          ),
          body: const TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              AdminOrdersView(),
              AdminProductsView(),
              AdminCategoriesView(),
              AdminUsersView(),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
//                     VIEW ĐƠN HÀNG
// =================================================================
class AdminOrdersView extends StatelessWidget {
  const AdminOrdersView({super.key});
  //... code của AdminOrdersView giữ nguyên ...
  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
      case 'pending': return (Colors.orange.shade700, 'Chờ xử lý');
      case 'processing': return (Colors.blue.shade700, 'Đang xử lý');
      case 'shipped': return (Colors.teal.shade700, 'Đang giao');
      case 'completed': return (Theme.of(context).colorScheme.primary, 'Hoàn thành');
      case 'cancelled': return (Colors.red.shade700, 'Đã hủy');
      default: return (Colors.grey.shade700, 'Không xác định');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Tìm theo mã đơn, tên, SĐT...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (query) => context.read<AdminOrdersCubit>().searchOrders(query),
          ),
        ),
        BlocBuilder<AdminOrdersCubit, AdminOrdersState>(
          buildWhen: (previous, current) => previous.currentFilter != current.currentFilter,
          builder: (context, state) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  _buildFilterChip(context, 'Cần xử lý', 'active', state.currentFilter),
                  _buildFilterChip(context, 'Hoàn thành', 'completed', state.currentFilter),
                  _buildFilterChip(context, 'Đã hủy', 'cancelled', state.currentFilter),
                  _buildFilterChip(context, 'Tất cả', 'all', state.currentFilter),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: BlocConsumer<AdminOrdersCubit, AdminOrdersState>(
            listener: (context, state) {
              if (state.status == AdminOrdersStatus.error && state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
              }
            },
            builder: (context, state) {
              if (state.status == AdminOrdersStatus.loading && state.filteredOrders.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.filteredOrders.isEmpty) {
                return const Center(child: Text('Không có đơn hàng nào khớp.'));
              }
              return RefreshIndicator(
                onRefresh: () async => context.read<AdminOrdersCubit>().fetchAllOrders(),
                child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    itemCount: state.filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = state.filteredOrders[index];
                      return _buildOrderCard(context, order);
                    }),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, String filterValue, String currentFilter) {
    final bool isSelected = currentFilter == filterValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) context.read<AdminOrdersCubit>().filterOrdersByStatus(filterValue);
        },
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).colorScheme.primary,
        shape: StadiumBorder(side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusInfo = _getStatusInfo(order.status, context);
    const List<String> statusOptions = ['pending', 'processing', 'shipped', 'completed', 'cancelled'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (order.id != null) {
            Navigator.of(context).push(OrderDetailPage.route(order.id!));
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Mã đơn: #${order.id?.substring(0, 8).toUpperCase() ?? 'N/A'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: statusInfo.$1.withOpacity(0.1), borderRadius: BorderRadius.circular(20),),
                    child: Text(statusInfo.$2, style: TextStyle(color: statusInfo.$1, fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ],
              ),
              const SizedBox(height: 4),
              if(order.createdAt != null)
                Text(
                    'Ngày đặt: ${dateFormat.format(order.createdAt!.toDate())}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)
                ),
              const Divider(height: 24),
              _buildInfoRow('Khách hàng:', order.shippingAddress.recipientName, isBold: true),
              _buildInfoRow('Số điện thoại:', order.shippingAddress.phoneNumber),
              _buildInfoRow('Địa chỉ:', order.shippingAddress.fullAddress),
              const SizedBox(height: 12),
              _buildInfoRow('Tổng tiền:', currencyFormatter.format(order.total), isBold: true, valueColor: Theme.of(context).colorScheme.primary),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cập nhật trạng thái:', style: TextStyle(fontWeight: FontWeight.w500)),
                  DropdownButton<String>(
                    value: order.status,
                    icon: const Icon(Icons.arrow_drop_down),
                    underline: Container(height: 2, color: statusInfo.$1),
                    onChanged: (String? newStatus) {
                      if (newStatus != null && newStatus != order.status) {
                        context.read<AdminOrdersCubit>().updateOrderStatus(order.id!, newStatus);
                      }
                    },
                    items: statusOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                          value: value,
                          child: Text(_getStatusInfo(value, context).$2, style: TextStyle(color: _getStatusInfo(value, context).$1, fontWeight: FontWeight.bold))
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label ', style: TextStyle(color: Colors.grey.shade700)),
          Expanded(child: Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: valueColor))),
        ],
      ),
    );
  }
}

// =================================================================
//                     VIEW SẢN PHẨM
// =================================================================
class AdminProductsView extends StatelessWidget {
  const AdminProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) => context.read<AdminProductsCubit>().searchProducts(query),
            ),
          ),
          Expanded(
            child: BlocBuilder<AdminProductsCubit, AdminProductsState>(
              builder: (context, state) {
                if (state.status == AdminProductsStatus.loading && state.filteredProducts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.filteredProducts.isEmpty) {
                  return const Center(child: Text('Không tìm thấy sản phẩm nào.'));
                }
                return RefreshIndicator(
                  onRefresh: () => context.read<AdminProductsCubit>().fetchAllProducts(),
                  child: ListView.separated(
                    itemCount: state.filteredProducts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
                    itemBuilder: (context, index) {
                      final product = state.filteredProducts[index];
                      return _buildProductListItem(context, product);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push<bool?>(AdminProductFormPage.route()).then((success) {
            if (success == true) {
              context.read<AdminProductsCubit>().fetchAllProducts();
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- SỬA LỖI OVERFLOW BẰNG CÁCH XÂY DỰNG LAYOUT THỦ CÔNG ---
  Widget _buildProductListItem(BuildContext context, ProductModel product) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final displayPrice = product.packingOptions.isNotEmpty && product.packingOptions.first.prices.isNotEmpty
        ? product.packingOptions.first.prices.values.first
        : 0.0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push<bool?>(AdminProductFormPage.route(product: product)).then((success) {
            if (success == true) {
              context.read<AdminProductsCubit>().fetchAllProducts();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Ảnh sản phẩm
              (product.imageUrl.isNotEmpty)
                  ? Image.network(product.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)))
                  : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image)),
              const SizedBox(width: 16),
              // Tên và giá
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 4),
                    Text('Giá từ: ${currencyFormatter.format(displayPrice)}'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Cụm action
              Row(
                children: [
                  Column(
                    children: [
                      const Text('Nổi bật', style: TextStyle(fontSize: 10)),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: product.isFeatured,
                          onChanged: (newValue) {
                            context.read<AdminProductsCubit>().toggleIsFeatured(product.id, product.isFeatured);
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                    tooltip: 'Xóa sản phẩm',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Xác nhận xóa'),
                          content: Text('Bạn có chắc chắn muốn xóa sản phẩm "${product.name}"? Hành động này không thể hoàn tác.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Hủy')),
                            TextButton(
                              onPressed: () {
                                context.read<AdminProductsCubit>().deleteProduct(product.id);
                                Navigator.of(dialogContext).pop();
                              },
                              child: Text('Xóa', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
//                     VIEW DANH MỤC
// =================================================================
class AdminCategoriesView extends StatelessWidget {
  const AdminCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AdminCategoriesCubit, AdminCategoriesState>(
        listener: (context, state) {
          if (state.status == AdminCategoriesStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state.status == AdminCategoriesStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final topLevelCategories = state.topLevelCategories;
          if (topLevelCategories.isEmpty) {
            return const Center(child: Text('Chưa có danh mục nào.'));
          }

          return RefreshIndicator(
            onRefresh: () async => context.read<AdminCategoriesCubit>().fetchAllCategories(),
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: topLevelCategories.map((category) {
                return _buildCategoryTree(context, category, state.allCategories, 0);
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryFormDialog(context),
        tooltip: 'Thêm danh mục gốc',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryTree(BuildContext context, CategoryModel category, List<CategoryModel> allCategories, int level) {
    final subCategories = allCategories.where((c) => c.parentId == category.id).toList();
    const double indentationStep = 20.0;

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: indentationStep * level, right: 8.0),
      leading: Icon(subCategories.isNotEmpty ? Icons.folder_open_rounded : Icons.article_outlined, color: subCategories.isNotEmpty ? Colors.amber.shade800 : Colors.grey.shade600),
      title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green), onPressed: () => _showCategoryFormDialog(context, parentCategory: category), tooltip: 'Thêm danh mục con'),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), onPressed: () => _showCategoryFormDialog(context, categoryToEdit: category), tooltip: 'Sửa danh mục này'),
          IconButton(icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error), onPressed: () => _showDeleteConfirmDialog(context, category, subCategories.isNotEmpty), tooltip: 'Xóa danh mục'),
        ],
      ),
      children: subCategories.map((sub) => _buildCategoryTree(context, sub, allCategories, level + 1)).toList(),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, CategoryModel category, bool hasChildren) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(hasChildren
            ? 'Danh mục "${category.name}" có chứa các danh mục con. Bạn không thể xóa. Vui lòng xóa hết các danh mục con trước.'
            : 'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
          if (!hasChildren)
            TextButton(
              onPressed: () {
                context.read<AdminCategoriesCubit>().deleteCategory(category.id);
                Navigator.of(dialogContext).pop();
              },
              child: Text('XÓA', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
    );
  }

  void _showCategoryFormDialog(BuildContext context, {CategoryModel? categoryToEdit, CategoryModel? parentCategory}) {
    final cubit = context.read<AdminCategoriesCubit>();
    final allCategories = (cubit.state as AdminCategoriesState).allCategories;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: categoryToEdit?.name ?? '');
    final imageUrlController = TextEditingController(text: categoryToEdit?.imageUrl ?? '');
    String? selectedParentId = categoryToEdit?.parentId ?? parentCategory?.id;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(categoryToEdit != null ? 'Sửa Danh mục' : 'Thêm Danh mục mới'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên danh mục'), validator: (v) => v!.isEmpty ? 'Không được để trống' : null),
                  const SizedBox(height: 16),
                  TextFormField(controller: imageUrlController, decoration: const InputDecoration(labelText: 'URL Ảnh đại diện')),
                  const SizedBox(height: 16),
                  const Text('Danh mục cha:', style: TextStyle(fontSize: 12)),
                  DropdownButtonFormField<String>(
                    value: selectedParentId,
                    isExpanded: true,
                    hint: const Text('Là danh mục gốc'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Không có (Là danh mục gốc)'),
                      ),
                      ...allCategories
                          .where((c) => c.id != categoryToEdit?.id)
                          .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ))
                    ],
                    onChanged: (value) => selectedParentId = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  cubit.saveCategory(
                    existingCategory: categoryToEdit,
                    name: nameController.text.trim(),
                    imageUrl: imageUrlController.text.trim(),
                    parentId: selectedParentId,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('LƯU'),
            ),
          ],
        );
      },
    );
  }
}

// =================================================================
//                     VIEW NGƯỜI DÙNG
// =================================================================
class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  (Color, String) _getStatusInfo(String status, BuildContext context) {
    switch (status) {
      case 'pending_approval': return (Colors.orange.shade700, 'Chờ duyệt');
      case 'active': return (Theme.of(context).colorScheme.primary, 'Hoạt động');
      case 'suspended': return (Colors.red.shade700, 'Bị khóa');
      default: return (Colors.grey.shade700, 'Không xác định');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BlocBuilder<AdminUsersCubit, AdminUsersState>(
            buildWhen: (previous, current) => previous.currentFilter != current.currentFilter,
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(value: 'all', label: Text('Tất cả')),
                    ButtonSegment<String>(value: 'pending_approval', label: Text('Chờ duyệt')),
                    ButtonSegment<String>(value: 'active', label: Text('Hoạt động')),
                  ],
                  selected: <String>{state.currentFilter},
                  onSelectionChanged: (Set<String> newSelection) {
                    context.read<AdminUsersCubit>().filterUsers(newSelection.first);
                  },
                ),
              );
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: BlocBuilder<AdminUsersCubit, AdminUsersState>(
              builder: (context, state) {
                if (state.status == AdminUsersStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.filteredUsers.isEmpty) {
                  return const Center(child: Text('Không có người dùng nào.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => context.read<AdminUsersCubit>().fetchAllUsers(),
                  child: ListView.separated(
                    itemCount: state.filteredUsers.length,
                    separatorBuilder: (_, __) => const Divider(height: 0, indent: 16),
                    itemBuilder: (context, index) {
                      final user = state.filteredUsers[index];
                      final statusInfo = _getStatusInfo(user.status, context);
                      return ListTile(
                        title: Text(user.displayName ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user.email ?? 'Không có email'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusInfo.$1.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                              child: Text(statusInfo.$2, style: TextStyle(color: statusInfo.$1, fontSize: 12, fontWeight: FontWeight.w500)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                        onTap: () => _showEditUserDialog(context, user),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(BuildContext parentContext, UserModel user) {
    final cubit = parentContext.read<AdminUsersCubit>();
    String selectedRole = user.role;
    String selectedStatus = user.status;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Cập nhật người dùng'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(user.email ?? ''),
                    const Divider(height: 24),
                    const Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedRole,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: 'agent_1', child: Text('Đại lý cấp 1')),
                        const DropdownMenuItem(value: 'agent_2', child: Text('Đại lý cấp 2')),
                        const DropdownMenuItem(value: 'sales_rep', child: Text('Nhân viên Kinh doanh')),
                        const DropdownMenuItem(value: 'accountant', child: Text('Kế toán')),
                        const DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedRole = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: 'pending_approval', child: Text('Chờ duyệt')),
                        const DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                        const DropdownMenuItem(value: 'suspended', child: Text('Bị khóa')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedStatus = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    cubit.updateUser(user.id, selectedRole, selectedStatus);
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}