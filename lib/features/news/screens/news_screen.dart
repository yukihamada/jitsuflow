import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../models/news_model.dart';

final _apiClient = ApiClient();

Color _categoryColor(String? category) {
  switch (category) {
    case 'イベント':
    case 'bjj':
      return const Color(0xFF22C55E);
    case 'お知らせ':
    case 'site':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFFDC2626);
  }
}

String _categoryLabel(String? category) {
  switch (category) {
    case 'bjj':
      return 'BJJ';
    case 'site':
      return 'お知らせ';
    default:
      return category ?? 'ニュース';
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsModel>? _news;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _apiClient.fetchNews();
      if (mounted) setState(() { _news = data; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _error = 'データ取得に失敗しました'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('ニュース',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Color(0xFF71717A), size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
                      child: const Text('再試行', style: TextStyle(color: Color(0xFFDC2626))),
                    ),
                  ]))
              : _buildList(),
    );
  }

  Widget _buildList() {
    final items = _news ?? [];
    if (items.isEmpty) {
      return const Center(
        child: Text('ニュースがありません', style: TextStyle(color: Color(0xFF52525B))),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFDC2626),
      backgroundColor: const Color(0xFF18181B),
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: items.length,
        itemBuilder: (context, i) => _NewsCard(news: items[i]),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsModel news;
  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    final dateStr = news.publishedAt != null
        ? '${news.publishedAt!.year}/${news.publishedAt!.month}/${news.publishedAt!.day}'
        : '';
    final catLabel = _categoryLabel(news.category);
    final catColor = _categoryColor(news.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  catLabel,
                  style: TextStyle(
                    color: catColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            news.title,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          if (news.summary != null) ...[
            const SizedBox(height: 6),
            Text(
              news.summary!,
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
