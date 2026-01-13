import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/returns/presentation/bloc/admin_returns_cubit.dart';
import 'package:piv_app/features/returns/presentation/pages/admin_return_request_detail_page.dart';

class AdminReturnRequestLoaderPage extends StatefulWidget {
  final String requestId;

  const AdminReturnRequestLoaderPage({super.key, required this.requestId});

  static Route route(String requestId) {
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => sl<AdminReturnsCubit>(),
        child: AdminReturnRequestLoaderPage(requestId: requestId),
      ),
    );
  }

  @override
  State<AdminReturnRequestLoaderPage> createState() => _AdminReturnRequestLoaderPageState();
}

class _AdminReturnRequestLoaderPageState extends State<AdminReturnRequestLoaderPage> {
  @override
  void initState() {
    super.initState();
    // Gọi hàm load chi tiết ngay khi init
    context.read<AdminReturnsCubit>().loadReturnRequestDetail(widget.requestId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AdminReturnsCubit, AdminReturnsState>(
        listener: (context, state) {
          if (state is AdminReturnsError) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
            Navigator.of(context).pop(); // Quay lại nếu lỗi
          }
        },
        builder: (context, state) {
          if (state is AdminReturnsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AdminReturnRequestLoaded) {
            // Khi đã có dữ liệu, hiển thị trang chi tiết
            // Lưu ý: Trang chi tiết cần Cubit để thực hiện các hành động (duyệt/từ chối)
            // Vì vậy ta truyền Cubit hiện tại vào
            return AdminReturnRequestDetailPage(request: state.request);
          }
          return const Center(child: Text('Đang tải dữ liệu...'));
        },
      ),
    );
  }
}
