import 'package:json_annotation/json_annotation.dart';

part 'video.g.dart';

@JsonSerializable()
class Video {
  final String id;
  final String title;
  final String description;
  final bool isPremium;
  final String? category;
  final String? uploadUrl;
  final String? thumbnailUrl;
  final int? duration;
  final int? views;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Video({
    required this.id,
    required this.title,
    required this.description,
    required this.isPremium,
    this.category,
    this.uploadUrl,
    this.thumbnailUrl,
    this.duration,
    this.views,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);

  Map<String, dynamic> toJson() => _$VideoToJson(this);

  Video copyWith({
    String? id,
    String? title,
    String? description,
    bool? isPremium,
    String? category,
    String? uploadUrl,
    String? thumbnailUrl,
    int? duration,
    int? views,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Video(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isPremium: isPremium ?? this.isPremium,
      category: category ?? this.category,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      views: views ?? this.views,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}