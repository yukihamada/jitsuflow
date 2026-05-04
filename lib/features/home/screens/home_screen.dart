import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../news/models/news_model.dart';

final _homeApiClient = ApiClient();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<NewsModel>? _news;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final data = await _homeApiClient.fetchNews();
    if (mounted) setState(() => _news = data.take(3).toList());
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'おはようございます';
    if (hour < 18) return 'こんにちは';
    return 'こんばんは';
  }

  String _dateLabel() {
    final now = DateTime.now();
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final wd = weekdays[now.weekday - 1];
    return '${now.month}月${now.day}日（$wd）';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFDC2626),
          backgroundColor: const Color(0xFF18181B),
          onRefresh: _loadNews,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildHeroCard(context),
              const SizedBox(height: 20),
              _buildSecondaryCards(context),
              const SizedBox(height: 28),
              _buildQuickMenu(context),
              const SizedBox(height: 28),
              _buildRecentNews(context),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _dateLabel(),
              style: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
            ),
          ],
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFDC2626).withValues(alpha: 0.3),
            ),
          ),
          child: const Center(
            child: Text('JF',
                style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/technique-flow'),
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🔵 良蔵システム',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'テクニックフロー',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '95のノード、130+のつながりを探索',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '開く',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, color: Colors.white.withValues(alpha: 0.9), size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SmallCard(
                icon: Icons.play_circle_filled,
                label: '動画',
                subtitle: '200+ テクニック',
                color: const Color(0xFF1E1B4B),
                iconColor: const Color(0xFF818CF8),
                onTap: () => context.go('/videos'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SmallCard(
                icon: Icons.assignment,
                label: 'ゲームプラン',
                subtitle: '戦略を構築',
                color: const Color(0xFF052E16),
                iconColor: const Color(0xFF4ADE80),
                onTap: () => context.push('/game-plans'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WideCard(
          icon: Icons.menu_book_rounded,
          label: '練習日誌',
          subtitle: '練習を記録・振り返る',
          color: const Color(0xFF3B0000),
          iconColor: const Color(0xFFDC2626),
          onTap: () => context.push('/training-journal'),
        ),
      ],
    );
  }

  Widget _buildQuickMenu(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'メニュー',
          style: TextStyle(
            color: Color(0xFF52525B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Column(
            children: [
              _MenuRow(Icons.sports_martial_arts, '道場を探す', () => context.push('/dojos')),
              _divider(),
              _MenuRow(Icons.people, 'コミュニティ', () => context.push('/community')),
              _divider(),
              _MenuRow(Icons.school, 'インストラクター', () => context.push('/instructors')),
              _divider(),
              _MenuRow(Icons.newspaper, 'ニュース', () => context.push('/news')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Divider(
        color: Color(0xFF27272A),
        height: 1,
        indent: 54,
      );

  String _formatNewsDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.month}月${dt.day}日';
  }

  Widget _buildRecentNews(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ニュース',
              style: TextStyle(
                color: Color(0xFF52525B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/news'),
              child: const Text(
                'すべて見る →',
                style: TextStyle(color: Color(0xFFDC2626), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_news == null)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: Color(0xFFDC2626), strokeWidth: 2),
            ),
          )
        else if (_news!.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: const Center(
              child: Text('ニュースはまだありません', style: TextStyle(color: Color(0xFF52525B), fontSize: 14)),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              children: List.generate(_news!.length, (i) {
                final item = _news![i];
                return Column(
                  children: [
                    InkWell(
                      onTap: () => context.push('/news'),
                      borderRadius: BorderRadius.circular(i == 0
                          ? 14
                          : i == _news!.length - 1
                              ? 14
                              : 0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatNewsDate(item.publishedAt),
                              style: const TextStyle(color: Color(0xFF52525B), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < _news!.length - 1)
                      const Divider(color: Color(0xFF27272A), height: 1, indent: 16),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _SmallCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _SmallCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: iconColor.withValues(alpha: 0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _WideCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: iconColor.withValues(alpha: 0.7), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: iconColor.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow(this.icon, this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFFA1A1AA)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF3F3F46), size: 18),
          ],
        ),
      ),
    );
  }
}
