import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_model.dart';

class VideoDetailScreen extends StatelessWidget {
  final VideoModel video;
  const VideoDetailScreen({super.key, required this.video});

  Future<void> _openVideo(BuildContext context) async {
    final url = video.videoUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('動画URLが見つかりません'), backgroundColor: Colors.red),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ブラウザを開けませんでした'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlayerPlaceholder(context),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (video.videoType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            video.videoType!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF27272A)),
                    ),
                    child: Row(
                      children: [
                        _infoItem(Icons.person, video.authorName ?? ''),
                        const SizedBox(width: 20),
                        _infoItem(
                          Icons.visibility,
                          _formatViews(video.viewCount),
                        ),
                        if (video.createdAt != null) ...[
                          const SizedBox(width: 20),
                          _infoItem(
                            Icons.calendar_today,
                            '${video.createdAt!.year}/${video.createdAt!.month}/${video.createdAt!.day}',
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (video.description != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '説明',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF18181B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF27272A)),
                      ),
                      child: Text(
                        video.description!,
                        style: const TextStyle(
                          color: Color(0xFFD4D4D8),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/technique-flow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'テクニックフローで見る',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerPlaceholder(BuildContext context) {
    final hasVideo = video.videoUrl != null && video.videoUrl!.isNotEmpty;
    return GestureDetector(
      onTap: hasVideo ? () => _openVideo(context) : null,
      child: Container(
        width: double.infinity,
        height: 220,
        color: const Color(0xFF18181B),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: video.videoType == 'ドキュメンタリー'
                  ? const Color(0xFF1E1B4B)
                  : const Color(0xFF1C1C2E),
            ),
            Icon(
              hasVideo ? Icons.play_circle_filled : Icons.video_library_outlined,
              color: hasVideo ? const Color(0xFFDC2626) : const Color(0xFF52525B),
              size: 72,
            ),
            if (hasVideo)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '▶ 動画を再生',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF71717A)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
        ),
      ],
    );
  }
}

String _formatViews(int? count) {
  if (count == null) return '';
  if (count >= 10000) return '${(count / 10000).toStringAsFixed(1)}万';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return '$count';
}
