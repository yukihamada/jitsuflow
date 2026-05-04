class NewsModel {
  final String id;
  final String title;
  final String? summary;
  final String? content;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String? category;

  const NewsModel({
    required this.id,
    required this.title,
    this.summary,
    this.content,
    this.imageUrl,
    this.publishedAt,
    this.category,
  });

  factory NewsModel.fromJson(Map<String, dynamic> j) => NewsModel(
        id: '${j['id'] ?? ''}',
        title: j['title'] ?? '',
        summary: j['summary'],
        content: j['content'],
        imageUrl: j['image_url'],
        publishedAt: j['published_at'] != null
            ? DateTime.tryParse(j['published_at'])
            : null,
        category: j['category'],
      );
}
