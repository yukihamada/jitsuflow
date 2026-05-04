class ForumThread {
  final String id;
  final String title;
  final String body;
  final String authorName;
  final String? authorAvatar;
  final int replyCount;
  final int viewCount;
  final DateTime createdAt;
  final String category; // 'technique', 'competition', 'gear', 'general'

  const ForumThread({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    this.authorAvatar,
    this.replyCount = 0,
    this.viewCount = 0,
    required this.createdAt,
    this.category = 'general',
  });

  factory ForumThread.fromJson(Map<String, dynamic> j) {
    // Map server categories (Japanese) to app categories
    final serverCat = j['category'] as String? ?? '';
    String cat;
    switch (serverCat) {
      case 'テクニック':
        cat = 'technique';
        break;
      case '大会':
        cat = 'competition';
        break;
      case '道場':
        cat = 'gear';
        break;
      case '初心者':
        cat = 'general';
        break;
      default:
        cat = 'general';
    }
    return ForumThread(
      id: j['id'] ?? '',
      title: j['title'] ?? '',
      body: j['body'] ?? '',
      authorName: j['display_name'] ?? '匿名',
      replyCount: (j['reply_count'] as num?)?.toInt() ?? 0,
      viewCount: 0,
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      category: cat,
    );
  }
}

class ForumReply {
  final String id;
  final String threadId;
  final String body;
  final String authorName;
  final DateTime createdAt;

  const ForumReply({
    required this.id,
    required this.threadId,
    required this.body,
    required this.authorName,
    required this.createdAt,
  });
}
