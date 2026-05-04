import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../../../core/theme/app_theme.dart';

class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _descriptionExpanded = false;
  bool _isPurchased = false;
  final Set<int> _expandedLessons = {};

  @override
  void initState() {
    super.initState();
    _isPurchased = widget.course.isPurchased;
  }

  CourseModel get course => widget.course;

  String _categoryEmoji(String category) {
    switch (category) {
      case 'guard':
        return '🛡️';
      case 'passing':
        return '⚡';
      case 'submissions':
        return '🔒';
      case 'takedowns':
        return '🥋';
      case 'competition':
        return '🏆';
      default:
        return '📚';
    }
  }

  List<Color> _categoryGradient(String category) {
    switch (category) {
      case 'guard':
        return [const Color(0xFFDC2626), const Color(0xFF8B5CF6)];
      case 'passing':
        return [const Color(0xFF0EA5E9), const Color(0xFFDC2626)];
      case 'submissions':
        return [const Color(0xFFEF4444), const Color(0xFFEC4899)];
      case 'takedowns':
        return [const Color(0xFFF59E0B), const Color(0xFFEF4444)];
      case 'competition':
        return [const Color(0xFFF59E0B), const Color(0xFFEAB308)];
      default:
        return [const Color(0xFFDC2626), const Color(0xFFF97316)];
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.amber;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _buildLessons() {
    final lessons = <Map<String, dynamic>>[];
    for (int i = 1; i <= course.lessonCount; i++) {
      lessons.add({
        'index': i,
        'title': 'レッスン $i: ${_lessonTitle(i)}',
        'duration': '${8 + (i * 3) % 12}分',
        'isFree': i <= 3,
      });
    }
    return lessons;
  }

  String _lessonTitle(int index) {
    final titles = [
      'イントロダクション',
      '基本ポジション',
      'グリップワーク',
      '応用テクニック①',
      '応用テクニック②',
      'コンビネーション',
      'ドリル練習',
      'スパーリング解説',
      '実践応用',
      '総仕上げ',
      '試合での活用',
      'ボーナスレッスン',
    ];
    return titles[(index - 1) % titles.length];
  }

  Future<void> _showPurchaseDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          '購入確認',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              course.formattedPrice,
              style: const TextStyle(
                color: Color(0xFFF97316),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.credit_card),
                label: const Text('Stripe決済で購入'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF635BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'キャンセル',
              style: TextStyle(color: Color(0xFFA1A1AA)),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isPurchased = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('購入が完了しました！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = _buildLessons();
    final gradient = _categoryGradient(course.category);
    final levelColor = _levelColor(course.level);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero thumbnail
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    _categoryEmoji(course.category),
                    style: const TextStyle(fontSize: 72),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Course title
                Text(
                  course.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Instructor row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.3),
                      child: Text(
                        course.instructorName.substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.instructorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'インストラクター',
                            style: TextStyle(
                              color: Color(0xFFF97316),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rating
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      final full = i < course.rating.floor();
                      final half =
                          !full && i < course.rating && course.rating % 1 >= 0.5;
                      return Icon(
                        full
                            ? Icons.star
                            : half
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                    const SizedBox(width: 6),
                    Text(
                      course.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${course.reviewCount}件)',
                      style: const TextStyle(color: Color(0xFFA1A1AA)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick info row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoItem(
                        icon: Icons.play_circle_outline,
                        label: '${course.lessonCount}レッスン',
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: const Color(0xFF27272A),
                      ),
                      _InfoItem(
                        icon: Icons.signal_cellular_alt,
                        label: course.levelLabel,
                        color: levelColor,
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: const Color(0xFF27272A),
                      ),
                      _InfoItem(
                        icon: Icons.category_outlined,
                        label: course.categoryLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  '講座について',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedCrossFade(
                  firstChild: Text(
                    course.description,
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                      height: 1.6,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(
                    course.description,
                    style: const TextStyle(
                      color: Color(0xFFA1A1AA),
                      height: 1.6,
                    ),
                  ),
                  crossFadeState: _descriptionExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
                TextButton(
                  onPressed: () => setState(
                      () => _descriptionExpanded = !_descriptionExpanded),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _descriptionExpanded ? '閉じる' : 'もっと見る',
                    style: const TextStyle(color: Color(0xFFF97316)),
                  ),
                ),
                const SizedBox(height: 20),

                // Lesson list
                const Text(
                  'カリキュラム',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ...lessons.map((lesson) {
                  final idx = lesson['index'] as int;
                  final isFree = lesson['isFree'] as bool;
                  final isLocked = !isFree && !_isPurchased;
                  final isExpanded = _expandedLessons.contains(idx);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: isLocked
                          ? null
                          : () => setState(() {
                                if (isExpanded) {
                                  _expandedLessons.remove(idx);
                                } else {
                                  _expandedLessons.add(idx);
                                }
                              }),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isLocked
                                    ? const Color(0xFF27272A)
                                    : AppTheme.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isLocked
                                    ? const Text('🔒',
                                        style: TextStyle(fontSize: 12))
                                    : Text(
                                        '$idx',
                                        style: TextStyle(
                                          color: isLocked
                                              ? const Color(0xFF71717A)
                                              : AppTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson['title'] as String,
                                    style: TextStyle(
                                      color: isLocked
                                          ? const Color(0xFF71717A)
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'このレッスンではテクニックの詳細を学びます。実際の動きをスロー再生で確認しながら習得しましょう。',
                                        style: const TextStyle(
                                          color: Color(0xFFA1A1AA),
                                          fontSize: 12,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  lesson['duration'] as String,
                                  style: const TextStyle(
                                    color: Color(0xFFA1A1AA),
                                    fontSize: 11,
                                  ),
                                ),
                                if (isFree)
                                  const Text(
                                    '無料',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ]),
            ),
          ),
        ],
      ),

      // Bottom sticky bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(
            top: BorderSide(color: Color(0xFF27272A)),
          ),
        ),
        child: _isPurchased
            ? ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '受講を開始する',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            : Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '受講料',
                        style: TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        course.formattedPrice,
                        style: const TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: _showPurchaseDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '購入して受講する',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? const Color(0xFFF97316), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color ?? const Color(0xFFA1A1AA),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
