import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/video.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc() : super(VideoInitial()) {
    on<VideoLoadRequested>(_onLoadRequested);
    on<VideoLoadByIdRequested>(_onLoadByIdRequested);
    on<VideoFilterRequested>(_onFilterRequested);
  }

  Future<void> _onLoadRequested(
    VideoLoadRequested event,
    Emitter<VideoState> emit,
  ) async {
    emit(VideoLoading());
    
    try {
      final videos = await ApiService.getVideos(premium: event.premium);
      emit(VideoLoadSuccess(videos: videos));
    } catch (e) {
      emit(VideoFailure(message: e.toString()));
    }
  }

  Future<void> _onLoadByIdRequested(
    VideoLoadByIdRequested event,
    Emitter<VideoState> emit,
  ) async {
    emit(VideoLoading());
    
    try {
      final video = await ApiService.getVideo(event.id);
      emit(VideoDetailSuccess(video: video));
    } catch (e) {
      emit(VideoFailure(message: e.toString()));
    }
  }

  Future<void> _onFilterRequested(
    VideoFilterRequested event,
    Emitter<VideoState> emit,
  ) async {
    emit(VideoLoading());
    
    try {
      final videos = await ApiService.getVideos(premium: event.premium);
      final filteredVideos = videos.where((video) {
        final matchesCategory = event.category == null || 
                               video.category == event.category;
        final matchesSearch = event.searchQuery == null || 
                             video.title.toLowerCase().contains(event.searchQuery!.toLowerCase()) ||
                             video.description.toLowerCase().contains(event.searchQuery!.toLowerCase());
        
        return matchesCategory && matchesSearch;
      }).toList();
      
      emit(VideoLoadSuccess(videos: filteredVideos));
    } catch (e) {
      emit(VideoFailure(message: e.toString()));
    }
  }
}