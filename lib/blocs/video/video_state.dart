part of 'video_bloc.dart';

abstract class VideoState extends Equatable {
  const VideoState();

  @override
  List<Object?> get props => [];
}

class VideoInitial extends VideoState {}

class VideoLoading extends VideoState {}

class VideoLoadSuccess extends VideoState {
  final List<Video> videos;

  const VideoLoadSuccess({required this.videos});

  @override
  List<Object> get props => [videos];
}

class VideoDetailSuccess extends VideoState {
  final Video video;

  const VideoDetailSuccess({required this.video});

  @override
  List<Object> get props => [video];
}

class VideoFailure extends VideoState {
  final String message;

  const VideoFailure({required this.message});

  @override
  List<Object> get props => [message];
}