import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:piv_app/data/models/user_model.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static PageRoute<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const ProfilePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ** SỬA LỖI Ở ĐÂY **
    // Cung cấp ProfileCubit cho cây widget của trang này.
    // Nó sẽ lấy instance singleton đã được đăng ký trong GetIt (sl).
    return BlocProvider(
      create: (_) => sl<ProfileCubit>(),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ Sơ Cá Nhân'),
        actions: [
          // Nút để chuyển đổi giữa chế độ xem và chỉnh sửa
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, state) {
              // Chỉ hiển thị nút khi đã tải xong (trạng thái success hoặc error)
              if (state.status == ProfileStatus.success || state.status == ProfileStatus.error) {
                return TextButton(
                  onPressed: () {
                    // Chuyển đổi chế độ chỉnh sửa
                    context.read<ProfileCubit>().toggleEditMode(!state.isEditing);
                  },
                  child: Text(
                    state.isEditing ? 'HỦY' : 'SỬA',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold),
                  ),
                );
              }
              // Ẩn nút khi đang loading hoặc ở trạng thái ban đầu
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ));
          }
          // Hiển thị thông báo khi lưu thành công
          if (state.status == ProfileStatus.success && !state.isEditing && ModalRoute.of(context)!.isCurrent) {
            final previousState = context.read<ProfileCubit>().state;
            if (previousState.status == ProfileStatus.updating) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: const Text('Cập nhật hồ sơ thành công!'),
                  backgroundColor: Colors.green.shade700,
                ));
            }
          }
        },
        builder: (context, state) {
          if (state.status == ProfileStatus.loading || state.status == ProfileStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.user.isEmpty && state.status != ProfileStatus.loading) {
            return const Center(child: Text('Không thể tải thông tin người dùng.'));
          }

          return _buildProfileForm(context, state.user, state.isEditing);
        },
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, UserModel user, bool isEditing) {
    // Sử dụng một Key cho Form để có thể validate nếu cần
    final _formKey = GlobalKey<FormState>();

    // Sử dụng TextEditingController để quản lý text trong TextFormField tốt hơn
    // và không bị reset khi rebuild.
    final _displayNameController = TextEditingController(text: user.displayName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Các trường thông tin
            TextFormField(
              controller: _displayNameController,
              enabled: isEditing,
              decoration: InputDecoration(
                labelText: 'Tên hiển thị',
                border: const OutlineInputBorder(),
                filled: !isEditing,
                fillColor: !isEditing ? Colors.grey.shade100 : null,
              ),
              onChanged: (value) {
                // Chỉ cần gọi khi người dùng thực sự thay đổi text
                // Không cần gọi trong build
              },
              validator: (value) {
                if(value == null || value.isEmpty) {
                  return 'Tên hiển thị không được để trống';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: user.email,
              enabled: false, // Không cho phép sửa email
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),

            // Thêm các trường khác ở đây, ví dụ:
            // const SizedBox(height: 16),
            // TextFormField(
            //   initialValue: user.phoneNumber, // Cần thêm phoneNumber vào UserModel
            //   enabled: isEditing,
            //   decoration: InputDecoration(labelText: 'Số điện thoại', border: const OutlineInputBorder()),
            //   onChanged: (value) { /* ... */ },
            // ),

            const SizedBox(height: 32),

            // Nút Lưu chỉ hiển thị ở chế độ chỉnh sửa
            if (isEditing)
              SizedBox(
                width: double.infinity,
                child: BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    return state.status == ProfileStatus.updating
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: () {
                        // Cập nhật giá trị từ controller vào cubit trước khi lưu
                        context.read<ProfileCubit>().profileFieldChanged(displayName: _displayNameController.text);
                        // Một chút delay để đảm bảo state đã cập nhật trước khi save
                        Future.delayed(const Duration(milliseconds: 50), () {
                          context.read<ProfileCubit>().saveUserProfile();
                        });
                      },
                      child: const Text('LƯU THAY ĐỔI'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
