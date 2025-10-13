// lib/features/admin/presentation/pages/admin_news_list_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:piv_app/data/models/news_article_model.dart';
import 'admin_news_form_page.dart';

class AdminNewsListPage extends StatelessWidget {
  const AdminNewsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tin tức'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('newsArticles').orderBy('publishedDate', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // ✅ CORRECTED TO USE fromSnapshot
          final articles = snapshot.data!.docs
              .map((doc) => NewsArticleModel.fromSnapshot(doc))
              .toList();

          return ListView.builder(
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return ListTile(
                leading: article.imageUrl.isNotEmpty ? Image.network(article.imageUrl, width: 50, height: 50, fit: BoxFit.cover) : const Icon(Icons.article),
                title: Text(article.title),
                subtitle: Text(article.summary, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.edit),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminNewsFormPage(article: article))),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminNewsFormPage())),
        label: const Text('Tạo Bài Viết'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}