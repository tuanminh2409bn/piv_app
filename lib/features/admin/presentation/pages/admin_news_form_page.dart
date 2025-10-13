// lib/features/admin/presentation/pages/admin_news_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:piv_app/data/models/news_article_model.dart';
import 'package:piv_app/features/admin/presentation/bloc/news_form_cubit.dart';

class AdminNewsFormPage extends StatelessWidget {
  final NewsArticleModel? article;
  const AdminNewsFormPage({super.key, this.article});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NewsFormCubit()..loadArticle(article),
      child: const _AdminNewsFormView(),
    );
  }
}

class _AdminNewsFormView extends StatelessWidget {
  const _AdminNewsFormView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<NewsFormCubit, NewsFormState>(
      listener: (context, state) {
        if (state.status == NewsFormStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu bài viết thành công!'), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        }
        if (state.status == NewsFormStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage ?? 'Đã có lỗi'), backgroundColor: Colors.red));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.read<NewsFormCubit>().state.article.id == 'new' ? 'Tạo Bài Viết Mới' : 'Sửa Bài Viết'),
          actions: [
            if(context.watch<NewsFormCubit>().state.status == NewsFormStatus.saving)
              const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()),
            if(context.watch<NewsFormCubit>().state.status != NewsFormStatus.saving)
              TextButton(onPressed: () => context.read<NewsFormCubit>().saveArticle(), child: const Text('Lưu & Đăng')),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                initialValue: context.read<NewsFormCubit>().state.article.title,
                decoration: const InputDecoration(labelText: 'Tiêu đề bài viết'),
                onChanged: (value) => context.read<NewsFormCubit>().updateField(title: value),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // ✅ CORRECTED TO USE 'summary'
              TextFormField(
                initialValue: context.read<NewsFormCubit>().state.article.summary,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn (Dùng cho thông báo)'),
                onChanged: (value) => context.read<NewsFormCubit>().updateField(summary: value),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: context.read<NewsFormCubit>().state.article.imageUrl,
                decoration: const InputDecoration(labelText: 'URL Ảnh đại diện'),
                onChanged: (value) => context.read<NewsFormCubit>().updateField(imageUrl: value),
              ),
              const SizedBox(height: 24),
              // ✅ CORRECTED TO USE 'content'
              TextFormField(
                initialValue: context.read<NewsFormCubit>().state.article.content,
                decoration: const InputDecoration(labelText: 'Nội dung chính'),
                maxLines: 15,
                onChanged: (value) => context.read<NewsFormCubit>().updateField(content: value),
              )
            ],
          ),
        ),
      ),
    );
  }
}