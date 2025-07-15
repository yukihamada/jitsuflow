/**
 * クラス詳細画面
 * 動画プレビュー、予約機能、レビュー表示
 */

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import '../../themes/colorful_theme.dart';
import '../../models/class_info.dart';
import '../../services/api_service.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassInfo classInfo;

  const ClassDetailScreen({
    super.key,
    required this.classInfo,
  });

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  final _apiService = ApiService();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isBooking = false;
  bool _isBooked = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _checkBookingStatus();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    if (widget.classInfo.previewVideoUrl != null) {
      try {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.classInfo.previewVideoUrl!),
        );
        
        await _videoController!.initialize();
        
        setState(() {
          _isVideoInitialized = true;
        });
      } catch (e) {
        print('Video initialization error: $e');
      }
    }
  }

  Future<void> _checkBookingStatus() async {
    try {
      final userId = await _apiService.getCurrentUserId();
      final response = await _apiService.get('/api/bookings/user/$userId');
      
      final bookings = response['bookings'] as List;
      final isAlreadyBooked = bookings.any((booking) => 
        booking['class_id'] == widget.classInfo.id
      );
      
      setState(() {
        _isBooked = isAlreadyBooked;
      });
    } catch (e) {
      // エラーは無視
    }
  }

  Future<void> _bookClass() async {
    if (_isBooked || _isBooking) return;

    setState(() => _isBooking = true);

    try {
      final userId = await _apiService.getCurrentUserId();
      
      await _apiService.post('/api/bookings/create', {
        'user_id': userId,
        'class_id': widget.classInfo.id,
        'dojo_id': 1, // デフォルト道場ID
        'booking_date': widget.classInfo.startTime.toIso8601String(),
        'booking_time': DateFormat('HH:mm').format(widget.classInfo.startTime),
      });

      setState(() {
        _isBooked = true;
        _isBooking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('予約が完了しました！'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isBooking = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('予約に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M月d日(E) HH:mm', 'ja_JP');
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ビデオプレビューAppBar
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildVideoPlayer(),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // シェア機能
                  },
                ),
              ),
            ],
          ),
          
          // クラス詳細コンテンツ
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // クラス基本情報
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // クラス名とタイプ
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.classInfo.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: ColorfulTheme.primaryGradient,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.classInfo.classTypeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // 日時と難易度
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 20,
                              color: ColorfulTheme.accentCyan,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              dateFormat.format(widget.classInfo.startTime),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ColorfulTheme.accentAmber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                widget.classInfo.difficultyLabel,
                                style: TextStyle(
                                  color: ColorfulTheme.accentAmber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 評価と定員
                        Row(
                          children: [
                            // 評価
                            Row(
                              children: [
                                ...List.generate(5, (index) {
                                  final isFilled = index < widget.classInfo.averageRating;
                                  return Icon(
                                    isFilled ? Icons.star : Icons.star_border,
                                    color: ColorfulTheme.accentAmber,
                                    size: 20,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.classInfo.averageRating.toStringAsFixed(1)} (${widget.classInfo.totalReviews})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            
                            const Spacer(),
                            
                            // 定員
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 20,
                                  color: ColorfulTheme.accentPurple,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.classInfo.currentStudents}/${widget.classInfo.maxStudents}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // インストラクター情報
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'インストラクター',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: ColorfulTheme.primaryGradient[1],
                              backgroundImage: widget.classInfo.instructorPhotoUrl != null
                                ? NetworkImage(widget.classInfo.instructorPhotoUrl!)
                                : null,
                              child: widget.classInfo.instructorPhotoUrl == null
                                ? Text(
                                    widget.classInfo.instructorName.substring(0, 1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.classInfo.instructorName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.classInfo.instructorBio,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // クラス説明
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'クラス内容',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.classInfo.description,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 技術タグ
                  if (widget.classInfo.techniques.isNotEmpty) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '学べる技術',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.classInfo.techniques.map((technique) {
                              final index = widget.classInfo.techniques.indexOf(technique);
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorfulTheme.getChipColor(index).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: ColorfulTheme.getChipColor(index),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  technique,
                                  style: TextStyle(
                                    color: ColorfulTheme.getChipColor(index),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 80), // 予約ボタン用スペース
                ],
              ),
            ),
          ),
        ],
      ),
      
      // 予約ボタン
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.classInfo.formattedPrice,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorfulTheme.primaryGradient[1],
                  ),
                ),
                Text(
                  '${widget.classInfo.duration}分',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _isBooked
                ? Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            '予約済み',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ColorfulTheme.gradientButton(
                    onPressed: widget.classInfo.currentStudents >= widget.classInfo.maxStudents
                      ? null
                      : _bookClass,
                    colors: widget.classInfo.currentStudents >= widget.classInfo.maxStudents
                      ? [Colors.grey, Colors.grey]
                      : ColorfulTheme.secondaryGradient,
                    child: _isBooking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.classInfo.currentStudents >= widget.classInfo.maxStudents
                            ? '満員'
                            : '予約する',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        color: Colors.black,
        child: widget.classInfo.thumbnailUrl != null
          ? Stack(
              children: [
                Image.network(
                  widget.classInfo.thumbnailUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.video_library,
                    size: 80,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'プレビュー動画',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
      );
    }

    return Stack(
      children: [
        VideoPlayer(_videoController!),
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.play_circle_fill,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}