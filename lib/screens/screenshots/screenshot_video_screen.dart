import 'package:flutter/material.dart';
import '../../themes/colorful_theme.dart';
import '../../models/video.dart';

class ScreenshotVideoScreen extends StatelessWidget {
  const ScreenshotVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final videos = [
      Video(
        id: '1',
        title: 'クローズドガードの基本',
        description: '初心者向けの基本的なクローズドガードの作り方と維持方法',
        thumbnailUrl: '',
        uploadUrl: '',
        duration: '13:20',
        instructorName: '村田良蔵',
        isPremium: false,
        createdAt: DateTime.now(),
      ),
      Video(
        id: '2',
        title: 'ベリンボロシステム完全解説',
        description: '上級者向けのベリンボロシステムの詳細解説',
        thumbnailUrl: '',
        uploadUrl: '',
        duration: '45:30',
        instructorName: '村田良蔵',
        isPremium: true,
        createdAt: DateTime.now(),
      ),
      Video(
        id: '3',
        title: 'パスガードの基本動作',
        description: '効果的なパスガードの基本的な動きとコンセプト',
        thumbnailUrl: '',
        uploadUrl: '',
        duration: '18:45',
        instructorName: '廣鰭翔大',
        isPremium: false,
        createdAt: DateTime.now(),
      ),
      Video(
        id: '4',
        title: 'デラヒーバガード攻略法',
        description: 'デラヒーバガードの仕組みと攻略テクニック',
        thumbnailUrl: '',
        uploadUrl: '',
        duration: '22:15',
        instructorName: '諸澤陽斗',
        isPremium: true,
        createdAt: DateTime.now(),
      ),
      Video(
        id: '5',
        title: 'エスケープ基礎講座',
        description: '各ポジションからの基本的なエスケープ方法',
        thumbnailUrl: '',
        uploadUrl: '',
        duration: '16:30',
        instructorName: '松本志',
        isPremium: false,
        createdAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          '技術動画',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return _buildVideoCard(video);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[900],
        selectedItemColor: const Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '予約',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_outline),
            label: '動画',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'ショップ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'アカウント',
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Video video) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // サムネイル
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: video.isPremium
                        ? [Colors.purple.shade800, Colors.purple.shade600]
                        : [Colors.green.shade800, Colors.green.shade600],
                  ),
                ),
                child: Center(
                  child: Icon(
                    video.isPremium ? Icons.lock : Icons.play_circle_outline,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              if (video.isPremium)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'プレミアム',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.duration,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          // ビデオ情報
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video.instructorName,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  video.description,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}