part of 'video_bloc.dart';

abstract class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object?> get props => [];
}

class VideoLoadRequested extends VideoEvent {
  final bool? premium;

  const VideoLoadRequested({this.premium});

  @override
  List<Object?> get props => [premium];
}

class VideoLoadByIdRequested extends VideoEvent {
  final String id;

  const VideoLoadByIdRequested({required this.id});

  @override
  List<Object> get props => [id];
}

class VideoFilterRequested extends VideoEvent {
  final String? category;
  final String? searchQuery;
  final bool? premium;

  const VideoFilterRequested({
    this.category,
    this.searchQuery,
    this.premium,
  });

  @override
  List<Object?> get props => [category, searchQuery, premium];
}