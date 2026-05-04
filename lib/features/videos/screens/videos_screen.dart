import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../models/video_model.dart';
import 'video_detail_screen.dart';

final _apiClient = ApiClient();

const _filters = ['すべて', 'テクニック', 'ドキュメンタリー'];

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  String _selectedFilter = 'すべて';
  String _searchQuery = '';
  List<VideoModel>? _videos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final data = await _apiClient.fetchVideos();
    if (mounted) setState(() { _videos = data; _loading = false; });
  }

  List<VideoModel> get _filtered {
    final all = _videos ?? [];
    return all.where((v) {
      final matchFilter = _selectedFilter == 'すべて' ||
          v.videoType == _selectedFilter ||
          (v.videoType == 'technique' && _selectedFilter == 'テクニック') ||
          (v.videoType == 'documentary' && _selectedFilter == 'ドキュメンタリー');
      final q = _searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          v.title.toLowerCase().contains(q) ||
          (v.authorName?.toLowerCase().contains(q) ?? false);
      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('動画',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          _buildSearch(),
          _buildFilters(),
          const SizedBox(height: 8),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            hintText: '検索',
            hintStyle: TextStyle(color: Color(0xFF52525B), fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Color(0xFF52525B), size: 18),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _filters.map((f) {
          final selected = f == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFDC2626) : const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF71717A),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
    }

    final items = _filtered;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library_outlined, color: Color(0xFF3F3F46), size: 48),
            const SizedBox(height: 16),
            Text(
              _videos?.isEmpty == true ? '動画はまだありません' : '該当する動画がありません',
              style: const TextStyle(color: Color(0xFF52525B), fontSize: 15),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFDC2626),
      backgroundColor: const Color(0xFF18181B),
      onRefresh: _loadVideos,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(color: Color(0xFF1F1F23), height: 1),
        itemBuilder: (context, i) => _ApiVideoItem(video: items[i]),
      ),
    );
  }
}

class _ApiVideoItem extends StatelessWidget {
  final VideoModel video;
  const _ApiVideoItem({required this.video});

  String _formatViews(int v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(1)}万回';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K回';
    return '$v回';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VideoDetailScreen(video: video)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 100,
                height: 62,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF27272A), Color(0xFF3F3F46)],
                  ),
                ),
                child: video.thumbnailUrl != null
                    ? Image.network(video.thumbnailUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultThumb())
                    : _defaultThumb(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(video.authorName ?? '',
                          style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                      if (video.viewCount != null) ...[
                        const Text(' · ', style: TextStyle(color: Color(0xFF52525B), fontSize: 12)),
                        Text(_formatViews(video.viewCount!),
                            style: const TextStyle(color: Color(0xFF52525B), fontSize: 12)),
                      ],
                    ],
                  ),
                  if (video.videoType != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: video.videoType == 'documentary'
                            ? const Color(0xFF1E1B4B)
                            : const Color(0xFF1C0A0A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.videoType == 'documentary' ? 'ドキュメンタリー' : 'テクニック',
                        style: TextStyle(
                          color: video.videoType == 'documentary'
                              ? const Color(0xFF818CF8)
                              : const Color(0xFFDC2626),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultThumb() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.play_circle_outline, color: Color(0xFF71717A), size: 32),
        Positioned(
          bottom: 4,
          right: 4,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

