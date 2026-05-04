import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../models/forum_models.dart';
import 'forum_thread_screen.dart';

final _apiClient = ApiClient();

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'all';
  List<ForumThread>? _threads;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _apiClient.fetchForumThreads();
    if (mounted) setState(() => _threads = data);
  }

  List<ForumThread> get _filteredThreads {
    final all = _threads ?? [];
    if (_selectedCategory == 'all') return all;
    return all.where((t) => t.category == _selectedCategory).toList();
  }

  static const _categories = [
    ('all', 'すべて'),
    ('technique', 'テクニック'),
    ('competition', '試合'),
    ('gear', 'ギア'),
    ('general', '雑談'),
  ];

  Color _categoryColor(String category) {
    switch (category) {
      case 'technique':
        return const Color(0xFFDC2626); // indigo
      case 'competition':
        return const Color(0xFF22C55E); // green
      case 'gear':
        return const Color(0xFFF59E0B); // amber
      default:
        return const Color(0xFF71717A); // zinc
    }
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'technique':
        return 'テクニック';
      case 'competition':
        return '試合';
      case 'gear':
        return 'ギア';
      default:
        return '雑談';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('コミュニティ'),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(child: _buildThreadList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewThreadSheet(context),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('投稿する'),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat.$1;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat.$2,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFA1A1AA),
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThreadList() {
    if (_threads == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
    }
    final threads = _filteredThreads;
    if (threads.isEmpty) {
      return const Center(
        child: Text('スレッドがありません', style: TextStyle(color: Color(0xFFA1A1AA))),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFFDC2626),
      backgroundColor: const Color(0xFF18181B),
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: threads.length,
        itemBuilder: (context, index) => _buildThreadCard(context, threads[index]),
      ),
    );
  }

  Widget _buildThreadCard(BuildContext context, ForumThread thread) {
    final catColor = _categoryColor(thread.category);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ForumThreadScreen(thread: thread),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _categoryLabel(thread.category),
                    style: TextStyle(
                      color: catColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              thread.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  thread.authorName,
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 12,
                  ),
                ),
                const Text(
                  ' · ',
                  style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                ),
                Text(
                  _formatDate(thread.createdAt),
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chat_bubble_outline,
                    size: 13, color: Color(0xFF71717A)),
                const SizedBox(width: 3),
                Text(
                  '${thread.replyCount}',
                  style: const TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.visibility_outlined,
                    size: 13, color: Color(0xFF71717A)),
                const SizedBox(width: 3),
                Text(
                  '${thread.viewCount}',
                  style: const TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNewThreadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NewThreadBottomSheet(onPosted: _load),
    );
  }
}

class _NewThreadBottomSheet extends StatefulWidget {
  final VoidCallback onPosted;
  const _NewThreadBottomSheet({required this.onPosted});

  @override
  State<_NewThreadBottomSheet> createState() => _NewThreadBottomSheetState();
}

class _NewThreadBottomSheetState extends State<_NewThreadBottomSheet> {
  String _selectedCategory = 'general';
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;

  static const _categories = [
    ('technique', 'テクニック'),
    ('competition', '試合'),
    ('gear', 'ギア'),
    ('general', '雑談'),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '新しいスレッドを投稿',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFFA1A1AA)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'カテゴリ',
            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat.$1;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cat.$2,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : const Color(0xFFA1A1AA),
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'タイトル',
              hintStyle: const TextStyle(color: Color(0xFF71717A)),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            style: const TextStyle(color: Colors.white),
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '本文を入力してください...',
              hintStyle: const TextStyle(color: Color(0xFF71717A)),
              filled: true,
              fillColor: const Color(0xFF27272A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : () async {
                final title = _titleController.text.trim();
                final body = _bodyController.text.trim();
                if (title.isEmpty || body.isEmpty) return;

                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                setState(() => _submitting = true);
                final id = await _apiClient.createForumThread(
                  title: title,
                  body: body,
                  category: _selectedCategory,
                );
                if (!mounted) return;
                setState(() => _submitting = false);

                if (id != null) {
                  nav.pop();
                  widget.onPosted();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('投稿しました')),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('投稿に失敗しました。再度お試しください。')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('投稿する', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
