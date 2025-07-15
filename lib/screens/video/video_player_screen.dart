import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../blocs/video/video_bloc.dart';
import '../../widgets/common/loading_widget.dart';
import '../../models/video.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isControlsVisible = true;

  @override
  void initState() {
    super.initState();
    context.read<VideoBloc>().add(VideoLoadByIdRequested(id: widget.videoId));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<VideoBloc, VideoState>(
        listener: (context, state) {
          if (state is VideoDetailSuccess) {
            _initializeVideo(state.video);
          } else if (state is VideoFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VideoLoading) {
            return const Center(
              child: LoadingWidget(
                color: Colors.white,
                size: 40,
              ),
            );
          }
          
          if (state is VideoFailure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'エラーが発生しました',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<VideoBloc>().add(
                        VideoLoadByIdRequested(id: widget.videoId),
                      );
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }
          
          if (state is VideoDetailSuccess) {
            return Column(
              children: [
                // Video Player
                Expanded(
                  flex: 3,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isControlsVisible = !_isControlsVisible;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              // Video placeholder or actual video
                              Center(
                                child: _controller != null &&
                                        _controller!.value.isInitialized
                                    ? VideoPlayer(_controller!)
                                    : Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(0xFF1B5E20).withOpacity(0.7),
                                              const Color(0xFF2E7D32).withOpacity(0.7),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.play_circle_fill,
                                                size: 80,
                                                color: Colors.white,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'デモ動画プレイヤー',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                              
                              // Controls overlay
                              if (_isControlsVisible)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.3),
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        // Top controls
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              if (state.video.isPremium)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'プレミアム',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        
                                        const Spacer(),
                                        
                                        // Play/Pause button
                                        IconButton(
                                          onPressed: () {
                                            if (_controller != null) {
                                              if (_controller!.value.isPlaying) {
                                                _controller!.pause();
                                              } else {
                                                _controller!.play();
                                              }
                                            }
                                          },
                                          icon: Icon(
                                            _controller != null && _controller!.value.isPlaying
                                                ? Icons.pause_circle_filled
                                                : Icons.play_circle_filled,
                                            size: 60,
                                            color: Colors.white,
                                          ),
                                        ),
                                        
                                        const Spacer(),
                                        
                                        // Bottom controls
                                        if (_controller != null && _controller!.value.isInitialized)
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: VideoProgressIndicator(
                                              _controller!,
                                              allowScrubbing: true,
                                              colors: const VideoProgressColors(
                                                playedColor: Color(0xFF1B5E20),
                                                bufferedColor: Colors.grey,
                                                backgroundColor: Colors.white24,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Video Info
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.video.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (state.video.category != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getCategoryName(state.video.category!),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF1B5E20),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (state.video.duration != null) ...[
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(state.video.duration!),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '動画の説明',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              state.video.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          
          return const SizedBox();
        },
      ),
    );
  }

  void _initializeVideo(Video video) {
    // In a real app, you would initialize the video player with the actual video URL
    // For demo purposes, we'll simulate a video player
    if (video.uploadUrl != null) {
      // _controller = VideoPlayerController.network(video.uploadUrl!)
      //   ..initialize().then((_) {
      //     setState(() {});
      //   });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'basics':
        return 'ベーシック';
      case 'advanced':
        return 'アドバンス';
      case 'submissions':
        return 'サブミッション';
      case 'competition':
        return 'コンペティション';
      default:
        return category;
    }
  }
}