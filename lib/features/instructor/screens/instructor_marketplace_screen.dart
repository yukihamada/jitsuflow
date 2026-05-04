import 'package:flutter/material.dart';
import '../models/course_model.dart';
import 'course_detail_screen.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

final _apiClient = ApiClient();

class InstructorMarketplaceScreen extends StatefulWidget {
  const InstructorMarketplaceScreen({super.key});

  @override
  State<InstructorMarketplaceScreen> createState() =>
      _InstructorMarketplaceScreenState();
}

class _InstructorMarketplaceScreenState
    extends State<InstructorMarketplaceScreen> {
  String _selectedCategory = 'all';
  String? _selectedLevel;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<CourseModel>? _courses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _apiClient.fetchInstructors();
    if (mounted) setState(() => _courses = data);
  }

  static const _categories = [
    ('all', 'すべて'),
    ('guard', 'ガード'),
    ('passing', 'パス'),
    ('submissions', 'サブミッション'),
    ('takedowns', 'テイクダウン'),
    ('competition', '試合対策'),
  ];

  static const _levels = [
    ('beginner', '初心者'),
    ('intermediate', '中級者'),
    ('advanced', '上級者'),
  ];

  List<CourseModel> get _filteredCourses {
    final all = _courses ?? [];
    return all.where((c) {
      final matchCategory =
          _selectedCategory == 'all' || c.category == _selectedCategory;
      final matchLevel =
          _selectedLevel == null || c.level == _selectedLevel;
      final matchSearch = _searchQuery.isEmpty ||
          c.title.contains(_searchQuery) ||
          c.instructorName.contains(_searchQuery);
      return matchCategory && matchLevel && matchSearch;
    }).toList();
  }

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_courses == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF09090B),
        appBar: AppBar(title: const Text('インストラクター講座')),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626))),
      );
    }

    final filtered = _filteredCourses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('インストラクター講座'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '講座・インストラクターを検索',
                hintStyle: const TextStyle(color: Color(0xFF71717A)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF71717A)),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.$2),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat.$1),
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFA1A1AA),
                      fontSize: 13,
                    ),
                    checkmarkColor: Colors.white,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),

          // Level filter chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('すべてのレベル'),
                    selected: _selectedLevel == null,
                    onSelected: (_) => setState(() => _selectedLevel = null),
                    selectedColor: AppTheme.surface,
                    backgroundColor: AppTheme.surface,
                    labelStyle: TextStyle(
                      color: _selectedLevel == null
                          ? Colors.white
                          : const Color(0xFFA1A1AA),
                      fontSize: 12,
                    ),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: _selectedLevel == null
                          ? AppTheme.primary
                          : Colors.transparent,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                  ),
                ),
                ..._levels.map((lv) {
                  final selected = _selectedLevel == lv.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(lv.$2),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedLevel = selected ? null : lv.$1),
                      selectedColor: _levelColor(lv.$1).withValues(alpha: 0.25),
                      backgroundColor: AppTheme.surface,
                      labelStyle: TextStyle(
                        color: selected
                            ? _levelColor(lv.$1)
                            : const Color(0xFFA1A1AA),
                        fontSize: 12,
                      ),
                      checkmarkColor: _levelColor(lv.$1),
                      side: BorderSide(
                        color: selected
                            ? _levelColor(lv.$1)
                            : Colors.transparent,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Course grid
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      '該当する講座がありません',
                      style: TextStyle(color: Color(0xFFA1A1AA)),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.62,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final course = filtered[index];
                      return _CourseCard(
                        course: course,
                        gradient: _categoryGradient(course.category),
                        emoji: _categoryEmoji(course.category),
                        levelColor: _levelColor(course.level),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CourseDetailScreen(course: course),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final List<Color> gradient;
  final String emoji;
  final Color levelColor;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.gradient,
    required this.emoji,
    required this.levelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 40)),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Instructor
                    Text(
                      course.instructorName,
                      style: const TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          course.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '(${course.reviewCount})',
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Level chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: levelColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        course.levelLabel,
                        style: TextStyle(
                          color: levelColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Price or purchased
                    course.isPurchased
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '購入済み',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            course.formattedPrice,
                            style: const TextStyle(
                              color: Color(0xFFF97316),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
}
