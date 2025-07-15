import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/demo_auth.dart';
import '../../services/api_service.dart';
import '../../models/video.dart';
import '../members/members_screen.dart';
import '../dojo_mode/dojo_mode_screen.dart';
import '../shop/shop_screen.dart';
import '../rental/user_rental_screen.dart';
import '../booking/calendar_booking_screen.dart';
import '../../themes/colorful_theme.dart';
import '../messages/messages_screen.dart';
import '../guest/guest_home_screen.dart';

class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  String? userName;
  String userType = 'member';
  int _currentIndex = 0;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Set<int> selectedSchedules = <int>{};
  bool isSelectionMode = false;
  
  // Skill assessment data
  Map<String, int> _skillRatings = {
    '引き込み': 4,
    'ガードビルド': 5,
    'オープンガード': 4,
    'ブルガードスタンド': 3,
    'ガードチェンジ：クローズド': 5,
    'クローズドガード三角': 5,
    'クローズドガードスィープ': 4,
    'オープンガード三角': 4,
    'オープンガードスィープ': 5,
    'オモプラッタサイド': 3,
    'サイドコントロール': 5,
    'サイドサブミッション': 4,
    'マウント移行': 4,
    'マウントキープ': 3,
    'マウントサブミッション': 5,
  };

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadUserType();
  }

  Future<void> _loadUserName() async {
    final name = await DemoAuth.getCurrentUserName();
    setState(() {
      userName = name ?? 'ユーザー';
    });
  }
  
  Future<void> _loadUserType() async {
    final type = await DemoAuth.getCurrentUserType();
    if (mounted) {
      setState(() {
        userType = type;
      });
      
      // ゲストユーザーの場合はゲスト専用画面へリダイレクト
      if (type == 'guest') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GuestHomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _getScreens(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF1B5E20),
        unselectedItemColor: Colors.grey,
        items: _getNavItems(),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ColorfulTheme.gradientBackground(
          child: AppBar(
            title: const Text('JitsuFlow'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sports_martial_arts,
                      size: 50,
                      color: Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'おかえりなさい、${userName ?? 'ユーザー'}さん！',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '今日も練習を始めましょう',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.add_circle,
                    title: '予約する',
                    subtitle: '道場を予約',
                    colorIndex: 0,
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.play_circle_fill,
                    title: '動画を見る',
                    subtitle: '技術動画',
                    colorIndex: 1,
                    onTap: () {
                      setState(() {
                        _currentIndex = 2;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.shopping_bag,
                    title: 'ショップ',
                    subtitle: '道着・用品購入',
                    colorIndex: 2,
                    onTap: () {
                      setState(() {
                        _currentIndex = 3;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.inventory,
                    title: 'レンタル',
                    subtitle: '道着・防具',
                    colorIndex: 3,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserRentalScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Skill Assessment Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.analytics,
                          color: Color(0xFF1B5E20),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '技術評価',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _showEditSkillsDialog,
                          child: const Text('編集'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...(_getSkillAssessments().map((skill) => _buildSkillRow(skill)).toList()),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Color(0xFF1B5E20),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '総合スコア: ${_getTotalScore()}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int? colorIndex,
  }) {
    final index = colorIndex ?? title.hashCode % 6;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorfulTheme.getChipColor(index).withOpacity(0.15),
            ColorfulTheme.getChipColor(index).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorfulTheme.getChipColor(index).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ColorfulTheme.getChipColor(index).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorfulTheme.getChipColor(index).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: ColorfulTheme.getChipColor(index),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorfulBookingTab() {
    return const CalendarBookingScreen();
  }

  Widget _buildBookingTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予約'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          if (userName == '管理者')
            IconButton(
              icon: const Icon(Icons.add_business),
              onPressed: _showAddScheduleDialog,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search and filter section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '検索・フィルタ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              labelText: '道場',
                            ),
                            hint: const Text('全ての道場'),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('全ての道場')),
                              DropdownMenuItem(value: 'yawara', child: Text('YAWARA (原宿)')),
                              DropdownMenuItem(value: 'overlimit', child: Text('Over Limit (札幌)')),
                              DropdownMenuItem(value: 'sweep', child: Text('スイープ (北参道)')),
                            ],
                            onChanged: (value) {
                              // Handle dojo filter
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                              labelText: 'インストラクター',
                            ),
                            hint: const Text('全て'),
                            items: const [
                              DropdownMenuItem(value: null, child: Text('全て')),
                              DropdownMenuItem(value: 'murata', child: Text('Ryozo Murata')),
                              DropdownMenuItem(value: 'sweep_instructor', child: Text('スイープインストラクター')),
                              DropdownMenuItem(value: 'female', child: Text('女性インストラクター')),
                            ],
                            onChanged: (value) {
                              // Handle instructor filter
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Class schedule list
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '今週のクラススケジュール',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (isSelectionMode) ...[
                            Text(
                              '${selectedSchedules.length}件選択',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selectedSchedules.isNotEmpty 
                                ? () => _bookMultipleSchedules()
                                : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('まとめて予約'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  isSelectionMode = false;
                                  selectedSchedules.clear();
                                });
                              },
                            ),
                          ] else
                            IconButton(
                              icon: const Icon(Icons.checklist),
                              onPressed: () {
                                setState(() {
                                  isSelectionMode = true;
                                });
                              },
                              tooltip: '複数選択',
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _getWeeklySchedule().length,
                          itemBuilder: (context, index) {
                            final schedule = _getWeeklySchedule()[index];
                            final isSelected = selectedSchedules.contains(schedule['id'] as int);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              color: isSelected ? Colors.green.withOpacity(0.1) : null,
                              child: ListTile(
                                leading: isSelectionMode 
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedSchedules.add(schedule['id'] as int);
                                          } else {
                                            selectedSchedules.remove(schedule['id'] as int);
                                          }
                                        });
                                      },
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B5E20).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            schedule['day'] as String,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            schedule['date'] as String,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                title: Text(
                                  schedule['className'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${schedule['time']} - ${schedule['instructor']}',
                                      style: const TextStyle(fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${schedule['level']} | 定員: ${schedule['capacity']}名',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: isSelectionMode 
                                  ? null
                                  : userName == '管理者'
                                    ? PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showEditScheduleDialog(schedule);
                                          } else if (value == 'delete') {
                                            _showDeleteScheduleDialog(schedule['id'] as int);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit),
                                                SizedBox(width: 8),
                                                Text('編集'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('削除', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : ElevatedButton(
                                        onPressed: (schedule['available'] as bool)
                                          ? () => _showBookingDialog(schedule)
                                          : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1B5E20),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          (schedule['available'] as bool) ? '予約' : '満員',
                                        ),
                                      ),
                                onTap: isSelectionMode
                                  ? () {
                                      setState(() {
                                        if (isSelected) {
                                          selectedSchedules.remove(schedule['id'] as int);
                                        } else {
                                          selectedSchedules.add(schedule['id'] as int);
                                        }
                                      });
                                    }
                                  : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getWeeklySchedule() {
    final now = DateTime.now();
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    
    return [
      {
        'id': 1,
        'day': '月',
        'date': '${now.day}',
        'className': 'ベーシッククラス',
        'time': '19:00-20:30',
        'instructor': '村田良蔵',
        'level': '初級',
        'capacity': 20,
        'booked': 15,
        'available': true,
      },
      {
        'id': 2,
        'day': '火',
        'date': '${now.day + 1}',
        'className': 'アドバンスクラス',
        'time': '19:00-20:30',
        'instructor': '諸澤陽斗',
        'level': '上級',
        'capacity': 15,
        'booked': 12,
        'available': true,
      },
      {
        'id': 3,
        'day': '水',
        'date': '${now.day + 2}',
        'className': 'オープンクラス',
        'time': '19:00-20:30',
        'instructor': '佐藤正幸',
        'level': '全レベル',
        'capacity': 25,
        'booked': 20,
        'available': true,
      },
      {
        'id': 4,
        'day': '木',
        'date': '${now.day + 3}',
        'className': 'レディースクラス',
        'time': '19:00-20:30',
        'instructor': '堰本祐希',
        'level': '女性限定',
        'capacity': 15,
        'booked': 15,
        'available': false,
      },
      {
        'id': 5,
        'day': '金',
        'date': '${now.day + 4}',
        'className': 'コンペティションクラス',
        'time': '19:00-20:30',
        'instructor': '村田良蔵',
        'level': '試合向け',
        'capacity': 12,
        'booked': 8,
        'available': true,
      },
      {
        'id': 6,
        'day': '土',
        'date': '${now.day + 5}',
        'className': 'キッズクラス',
        'time': '14:00-15:30',
        'instructor': '立石修也',
        'level': '子供向け',
        'capacity': 20,
        'booked': 16,
        'available': true,
      },
      {
        'id': 7,
        'day': '日',
        'date': '${now.day + 6}',
        'className': 'SWEEPベーシック',
        'time': '20:00-21:30',
        'instructor': '廣鰭翔大',
        'level': '初級',
        'capacity': 15,
        'booked': 8,
        'available': true,
      },
      {
        'id': 8,
        'day': '月',
        'date': '${now.day + 7}',
        'className': 'YAWARAなでしこ',
        'time': '18:00-19:30',
        'instructor': '濱田真亮',
        'level': '女性限定',
        'capacity': 12,
        'booked': 9,
        'available': true,
      },
    ];
  }

  Widget _buildVideoTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('動画'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: _isUploading ? null : _pickAndUploadVideo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Upload Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.upload_file,
                      size: 40,
                      color: Color(0xFF1B5E20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '動画をアップロード',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '技術動画を共有して学習をサポートしましょう',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _pickAndUploadVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                      ),
                      child: _isUploading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('動画選択'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Upload Progress
            if (_isUploading) ...[
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'アップロード中...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_uploadProgress * 100).toInt()}% 完了',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Video Library
            Expanded(
              child: FutureBuilder<List<Video>>(
                future: ApiService.getVideos(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('動画の取得に失敗しました: ${snapshot.error}'),
                        ],
                      ),
                    );
                  }
                  
                  final videos = snapshot.data ?? [];
                  
                  if (videos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text('動画がまだありません'),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      final video = videos[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: video.thumbnailUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                video.thumbnailUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.play_circle_fill,
                                    color: Color(0xFF1B5E20),
                                    size: 30,
                                  ),
                              ),
                            )
                          : const Icon(
                              Icons.play_circle_fill,
                              color: Color(0xFF1B5E20),
                              size: 30,
                            ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              video.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (video.isPremium)
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(video.description),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                video.category ?? '未分類',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                video.duration != null 
                                  ? '${(video.duration! ~/ 60)}:${(video.duration! % 60).toString().padLeft(2, '0')}'
                                  : '不明',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              if (video.views != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${video.views}回再生',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: userName == '管理者'
                          ? PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'unpublish') {
                                  _showUnpublishDialog(video.title);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'unpublish',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility_off),
                                      SizedBox(width: 8),
                                      Text('非公開にする'),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : null,
                      onTap: () {
                        _showVideoPlayer(video);
                      },
                    ),
                  );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF1B5E20),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      userName ?? 'ユーザー',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'プレミアム会員',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('総予約数', '28'),
                        _buildStatCard('参加チーム', '2'),
                        _buildStatCard('視聴動画', '15'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment Management Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.payment,
                          color: Color(0xFF1B5E20),
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '支払い管理',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B5E20).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '現在のプラン',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'アクティブ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'プレミアムプラン',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '複数道場プラン - 全道場利用可能 + 動画見放題',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '次回請求日: 2024年8月15日',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _showPlanChangeDialog,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1B5E20)),
                              foregroundColor: const Color(0xFF1B5E20),
                            ),
                            child: const Text('プラン変更'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _showPaymentHistoryDialog,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1B5E20)),
                              foregroundColor: const Color(0xFF1B5E20),
                            ),
                            child: const Text('支払い履歴'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Settings
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.edit,
                    title: 'プロフィール編集',
                    subtitle: '名前、電話番号等を変更',
                    onTap: _showEditProfileDialog,
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.history,
                    title: '予約履歴',
                    subtitle: '過去の予約とキャンセル',
                    onTap: _showBookingHistoryDialog,
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.group,
                    title: 'チーム管理',
                    subtitle: '参加チーム・チーム作成',
                    onTap: _showTeamManagementDialog,
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.location_on,
                    title: '所属道場管理',
                    subtitle: 'メイン道場・追加道場設定',
                    onTap: _showDojoAffiliationsDialog,
                  ),
                  const Divider(height: 1),
                  _buildMenuTile(
                    icon: Icons.notifications,
                    title: '通知設定',
                    subtitle: 'プッシュ通知・メール設定',
                    onTap: _showNotificationSettingsDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Admin Section (temporarily available for all users for testing)
            // if (userName == '管理者') ...[  
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.admin_panel_settings,
                      title: '管理者メニュー',
                      subtitle: 'システム管理機能',
                      trailing: const Icon(Icons.verified_user, color: Color(0xFF1B5E20)),
                      onTap: null,
                      enabled: false,
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.people_alt,
                      title: 'メンバー管理',
                      subtitle: '全メンバーの管理・編集',
                      onTap: () {
                        try {
                          print('Navigating to MembersScreen...');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MembersScreen(),
                            ),
                          ).catchError((error) {
                            print('Navigation error: $error');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('エラー: $error')),
                            );
                          });
                        } catch (e) {
                          print('MembersScreen navigation error: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('メンバー画面を開けません: $e')),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    _buildMenuTile(
                      icon: Icons.store,
                      title: '道場モード',
                      subtitle: 'POS・レンタル・録画・経営分析',
                      onTap: () {
                        try {
                          print('Navigating to DojoModeScreen...');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DojoModeScreen(dojoId: 1),
                            ),
                          ).catchError((error) {
                            print('Navigation error: $error');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('エラー: $error')),
                            );
                          });
                        } catch (e) {
                          print('DojoModeScreen navigation error: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('道場モードを開けません: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            // ],
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text(
                  'ログアウト',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      // File picker for video
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        setState(() {
          _isUploading = true;
          _uploadProgress = 0.0;
        });

        // Start upload and AI analysis
        await _uploadAndAnalyzeVideo(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ファイル選択エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadAndAnalyzeVideo(PlatformFile file) async {
    try {
      // Simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _uploadProgress = i / 100;
        });
      }

      // Show AI analysis and editing dialog
      _showAIAnalysisDialog(file);

    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('アップロードエラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAIAnalysisDialog(PlatformFile file) {
    // AI generated suggestions (simulated)
    final aiSuggestions = {
      'title': '${file.name.split('.').first}のテクニック分析',
      'description': 'AI分析により、この動画ではガードポジションからのスイープテクニックが含まれていることを検出しました。',
      'category': 'スイープ',
      'detectedTechniques': ['クローズドガード', 'スイープ', 'トランジション'],
      'audioTranscript': '「今日はクローズドガードからのスイープについて説明します...」',
      'detectedFaces': [
        {
          'faceId': 'face_001',
          'personName': 'インストラクター田中',
          'confidence': 0.92,
          'timeStamps': [2.5, 15.3, 28.7]
        },
        {
          'faceId': 'face_002',
          'personName': '生徒A（匿名）',
          'confidence': 0.85,
          'timeStamps': [5.2, 22.1]
        }
      ],
      'deepfakeScore': 0.12,
    };

    final titleController = TextEditingController(text: aiSuggestions['title'] as String);
    final descriptionController = TextEditingController(text: aiSuggestions['description'] as String);
    String selectedCategory = aiSuggestions['category'] as String;
    bool isPremium = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF1B5E20)),
              const SizedBox(width: 8),
              const Text('AI分析結果'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  // Regenerate AI suggestions
                  setDialogState(() {
                    titleController.text = '${file.name}の柔術テクニック';
                    descriptionController.text = 'AI再分析により更新された説明文です。';
                  });
                },
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Detection Results
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🤖 AI検出結果',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('検出技術: ${(aiSuggestions['detectedTechniques'] as List).join(', ')}'),
                        const SizedBox(height: 4),
                        Text('音声テキスト: "${aiSuggestions['audioTranscript']}"'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Face Recognition Results
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '👤 顔認識結果',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.face_retouching_natural, color: Colors.purple),
                              onPressed: () => _showFaceMorphDialog(file),
                              tooltip: '顔変更',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...((aiSuggestions['detectedFaces'] as List).map((face) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• ${face['personName']} (信頼度: ${((face['confidence'] as double) * 100).toInt()}%)'),
                        )).toList()),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.security, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'DeepFake検出: ${((1 - (aiSuggestions['deepfakeScore'] as double)) * 100).toInt()}% 本物',
                              style: const TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Editable fields
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'タイトル (AI提案済み)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: '説明 (AI提案済み)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'カテゴリ (AI提案済み)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: const [
                      DropdownMenuItem(value: '基礎', child: Text('基礎')),
                      DropdownMenuItem(value: '上級', child: Text('上級')),
                      DropdownMenuItem(value: 'スイープ', child: Text('スイープ')),
                      DropdownMenuItem(value: 'サブミッション', child: Text('サブミッション')),
                      DropdownMenuItem(value: '試合', child: Text('試合')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('プレミアムコンテンツ'),
                    subtitle: const Text('有料会員のみ視聴可能'),
                    value: isPremium,
                    onChanged: (value) {
                      setDialogState(() {
                        isPremium = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isUploading = false;
                });
                Navigator.pop(context);
              },
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isUploading = false;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('「${titleController.text}」をアップロードしました'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              child: const Text('投稿する'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnpublishDialog(String videoTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('動画を非公開にする'),
        content: Text('「$videoTitle」を非公開にしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('「$videoTitle」を非公開にしました'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              '非公開にする',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }


  void _showAddScheduleDialog() {
    final classNameController = TextEditingController();
    final instructorController = TextEditingController();
    final capacityController = TextEditingController();
    String selectedDay = '月';
    String selectedTime = '19:00-20:30';
    String selectedLevel = '初級';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新しいクラスを追加'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: classNameController,
                    decoration: const InputDecoration(
                      labelText: 'クラス名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: const InputDecoration(
                      labelText: '曜日',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '月', child: Text('月曜日')),
                      DropdownMenuItem(value: '火', child: Text('火曜日')),
                      DropdownMenuItem(value: '水', child: Text('水曜日')),
                      DropdownMenuItem(value: '木', child: Text('木曜日')),
                      DropdownMenuItem(value: '金', child: Text('金曜日')),
                      DropdownMenuItem(value: '土', child: Text('土曜日')),
                      DropdownMenuItem(value: '日', child: Text('日曜日')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDay = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: const InputDecoration(
                      labelText: '時間',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '10:00-11:30', child: Text('10:00-11:30')),
                      DropdownMenuItem(value: '14:00-15:30', child: Text('14:00-15:30')),
                      DropdownMenuItem(value: '19:00-20:30', child: Text('19:00-20:30')),
                      DropdownMenuItem(value: '20:30-22:00', child: Text('20:30-22:00')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedTime = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: instructorController,
                    decoration: const InputDecoration(
                      labelText: 'インストラクター',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: const InputDecoration(
                      labelText: 'レベル',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '初級', child: Text('初級')),
                      DropdownMenuItem(value: '中級', child: Text('中級')),
                      DropdownMenuItem(value: '上級', child: Text('上級')),
                      DropdownMenuItem(value: '全レベル', child: Text('全レベル')),
                      DropdownMenuItem(value: '女性限定', child: Text('女性限定')),
                      DropdownMenuItem(value: '子供向け', child: Text('子供向け')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedLevel = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: capacityController,
                    decoration: const InputDecoration(
                      labelText: '定員',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (classNameController.text.isNotEmpty && 
                    instructorController.text.isNotEmpty &&
                    capacityController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('新しいクラス「${classNameController.text}」を追加しました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              child: const Text('追加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditScheduleDialog(Map<String, dynamic> schedule) {
    final classNameController = TextEditingController(text: schedule['className'] as String);
    final instructorController = TextEditingController(text: schedule['instructor'] as String);
    final capacityController = TextEditingController(text: schedule['capacity'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クラスを編集'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              TextField(
                controller: classNameController,
                decoration: const InputDecoration(
                  labelText: 'クラス名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instructorController,
                decoration: const InputDecoration(
                  labelText: 'インストラクター',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: capacityController,
                decoration: const InputDecoration(
                  labelText: '定員',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('クラス「${classNameController.text}」を更新しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  void _showDeleteScheduleDialog(int scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クラスを削除'),
        content: const Text('このクラスを削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('クラスを削除しました'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoPlayer(Video video) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: double.maxFinite,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      video.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (video.isPremium)
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Video player with actual video URL
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (video.uploadUrl != null) {
                        launchUrl(Uri.parse(video.uploadUrl!));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                        image: video.thumbnailUrl != null
                          ? DecorationImage(
                              image: NetworkImage(video.thumbnailUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.play_circle_fill,
                            size: 80,
                            color: Colors.white,
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Text(
                              'クリックで再生',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Video info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(video.category ?? '未分類'),
                          backgroundColor: const Color(0xFF1B5E20),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        if (video.isPremium)
                          const Chip(
                            label: Text('プレミアム'),
                            backgroundColor: Colors.amber,
                          ),
                        const Spacer(),
                        Text(
                          video.duration != null 
                            ? '${(video.duration! ~/ 60)}:${(video.duration! % 60).toString().padLeft(2, '0')}'
                            : '不明',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFaceMorphDialog(PlatformFile file) {
    String selectedMorphType = 'face_swap';
    double intensity = 0.5;
    String targetFace = 'face_001';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.face_retouching_natural, color: Colors.purple),
              const SizedBox(width: 8),
              const Text('顔変更機能'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '注意: この機能は研究・教育目的のみです。悪用は禁止されています。',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: selectedMorphType,
                  decoration: const InputDecoration(
                    labelText: '変更タイプ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'face_swap', child: Text('顔交換')),
                    DropdownMenuItem(value: 'age_progression', child: Text('年齢変更')),
                    DropdownMenuItem(value: 'expression_change', child: Text('表情変更')),
                    DropdownMenuItem(value: 'gender_swap', child: Text('性別変更')),
                    DropdownMenuItem(value: 'ethnicity_change', child: Text('民族性変更')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMorphType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                DropdownButtonFormField<String>(
                  value: targetFace,
                  decoration: const InputDecoration(
                    labelText: '対象の顔',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'face_001', child: Text('インストラクター田中')),
                    DropdownMenuItem(value: 'face_002', child: Text('生徒A（匿名）')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      targetFace = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                Text('変更強度: ${(intensity * 100).toInt()}%'),
                Slider(
                  value: intensity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (value) {
                    setDialogState(() {
                      intensity = value;
                    });
                  },
                ),
                
                const SizedBox(height: 16),
                
                if (intensity > 0.7)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠️ 高強度の変更は不自然に見える可能性があります',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processFaceMorph(selectedMorphType, targetFace, intensity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('変更開始'),
            ),
          ],
        ),
      ),
    );
  }

  void _processFaceMorph(String morphType, String targetFace, double intensity) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.purple),
            const SizedBox(height: 16),
            const Text('顔変更処理中...'),
            const SizedBox(height: 8),
            Text('処理時間: 約${(5 + intensity * 10).toInt()}秒'),
          ],
        ),
      ),
    );

    // Simulate processing
    Future.delayed(Duration(seconds: (5 + intensity * 10).toInt()), () {
      Navigator.pop(context); // Close processing dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('顔変更が完了しました（${(intensity * 100).toInt()}%強度）'),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  // Profile helper methods
  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
    bool enabled = true,
  }) {
    return ListTile(
      enabled: enabled,
      leading: Icon(
        icon,
        color: enabled ? const Color(0xFF1B5E20) : Colors.grey,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: enabled ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: enabled ? Colors.grey : Colors.grey[400],
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: enabled ? Colors.grey : Colors.grey[400],
      ),
      onTap: enabled ? onTap : null,
    );
  }

  // Skill assessment helper methods
  List<Map<String, dynamic>> _getSkillAssessments() {
    return _skillRatings.entries.map((entry) => {
      'name': entry.key,
      'rating': entry.value,
    }).toList();
  }
  
  int _getTotalScore() {
    return _skillRatings.values.fold(0, (sum, rating) => sum + rating);
  }
  
  Widget _buildSkillRow(Map<String, dynamic> skill) {
    final rating = skill['rating'] as int;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              skill['name'] as String,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating ? Icons.circle : Icons.circle_outlined,
                  size: 16,
                  color: index < rating 
                    ? const Color(0xFF1B5E20)
                    : Colors.grey[300],
                );
              }),
            ),
          ),
          SizedBox(
            width: 30,
            child: Text(
              '$rating',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showEditSkillsDialog() {
    final tempRatings = Map<String, int>.from(_skillRatings);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('技術評価を編集'),
          content: SizedBox(
            width: double.maxFinite,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                children: tempRatings.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(5, (index) {
                            final rating = index + 1;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setDialogState(() {
                                    tempRatings[entry.key] = rating;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: entry.value >= rating
                                      ? const Color(0xFF1B5E20)
                                      : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$rating',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: entry.value >= rating
                                        ? Colors.white
                                        : Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _skillRatings = tempRatings;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('技術評価を更新しました'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('検索・フィルタ'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'キーワード検索',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  hintText: 'クラス名、インストラクター名など',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  labelText: '道場',
                ),
                hint: const Text('全ての道場'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('全ての道場')),
                  DropdownMenuItem(value: 'yawara', child: Text('YAWARA (原宿)')),
                  DropdownMenuItem(value: 'overlimit', child: Text('Over Limit (札幌)')),
                  DropdownMenuItem(value: 'sweep', child: Text('スイープ (北参道)')),
                ],
                onChanged: (value) {
                  // Handle dojo filter
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                  labelText: 'インストラクター',
                ),
                hint: const Text('全て'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('全て')),
                  DropdownMenuItem(value: 'murata', child: Text('Ryozo Murata')),
                  DropdownMenuItem(value: 'sweep_instructor', child: Text('スイープインストラクター')),
                  DropdownMenuItem(value: 'female', child: Text('女性インストラクター')),
                ],
                onChanged: (value) {
                  // Handle instructor filter
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('フィルタを適用しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: const Text('検索'),
          ),
        ],
      ),
    );
  }

  void _bookMultipleSchedules() {
    if (selectedSchedules.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('まとめて予約'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${selectedSchedules.length}件のクラスを予約しますか？'),
            const SizedBox(height: 16),
            const Text(
              '選択されたクラス:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...selectedSchedules.map((scheduleId) {
              final schedule = _getWeeklySchedule().firstWhere(
                (s) => s['id'] == scheduleId,
                orElse: () => {'className': '不明', 'day': '', 'time': ''},
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${schedule['day']} ${schedule['className']} (${schedule['time']})'),
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isSelectionMode = false;
                selectedSchedules.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${selectedSchedules.length}件のクラスを予約しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: const Text('予約確定'),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('以下のクラスを予約しますか？'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule['className'] as String,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('日時: ${schedule['day']} ${schedule['time']}'),
                  Text('インストラクター: ${schedule['instructor']}'),
                  Text('レベル: ${schedule['level']}'),
                  Text('定員: ${schedule['capacity']}名 (予約済み: ${schedule['booked']}名)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('「${schedule['className']}」を予約しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: const Text('予約確定'),
          ),
        ],
      ),
    );
  }

  void _showPlanChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プラン変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPlanOption(
              title: '複数道場プラン',
              price: '各道場プラン料金 + 追加費用',
              features: ['全道場利用可能', '動画見放題', '優先予約'],
              isSelected: true,
            ),
            const SizedBox(height: 16),
            _buildPlanOption(
              title: '単一道場プラン',
              price: '¥8,000〜¥33,000/月',
              features: ['選択した道場のみ', 'プランにより動画利用可'],
              isSelected: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('プラン変更を受け付けました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: const Text('変更'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String price,
    required List<String> features,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF1B5E20) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF1B5E20),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(feature, style: const TextStyle(fontSize: 14)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _showPaymentHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支払い履歴'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: [
              _buildPaymentHistoryItem(
                date: '2024年7月15日',
                amount: '¥33,000',
                plan: 'YAWARAフルタイムプラン',
                status: '完了',
              ),
              _buildPaymentHistoryItem(
                date: '2024年6月15日',
                amount: '¥22,000',
                plan: 'Sweepプラン（月8回）',
                status: '完了',
              ),
              _buildPaymentHistoryItem(
                date: '2024年5月15日',
                amount: '¥12,000',
                plan: 'Over Limitフルタイム',
                status: '完了',
              ),
              _buildPaymentHistoryItem(
                date: '2024年4月15日',
                amount: '¥8,000',
                plan: 'Over Limitレディース&キッズ',
                status: '完了',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryItem({
    required String date,
    required String amount,
    required String plan,
    required String status,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(plan, style: const TextStyle(fontSize: 16)),
            Text(
              date,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: userName);
    final phoneController = TextEditingController(text: '090-1234-5678');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('プロフィール編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名前',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: '電話番号',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                userName = nameController.text;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('プロフィールを更新しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showBookingHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予約履歴'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: [
              _buildBookingHistoryItem(
                className: 'ベーシッククラス',
                dojo: 'Over Limit Sapporo',
                date: '7月20日(土)',
                time: '19:00-20:30',
                status: '予約済み',
                canCancel: true,
              ),
              _buildBookingHistoryItem(
                className: 'アドバンスクラス',
                dojo: 'Over Limit Sapporo',
                date: '7月18日(木)',
                time: '19:00-20:30',
                status: '完了',
                canCancel: false,
              ),
              _buildBookingHistoryItem(
                className: 'オープンクラス',
                dojo: 'スイープ',
                date: '7月15日(月)',
                time: '20:00-21:30',
                status: '完了',
                canCancel: false,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingHistoryItem({
    required String className,
    required String dojo,
    required String date,
    required String time,
    required String status,
    required bool canCancel,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  className,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == '予約済み' 
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == '予約済み' ? Colors.blue : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(dojo, style: const TextStyle(fontSize: 14)),
            Text('$date $time', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            if (canCancel) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  // Show cancel confirmation
                },
                child: const Text(
                  'キャンセル',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTeamManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チーム管理'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCreateTeamDialog();
                },
                icon: const Icon(Icons.add),
                label: const Text('新しいチーム作成'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '参加中のチーム',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    _buildTeamItem(
                      name: 'YAWARA競技チーム',
                      dojo: 'YAWARA JIU-JITSU ACADEMY',
                      role: '管理者',
                      members: 12,
                    ),
                    _buildTeamItem(
                      name: 'スイープ初心者の会',
                      dojo: 'スイープ',
                      role: 'メンバー',
                      members: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamItem({
    required String name,
    required String dojo,
    required String role,
    required int members,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1B5E20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(dojo, style: const TextStyle(fontSize: 14)),
            Text(
              '$membersメンバー',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamDialog() {
    final teamNameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedDojo = 'YAWARA JIU-JITSU ACADEMY';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新しいチーム作成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: teamNameController,
                decoration: const InputDecoration(
                  labelText: 'チーム名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'チーム説明',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedDojo,
                decoration: const InputDecoration(
                  labelText: '所属道場',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'YAWARA JIU-JITSU ACADEMY', child: Text('YAWARA')),
                  DropdownMenuItem(value: 'Over Limit Sapporo', child: Text('Over Limit')),
                  DropdownMenuItem(value: 'スイープ', child: Text('スイープ')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedDojo = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                if (teamNameController.text.isNotEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('チーム「${teamNameController.text}」を作成しました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDojoAffiliationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('所属道場管理'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '所属道場',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    _buildDojoAffiliationItem(
                      name: 'YAWARA JIU-JITSU ACADEMY',
                      address: '東京都渋谷区神宮前1-8-10',
                      isPrimary: true,
                      joinDate: '2024年1月15日',
                    ),
                    _buildDojoAffiliationItem(
                      name: 'スイープ',
                      address: '東京都渋谷区千駄ヶ谷3-55-12',
                      isPrimary: false,
                      joinDate: '2024年3月20日',
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // Show add dojo dialog
                },
                icon: const Icon(Icons.add),
                label: const Text('道場を追加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildDojoAffiliationItem({
    required String name,
    required String address,
    required bool isPrimary,
    required String joinDate,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'メイン',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(address, style: const TextStyle(fontSize: 14)),
            Text(
              '参加日: $joinDate',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettingsDialog() {
    bool pushNotifications = true;
    bool emailNotifications = false;
    bool bookingReminders = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('通知設定'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('プッシュ通知'),
                subtitle: const Text('アプリからの通知を受け取る'),
                value: pushNotifications,
                onChanged: (value) {
                  setDialogState(() {
                    pushNotifications = value;
                  });
                },
                activeColor: const Color(0xFF1B5E20),
              ),
              SwitchListTile(
                title: const Text('メール通知'),
                subtitle: const Text('メールでの通知を受け取る'),
                value: emailNotifications,
                onChanged: (value) {
                  setDialogState(() {
                    emailNotifications = value;
                  });
                },
                activeColor: const Color(0xFF1B5E20),
              ),
              SwitchListTile(
                title: const Text('予約リマインダー'),
                subtitle: const Text('クラス開始前の通知'),
                value: bookingReminders,
                onChanged: (value) {
                  setDialogState(() {
                    bookingReminders = value;
                  });
                },
                activeColor: const Color(0xFF1B5E20),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('通知設定を保存しました'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DemoAuth.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text(
              'ログアウト',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _getScreens() {
    if (userType == 'admin' || userType == 'member') {
      return [
        _buildHomeTab(),
        _buildColorfulBookingTab(),
        _buildVideoTab(),
        const MessagesScreen(),
        _buildProfileTab(),
      ];
    } else {
      return [
        _buildHomeTab(),
        _buildColorfulBookingTab(),
        _buildVideoTab(),
        const ShopScreen(),
        _buildProfileTab(),
      ];
    }
  }
  
  List<BottomNavigationBarItem> _getNavItems() {
    if (userType == 'admin') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'ホーム',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '予約',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle),
          label: '動画',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'メッセージ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: '管理',
        ),
      ];
    } else if (userType == 'member') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'ホーム',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '予約',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle),
          label: '動画',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'メッセージ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'アカウント',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'ホーム',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: '予約',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.play_circle),
          label: '動画',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: 'ショップ',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'アカウント',
        ),
      ];
    }
  }
}