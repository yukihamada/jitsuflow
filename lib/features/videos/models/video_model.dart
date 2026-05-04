class VideoModel {
  final String id;
  final String title;
  final String? description;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? authorName;
  final DateTime? createdAt;
  final int? viewCount;
  final String? videoType;

  const VideoModel({
    required this.id,
    required this.title,
    this.description,
    this.videoUrl,
    this.thumbnailUrl,
    this.authorName,
    this.createdAt,
    this.viewCount,
    this.videoType,
  });

  factory VideoModel.fromJson(Map<String, dynamic> j) => VideoModel(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        description: j['description'],
        videoUrl: j['video_url'],
        thumbnailUrl: j['thumbnail_url'],
        authorName: j['author_name'],
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'])
            : null,
        viewCount: j['view_count'],
        videoType: j['video_type'],
      );
}
