import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/data/models/commission_model.dart';
import 'package:piv_app/data/models/order_model.dart';
import 'package:piv_app/data/models/user_model.dart';
import 'package:piv_app/data/models/voucher_with_details.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_commissions_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_orders_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_settings_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_vouchers_cubit.dart';
import 'package:piv_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:piv_app/features/orders/presentation/pages/order_detail_page.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_products_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_categories_cubit.dart';
import 'package:piv_app/features/admin/presentation/bloc/admin_users_cubit.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/admin/presentation/pages/admin_product_form_page.dart';
import 'package:piv_app/features/home/data/models/category_model.dart';
import 'package:piv_app/data/models/commission_with_details.dart';
import 'package:piv_app/features/vouchers/data/models/voucher_model.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AdminHomePage());
  }

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- HÀM NÀY GIỮ NGUYÊN TỪ FILE GỐC CỦA BẠN ---
  Widget? _buildFloatingActionButton(BuildContext context) {
    switch (_currentTabIndex) {
      case 1: // Products
        return FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push<bool?>(AdminProductFormPage.route()).then((success) {
              if (success == true) {
                context.read<AdminProductsCubit>().fetchAllProducts();
              }
            });
          },
          child: const Icon(Icons.add),
        );
      case 2: // Categories
        return FloatingActionButton(
          onPressed: () => AdminCategoriesView.showCategoryFormDialog(context),
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AdminOrdersCubit>()..fetchAllOrders()),
        BlocProvider(create: (_) => sl<AdminProductsCubit>()..fetchAllProducts()),
        BlocProvider(create: (_) => sl<AdminCategoriesCubit>()..fetchAllCategories()),
        BlocProvider(create: (_) => sl<AdminUsersCubit>()..fetchAllUsers()),
        BlocProvider(create: (_) => sl<AdminCommissionsCubit>()..fetchAllData()),
        BlocProvider(create: (_) => sl<AdminSettingsCubit>()..loadSettings()),
        BlocProvider(create: (_) => sl<AdminVouchersCubit>()..fetchPendingVouchers()),
      ],
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
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Đơn hàng'),
              Tab(text: 'Sản phẩm'),
              Tab(text: 'Danh mục'),
              Tab(text: 'Người dùng'),
              Tab(text: 'Hoa hồng'),
              Tab(text: 'Cài đặt'),
              Tab(text: 'Duyệt Voucher'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            AdminOrdersView(),
            AdminProductsView(),
            AdminCategoriesView(),
            AdminUsersView(),
            AdminCommissionsView(),
            AdminSettingsView(),
            AdminVouchersView(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(context),
      ),
    );
  }
}

enum OrderFilter { processing, completed, all }

class AdminOrdersView extends StatefulWidget {
  const AdminOrdersView({super.key});

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
  OrderFilter _selectedFilter = OrderFilter.processing;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        context.read<AdminOrdersCubit>().searchOrders(_searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminOrdersCubit, AdminOrdersState>(
      listener: (context, state) {
        if (state.status == AdminOrdersStatus.error && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red));
        }
      },
      builder: (context, state) {
        final List<OrderModel> displayedOrders;
        switch (_selectedFilter) {
          case OrderFilter.processing:
            displayedOrders = state.processingOrders;
            break;
          case OrderFilter.completed:
            displayedOrders = state.completedOrders;
            break;
          case OrderFilter.all:
            displayedOrders = state.visibleOrders;
            break;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedButton<OrderFilter>(
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                  selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                ),
                segments: <ButtonSegment<OrderFilter>>[
                  ButtonSegment(
                    value: OrderFilter.processing,
                    label: Text('Cần xử lý (${state.processingOrders.length})'),
                    icon: const Icon(Icons.pending_actions_outlined),
                  ),
                  ButtonSegment(
                    value: OrderFilter.completed,
                    label: Text('Hoàn thành (${state.completedOrders.length})'),
                    icon: const Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: OrderFilter.all,
                    label: Text('Tất cả (${state.visibleOrders.length})'),
                    icon: const Icon(Icons.inventory_2_outlined),
                  ),
                ],
                selected: {_selectedFilter},
                onSelectionChanged: (Set<OrderFilter> newSelection) {
                  setState(() => _selectedFilter = newSelection.first);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm theo mã ĐH, tên hoặc SĐT khách...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _searchController.clear(),
                  )
                      : null,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.status == AdminOrdersStatus.loading && displayedOrders.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : displayedOrders.isEmpty
                  ? Center(child: Text('Không có đơn hàng nào phù hợp.'))
                  : RefreshIndicator(
                onRefresh: () => context.read<AdminOrdersCubit>().fetchAllOrders(),
                child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                    itemCount: displayedOrders.length,
                    itemBuilder: (context, index) {
                      final order = displayedOrders[index];
                      return _buildOrderCard(context, order);
                    }),
              ),
            ),
          ],
        );
      },
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
                        _showStatusChangeConfirmationDialog(
                          context,
                          orderId: order.id!,
                          newStatus: newStatus,
                          newStatusText: _getStatusInfo(newStatus, context).$2,
                        );
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

  void _showStatusChangeConfirmationDialog(BuildContext context, {
    required String orderId,
    required String newStatus,
    required String newStatusText,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận thay đổi'),
          content: Text('Bạn có chắc chắn muốn đổi trạng thái đơn hàng thành "$newStatusText"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('HỦY'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<AdminOrdersCubit>().updateOrderStatus(orderId, newStatus);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('XÁC NHẬN'),
            )
          ],
        );
      },
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

class AdminProductsView extends StatelessWidget {
  const AdminProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                  separatorBuilder: (_, __) => const Divider(height: 1),
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
    );
  }

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
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (product.imageUrl.isNotEmpty)
                    ? Image.network(product.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)))
                    : Container(width: 60, height: 60, color: Colors.grey.shade200, child: const Icon(Icons.image)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis,),
                    const SizedBox(height: 4),
                    Text('Giá từ: ${currencyFormatter.format(displayPrice)}'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
          ),
        ),
      ),
    );
  }
}

class AdminCategoriesView extends StatelessWidget {
  const AdminCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminCategoriesCubit, AdminCategoriesState>(
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
          IconButton(icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green), onPressed: () => showCategoryFormDialog(context, parentCategory: category), tooltip: 'Thêm danh mục con'),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), onPressed: () => showCategoryFormDialog(context, categoryToEdit: category), tooltip: 'Sửa danh mục này'),
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

  static void showCategoryFormDialog(BuildContext context, {CategoryModel? categoryToEdit, CategoryModel? parentCategory}) {
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
    return Column(
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
                      items: const [
                        DropdownMenuItem(value: 'agent_1', child: Text('Đại lý cấp 1')),
                        DropdownMenuItem(value: 'agent_2', child: Text('Đại lý cấp 2')),
                        DropdownMenuItem(value: 'sales_rep', child: Text('Nhân viên Kinh doanh')),
                        DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
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
                      items: const [
                        DropdownMenuItem(value: 'pending_approval', child: Text('Chờ duyệt')),
                        DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                        DropdownMenuItem(value: 'suspended', child: Text('Bị khóa')),
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

class AdminCommissionsView extends StatelessWidget {
  const AdminCommissionsView({super.key});

  Future<void> _selectDateRange(BuildContext context, AdminCommissionsState state) async {
    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: state.startDate != null && state.endDate != null
          ? DateTimeRange(start: state.startDate!, end: state.endDate!)
          : null,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('vi', 'VN'),
    );

    if (newDateRange != null) {
      context.read<AdminCommissionsCubit>().setDateRange(newDateRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(context),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: BlocConsumer<AdminCommissionsCubit, AdminCommissionsState>(
            listener: (context, state) {
              if (state.status == AdminCommissionsStatus.error && state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              }
            },
            builder: (context, state) {
              if (state.status == AdminCommissionsStatus.loading && state.allCommissions.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.allCommissions.isEmpty) {
                return const Center(child: Text('Không có dữ liệu hoa hồng.'));
              }
              if (state.filteredCommissions.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => context.read<AdminCommissionsCubit>().fetchAllData(),
                  child: const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Center(heightFactor: 5, child: Text('Không có hoa hồng nào khớp với bộ lọc.'))
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => context.read<AdminCommissionsCubit>().fetchAllData(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: state.filteredCommissions.length,
                  itemBuilder: (context, index) {
                    final commissionItem = state.filteredCommissions[index];
                    return _buildCommissionCard(context, commissionItem);
                  },
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BlocBuilder<AdminCommissionsCubit, AdminCommissionsState>(
        builder: (context, state) {
          final dateFormat = DateFormat('dd/MM/yyyy');
          final startDateText = state.startDate != null ? dateFormat.format(state.startDate!) : 'Từ ngày';
          final endDateText = state.endDate != null ? dateFormat.format(state.endDate!) : 'Đến ngày';

          return Column(
            children: [
              if (state.salesReps.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: state.selectedSalesRepId,
                  isExpanded: true,
                  hint: const Text('Tất cả Nhân viên Kinh doanh'),
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person_search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15)
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tất cả NVKD'),
                    ),
                    ...state.salesReps.map((salesRep) {
                      return DropdownMenuItem<String>(
                        value: salesRep.id,
                        child: Text(salesRep.displayName ?? salesRep.email ?? 'N/A'),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    context.read<AdminCommissionsCubit>().filterBySalesRep(value);
                  },
                )
              else
                const SizedBox(height: 58, child: Center(child: Text("Đang tải danh sách NVKD..."))),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(startDateText),
                      onPressed: () => _selectDateRange(context, state),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('-'),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_outlined, size: 18),
                      label: Text(endDateText),
                      onPressed: () => _selectDateRange(context, state),
                    ),
                  ),
                  if (state.startDate != null || state.endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Xóa bộ lọc ngày',
                      onPressed: () => context.read<AdminCommissionsCubit>().setDateRange(null),
                    )
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: 'all', label: Text('Tất cả')),
                  ButtonSegment<String>(value: 'pending', label: Text('Chờ xác nhận')),
                  ButtonSegment<String>(value: 'paid', label: Text('Đã xác nhận')),
                ],
                selected: <String>{state.currentFilter},
                onSelectionChanged: (newSelection) {
                  context.read<AdminCommissionsCubit>().filterByStatus(newSelection.first);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommissionCard(BuildContext context, CommissionWithDetails item) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final commission = item.commission;
    final salesRepName = item.salesRepName;
    final isPending = commission.status == CommissionStatus.pending;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn hàng: #${commission.orderId.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('NVKD: $salesRepName', style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('Đại lý: ${commission.agentName}'),
            const Divider(),
            _buildInfoRow(context, 'Ngày tạo:', dateFormat.format(commission.createdAt.toDate())),
            _buildInfoRow(context, 'Giá trị ĐH:', currencyFormatter.format(commission.orderTotal)),
            _buildInfoRow(context, 'Hoa hồng (${(commission.commissionRate * 100).toStringAsFixed(1)}%):', currencyFormatter.format(commission.commissionAmount), isBold: true),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    isPending ? 'Chờ xác nhận' : 'Đã xác nhận',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: isPending ? Colors.orange.shade700 : Colors.green.shade700,
                ),
                if (isPending)
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Xác nhận Hoa hồng'),
                            content: Text('Bạn có chắc chắn muốn xác nhận khoản hoa hồng ${currencyFormatter.format(commission.commissionAmount)}?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
                              ElevatedButton(onPressed: (){
                                context.read<AdminCommissionsCubit>().markAsPaid(commission.id);
                                Navigator.of(dialogContext).pop();
                              }, child: const Text('XÁC NHẬN')),
                            ],
                          )
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                    child: const Text('Xác nhận'),
                  )
                else if (commission.paidAt != null)
                  Text('Ngày XN: ${dateFormat.format(commission.paidAt!.toDate())}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class AdminVouchersView extends StatelessWidget {
  const AdminVouchersView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chờ duyệt Tạo/Sửa'),
              Tab(text: 'Chờ duyệt Xóa'),
            ],
          ),
        ),
        body: BlocBuilder<AdminVouchersCubit, AdminVouchersState>(
          builder: (context, state) {
            if (state.status == AdminVoucherStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == AdminVoucherStatus.error) {
              return Center(child: Text(state.errorMessage ?? 'Lỗi tải dữ liệu'));
            }

            return TabBarView(
              children: [
                _buildVoucherList(
                  context,
                  vouchers: state.pendingCreationVouchers,
                  emptyMessage: 'Không có yêu cầu tạo/sửa voucher nào.',
                  isDeletionRequest: false,
                ),
                _buildVoucherList(
                  context,
                  vouchers: state.pendingDeletionVouchers,
                  emptyMessage: 'Không có yêu cầu xóa voucher nào.',
                  isDeletionRequest: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVoucherList(
      BuildContext context, {
        required List<VoucherWithDetails> vouchers,
        required String emptyMessage,
        bool isDeletionRequest = false,
      }) {
    if (vouchers.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: vouchers.length,
      itemBuilder: (context, index) {
        final item = vouchers[index];
        final voucher = item.voucher;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(voucher.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(voucher.description),
                const Divider(height: 20),
                Text('Người tạo: ${item.createdByName}'),
                Text('Ngày hết hạn: ${DateFormat('dd/MM/yyyy').format(voucher.expiresAt.toDate())}'),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text('TỪ CHỐI', style: TextStyle(color: Colors.red)),
                      onPressed: () => _showReviewDialog(context, voucher, 'reject', isDeletionRequest),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      child: Text(isDeletionRequest ? 'DUYỆT XÓA' : 'DUYỆT'),
                      onPressed: () => _showReviewDialog(context, voucher, 'approve', isDeletionRequest),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReviewDialog(BuildContext context, VoucherModel voucher, String decision, bool isDeletionRequest) {
    final notesController = TextEditingController();
    final cubit = context.read<AdminVouchersCubit>();
    String title = decision == 'approve' ? (isDeletionRequest ? 'Duyệt Xóa Voucher' : 'Duyệt Voucher') : 'Từ chối Voucher';
    String content = 'Bạn có chắc chắn muốn ${decision == 'approve' ? (isDeletionRequest ? 'xóa' : 'phê duyệt') : 'từ chối'} voucher "${voucher.id}"?';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(content),
            if (decision == 'reject') ...[
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Lý do từ chối (tùy chọn)'),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('HỦY')),
          ElevatedButton(
            child: const Text('XÁC NHẬN'),
            onPressed: () {
              cubit.reviewVoucher(
                voucher: voucher,
                decision: decision,
                notes: notesController.text.trim(),
              );
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}

class AdminSettingsView extends StatelessWidget {
  const AdminSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSettingsCubit, AdminSettingsState>(
      builder: (context, state) {
        if (state.status == AdminSettingsStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Cài đặt chung', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _CommissionRateCard(initialRate: state.commissionRate),
          ],
        );
      },
    );
  }
}

class _CommissionRateCard extends StatefulWidget {
  final double initialRate;
  const _CommissionRateCard({required this.initialRate});

  @override
  State<_CommissionRateCard> createState() => _CommissionRateCardState();
}

class _CommissionRateCardState extends State<_CommissionRateCard> {
  late TextEditingController _textController;
  late double _currentSliderValue;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentSliderValue = (widget.initialRate * 100).clamp(0, 100);
    _textController = TextEditingController(text: _currentSliderValue.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant _CommissionRateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRate != oldWidget.initialRate && !_hasChanges) {
      final newRate = (widget.initialRate * 100).clamp(0, 100).toDouble();
      setState(() {
        _currentSliderValue = newRate;
        _textController.text = newRate.toStringAsFixed(1);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSave() {
    context.read<AdminSettingsCubit>().saveCommissionRate(_textController.text.trim());
    setState(() => _hasChanges = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.percent_rounded, color: Theme.of(context).colorScheme.primary),
              title: const Text('Tỷ lệ hoa hồng', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Tỷ lệ hoa hồng chung cho Nhân viên Kinh doanh'),
            ),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${_currentSliderValue.toStringAsFixed(1)} %',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary
                ),
              ),
            ),
            Slider(
              value: _currentSliderValue,
              min: 0,
              max: 100,
              divisions: 200,
              label: _currentSliderValue.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _hasChanges = true;
                  _currentSliderValue = value;
                  _textController.text = value.toStringAsFixed(1);
                });
              },
            ),
            Row(
              children: [
                const Expanded(child: Text('Hoặc nhập chính xác:', style: TextStyle(fontSize: 14))),
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _textController,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        suffixText: '%',
                        contentPadding: EdgeInsets.symmetric(horizontal: 8)
                    ),
                    onChanged: (value) {
                      final parsedValue = double.tryParse(value);
                      if (parsedValue != null && parsedValue >= 0 && parsedValue <= 100) {
                        setState(() {
                          _hasChanges = true;
                          _currentSliderValue = parsedValue;
                        });
                      } else {
                        setState(() {
                          _hasChanges = true;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_hasChanges)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: _onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Lưu thay đổi'),
                ),
              )
          ],
        ),
      ),
    );
  }
}