/**
 * クラス情報モデル
 * 柔術クラスの詳細情報（動画、説明、インストラクター情報等）
 */

class ClassInfo {
  final int id;
  final String name;
  final String description;
  final String classType; // beginner, intermediate, advanced, open_mat, competition
  final int instructorId;
  final String instructorName;
  final String instructorBio;
  final String? instructorPhotoUrl;
  final String? previewVideoUrl;
  final String? thumbnailUrl;
  final int duration; // 分
  final int maxStudents;
  final int currentStudents;
  final List<String> techniques; // 練習する技術
  final String difficulty; // beginner, intermediate, advanced
  final double averageRating;
  final int totalReviews;
  final List<ClassReview> reviews;
  final DateTime startTime;
  final DateTime endTime;
  final bool isRecurring;
  final String? recurringPattern; // weekly, daily, etc.
  final double price;
  final bool isPremiumOnly;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.classType,
    required this.instructorId,
    required this.instructorName,
    required this.instructorBio,
    this.instructorPhotoUrl,
    this.previewVideoUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.maxStudents,
    required this.currentStudents,
    required this.techniques,
    required this.difficulty,
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
    required this.startTime,
    required this.endTime,
    required this.isRecurring,
    this.recurringPattern,
    required this.price,
    required this.isPremiumOnly,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      classType: json['class_type'] ?? 'open_mat',
      instructorId: json['instructor_id'],
      instructorName: json['instructor_name'] ?? '',
      instructorBio: json['instructor_bio'] ?? '',
      instructorPhotoUrl: json['instructor_photo_url'],
      previewVideoUrl: json['preview_video_url'],
      thumbnailUrl: json['thumbnail_url'],
      duration: json['duration'] ?? 60,
      maxStudents: json['max_students'] ?? 20,
      currentStudents: json['current_students'] ?? 0,
      techniques: List<String>.from(json['techniques'] ?? []),
      difficulty: json['difficulty'] ?? 'beginner',
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      reviews: (json['reviews'] as List?)
          ?.map((r) => ClassReview.fromJson(r))
          .toList() ?? [],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      isRecurring: json['is_recurring'] == 1 || json['is_recurring'] == true,
      recurringPattern: json['recurring_pattern'],
      price: (json['price'] ?? 0).toDouble(),
      isPremiumOnly: json['is_premium_only'] == 1 || json['is_premium_only'] == true,
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'class_type': classType,
      'instructor_id': instructorId,
      'instructor_name': instructorName,
      'instructor_bio': instructorBio,
      'instructor_photo_url': instructorPhotoUrl,
      'preview_video_url': previewVideoUrl,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'max_students': maxStudents,
      'current_students': currentStudents,
      'techniques': techniques,
      'difficulty': difficulty,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_recurring': isRecurring,
      'recurring_pattern': recurringPattern,
      'price': price,
      'is_premium_only': isPremiumOnly,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // クラスタイプの日本語名
  String get classTypeLabel {
    switch (classType) {
      case 'beginner':
        return '初心者クラス';
      case 'intermediate':
        return '中級者クラス';
      case 'advanced':
        return '上級者クラス';
      case 'open_mat':
        return 'オープンマット';
      case 'competition':
        return '競技クラス';
      case 'gi':
        return '道着クラス';
      case 'no_gi':
        return 'ノーギクラス';
      default:
        return classType;
    }
  }

  // 難易度の日本語名
  String get difficultyLabel {
    switch (difficulty) {
      case 'beginner':
        return '初級';
      case 'intermediate':
        return '中級';
      case 'advanced':
        return '上級';
      default:
        return difficulty;
    }
  }

  // 空き状況
  String get availabilityStatus {
    if (currentStudents >= maxStudents) {
      return '満員';
    } else if (currentStudents >= maxStudents * 0.8) {
      return '残りわずか';
    } else {
      return '空きあり';
    }
  }

  // 価格表示
  String get formattedPrice {
    if (price == 0) {
      return '無料';
    }
    return '¥${price.toStringAsFixed(0)}';
  }

  // 評価の星表示用
  List<bool> get ratingStars {
    final fullStars = averageRating.floor();
    final hasHalfStar = (averageRating - fullStars) >= 0.5;
    
    final stars = <bool>[];
    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(true);
      } else if (i == fullStars && hasHalfStar) {
        stars.add(true); // 半星として扱う
      } else {
        stars.add(false);
      }
    }
    return stars;
  }
}

// クラスレビューモデル
class ClassReview {
  final int id;
  final int classId;
  final int userId;
  final String userName;
  final String? userPhotoUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ClassReview({
    required this.id,
    required this.classId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ClassReview.fromJson(Map<String, dynamic> json) {
    return ClassReview(
      id: json['id'],
      classId: json['class_id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      userPhotoUrl: json['user_photo_url'],
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_id': classId,
      'user_id': userId,
      'user_name': userName,
      'user_photo_url': userPhotoUrl,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// クラススケジュール（カレンダー表示用）
class ClassSchedule {
  final DateTime date;
  final List<ClassInfo> classes;

  ClassSchedule({
    required this.date,
    required this.classes,
  });

  // その日にクラスがあるかどうか
  bool get hasClasses => classes.isNotEmpty;

  // その日のクラス数
  int get classCount => classes.length;

  // その日の主要なクラスタイプ
  String get primaryClassType {
    if (classes.isEmpty) return '';
    
    final typeCounts = <String, int>{};
    for (final classInfo in classes) {
      typeCounts[classInfo.classType] = (typeCounts[classInfo.classType] ?? 0) + 1;
    }
    
    return typeCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}