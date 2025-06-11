import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/products/presentation/bloc/product_detail_cubit.dart';
import 'package:piv_app/features/home/data/models/product_model.dart';
import 'package:piv_app/features/cart/presentation/bloc/cart_cubit.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;
  const ProductDetailPage({super.key, required this.productId});

  static PageRoute<void> route(String productId) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(arguments: productId),
      builder: (_) => ProductDetailPage(productId: productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ProductDetailCubit>()..fetchProductDetail(productId),
      child: const ProductDetailView(),
    );
  }
}

class ProductDetailView extends StatefulWidget {
  const ProductDetailView({super.key});
  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  // Controller không còn cần thiết nếu chúng ta không dùng slider
  // final CarouselSliderController _imageCarouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<CartCubit, CartState>(
        listener: (context, cartState) {
          if (cartState.status == CartStatus.success) {
            ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(const SnackBar(content: Text('Đã thêm sản phẩm vào giỏ hàng!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
          } else if (cartState.status == CartStatus.error) {
            ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(cartState.errorMessage ?? 'Thêm vào giỏ hàng thất bại.'), backgroundColor: Theme.of(context).colorScheme.error));
          }
        },
        child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
          builder: (context, state) {
            if (state.status == ProductDetailStatus.loading || state.status == ProductDetailStatus.initial) {
              return const Center(child: CircularProgressIndicator(color: Colors.green));
            }
            if (state.status == ProductDetailStatus.error || state.product == null) {
              return _buildErrorView(context, state.errorMessage);
            }

            final product = state.product!;
            final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

            return Stack(
              children: [
                CustomScrollView(
                  slivers: <Widget>[
                    _buildProductImageAppBar(context, product),
                    SliverToBoxAdapter(
                      child: _buildProductInfo(context, product, currencyFormatter, state.quantity),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                  ],
                ),
                _buildAddToCartButton(context, product, state.quantity),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- HÀM HELPER ---

  Widget _buildErrorView(BuildContext context, String? errorMessage) {
    return Scaffold(appBar: AppBar(title: const Text("Lỗi")),body: Center(child: Padding(padding: const EdgeInsets.all(20.0),child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [Text(errorMessage ?? 'Không thể tải chi tiết sản phẩm.',textAlign: TextAlign.center,style: Theme.of(context).textTheme.titleMedium,),const SizedBox(height: 20),ElevatedButton.icon(icon: const Icon(Icons.refresh),label: const Text('Thử lại'),onPressed: () {final String? productIdFromArgs = ModalRoute.of(context)?.settings.arguments as String?;if (productIdFromArgs != null) {context.read<ProductDetailCubit>().fetchProductDetail(productIdFromArgs);}})],),),),);
  }

  Widget _buildProductImageAppBar(BuildContext context, ProductModel product) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.width,
      stretch: true,
      pinned: true,
      elevation: 2.0,
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black87),
      flexibleSpace: FlexibleSpaceBar(
        background: (product.imageUrl.isEmpty)
            ? Container(color: Colors.grey.shade200, child: const Icon(Icons.image_search_outlined, size: 80, color: Colors.grey))
            : Image.network(
          product.imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined, size: 80, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, ProductModel product, NumberFormat formatter, int quantity) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '${formatter.format(product.displayPrice)} / ${product.unit}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          _buildQuantitySelector(context, quantity),
          const SizedBox(height: 24),
          _buildInfoSection(context, title: 'Mô tả sản phẩm', content: product.description),
          const SizedBox(height: 24),

          // ** THÊM PHẦN HIỂN THỊ THUỘC TÍNH (ATTRIBUTES) Ở ĐÂY **
          if(product.attributes != null && product.attributes!.isNotEmpty)
            _buildInfoSection(
              context,
              title: 'Thông tin chi tiết',
              child: _buildAttributesTable(context, product.attributes!), // Gọi hàm helper mới
            ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context, int quantity) {
    return Row(children: [Text('Số lượng:', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),const Spacer(),IconButton(icon: const Icon(Icons.remove_circle_outline),onPressed: () => context.read<ProductDetailCubit>().decrementQuantity(),color: Colors.grey.shade700,),Text('$quantity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),IconButton(icon: const Icon(Icons.add_circle),onPressed: () => context.read<ProductDetailCubit>().incrementQuantity(),color: Theme.of(context).colorScheme.primary,),],);
  }

  Widget _buildInfoSection(BuildContext context, {required String title, String? content, Widget? child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start,children: [Text(title,style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),),const Divider(height: 16, thickness: 1),if(content != null && content.isNotEmpty)Padding(padding: const EdgeInsets.only(top: 4.0),child: Text(content,style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5, color: Colors.black.withOpacity(0.7)),),),if(child != null)Padding(padding: const EdgeInsets.only(top: 8.0),child: child,),],);
  }

  // ** HÀM HELPER MỚI ĐỂ HIỂN THỊ BẢNG THUỘC TÍNH **
  Widget _buildAttributesTable(BuildContext context, Map<String, dynamic> attributes) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(), // Cột key sẽ tự động co lại
        1: FlexColumnWidth(),       // Cột value sẽ lấp đầy phần còn lại
      },
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      children: attributes.entries.map((entry) {
        return TableRow(
          children: [
            // Cột Key (Tên thuộc tính)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Text(
                '${entry.key}:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            // Cột Value (Giá trị thuộc tính)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
              child: Text(
                entry.value.toString(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black.withOpacity(0.8)),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAddToCartButton(BuildContext context, ProductModel product, int quantity) {
    final cartStatus = context.watch<CartCubit>().state.status;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),),
        child: (cartStatus == CartStatus.itemAdding)
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
          icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
          label: const Text('Thêm vào giỏ hàng'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16),textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          onPressed: () {
            context.read<CartCubit>().addProduct(product, quantity);
          },
        ),
      ),
    );
  }
}
