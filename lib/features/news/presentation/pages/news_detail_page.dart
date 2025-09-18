//lib/features/news/presentation/pages/news_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:piv_app/core/di/injection_container.dart';
import 'package:piv_app/features/news/presentation/bloc/news_detail_cubit.dart';
import 'package:piv_app/data/models/news_article_model.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailPage extends StatelessWidget {
  final String articleId;

  const NewsDetailPage({super.key, required this.articleId});

  static PageRoute<void> route(String articleId) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(arguments: articleId),
      builder: (_) => NewsDetailPage(articleId: articleId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NewsDetailCubit>()..fetchNewsArticleDetail(articleId),
      child: const NewsDetailView(),
    );
  }
}

class NewsDetailView extends StatelessWidget {
  const NewsDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<NewsDetailCubit, NewsDetailState>(
        builder: (context, state) {
          if (state.status == NewsDetailStatus.loading || state.status == NewsDetailStatus.initial) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (state.status == NewsDetailStatus.error || state.article == null) {
            return _buildErrorView(context, state.errorMessage);
          }

          final article = state.article!;
          final DateFormat dateFormat = DateFormat('EEEE, dd/MM/yyyy, HH:mm', 'vi_VN');

          return CustomScrollView(
            slivers: <Widget>[
              _buildSliverAppBar(article),
              SliverToBoxAdapter(
                child: _buildArticleContent(context, article, dateFormat),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---

  Widget _buildErrorView(BuildContext context, String? errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage ?? 'Không thể tải chi tiết bài viết.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              onPressed: () {
                final String? articleIdFromArgs = ModalRoute.of(context)?.settings.arguments as String?;
                if (articleIdFromArgs != null) {
                  context.read<NewsDetailCubit>().fetchNewsArticleDetail(articleIdFromArgs);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi: Không tìm thấy ID bài viết để tải lại.')),
                  );
                  if(Navigator.canPop(context)) Navigator.pop(context);
                }
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(NewsArticleModel article) {
    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      elevation: 2.0,
      backgroundColor: Colors.green.shade700,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 12.0),
        title: Text(
          article.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17.0,
            fontWeight: FontWeight.bold,
            shadows: <Shadow>[
              Shadow(offset: Offset(0.0, 1.5), blurRadius: 3.0, color: Color.fromARGB(180, 0, 0, 0)),
              Shadow(offset: Offset(0.0, 1.5), blurRadius: 8.0, color: Color.fromARGB(180, 0, 0, 0)),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (article.imageUrl.isNotEmpty)
              Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade400,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined, color: Colors.white70, size: 60),
                ),
              )
            else
              Container(color: Colors.green.shade600),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.4, 0.6, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent(BuildContext context, NewsArticleModel article, DateFormat dateFormat) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildArticleMetaInfo(context, article, dateFormat),
            const Divider(height: 24, thickness: 0.8),

            if (article.summary.isNotEmpty && article.summary != article.content) ...[
              _buildSummarySection(context, article.summary),
              const Divider(height: 24, thickness: 0.8),
            ],

            SelectableText(
              article.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.7,
                color: Colors.black.withOpacity(0.85),
                fontSize: 16,
              ),
              textAlign: TextAlign.justify,
            ),
            if (article.sourceUrl != null && article.sourceUrl!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSourceLink(context, article.sourceUrl!), // Truyền sourceUrl
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildArticleMetaInfo(BuildContext context, NewsArticleModel article, DateFormat dateFormat) {
    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          dateFormat.format(article.publishedDate.toDate()),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700, fontSize: 13),
        ),
        if (article.author != null && article.author!.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text("•", style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(width: 6),
          Icon(Icons.person_outline, size: 15, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              article.author!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context, String summary) {
    final summaryStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: Colors.black.withOpacity(0.75),
      height: 1.5,
    );
    return Text(
      summary,
      style: summaryStyle,
    );
  }

  // 2. Cập nhật hàm _buildSourceLink
  Widget _buildSourceLink(BuildContext context, String sourceUrl) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      ),
      icon: Icon(Icons.link_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
      label: Text(
        'Xem nguồn bài viết',
        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onPressed: () async {
        final Uri url = Uri.parse(sourceUrl);
        // Sử dụng canLaunchUrl để kiểm tra xem link có thể mở được không
        if (await canLaunchUrl(url)) {
          // Mở link trong trình duyệt bên ngoài ứng dụng
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          // Nếu không mở được, hiển thị thông báo lỗi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể mở được link: $sourceUrl')),
          );
        }
      },
    );
  }
}
