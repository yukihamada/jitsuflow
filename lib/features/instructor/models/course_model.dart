class CourseModel {
  final String id;
  final String title;
  final String instructorName;
  final String? instructorAvatar;
  final String description;
  final String? thumbnailUrl;
  final int priceYen;
  final int lessonCount;
  final String level; // 'beginner', 'intermediate', 'advanced'
  final String category; // 'guard', 'passing', 'submissions', 'takedowns', 'competition'
  final double rating;
  final int reviewCount;
  final bool isPurchased;

  const CourseModel({
    required this.id,
    required this.title,
    required this.instructorName,
    this.instructorAvatar,
    required this.description,
    this.thumbnailUrl,
    required this.priceYen,
    required this.lessonCount,
    this.level = 'beginner',
    this.category = 'guard',
    this.rating = 0,
    this.reviewCount = 0,
    this.isPurchased = false,
  });

  String get levelLabel {
    switch (level) {
      case 'beginner':
        return '初心者';
      case 'intermediate':
        return '中級者';
      case 'advanced':
        return '上級者';
      default:
        return level;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'guard':
        return 'ガード';
      case 'passing':
        return 'パス';
      case 'submissions':
        return 'サブミッション';
      case 'takedowns':
        return 'テイクダウン';
      case 'competition':
        return '試合対策';
      default:
        return category;
    }
  }

  String get formattedPrice =>
      '¥${priceYen.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        instructorName: j['instructor_name'] as String? ?? '',
        instructorAvatar: null,
        description: j['description'] as String? ?? '',
        thumbnailUrl: j['thumbnail_url'] as String?,
        priceYen: (j['price_jpy'] as int?) ?? 0,
        lessonCount: (j['video_count'] as int?) ?? 0,
        level: 'intermediate',
        category: 'guard',
        rating: 0,
        reviewCount: 0,
      );
}
