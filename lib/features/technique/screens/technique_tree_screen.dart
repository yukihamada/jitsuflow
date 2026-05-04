import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

const _apiUrl = 'https://jiuflow-ssr.fly.dev/api/v1/technique-map';

class TechniqueNode {
  final String id;
  final String label;
  final String emoji;
  final int prob;
  final int priority;
  final String desc;
  final bool recommended;
  final bool warning;
  final List<TechniqueNode> children;

  const TechniqueNode({
    required this.id,
    required this.label,
    required this.emoji,
    required this.prob,
    required this.priority,
    required this.desc,
    required this.recommended,
    required this.warning,
    required this.children,
  });

  factory TechniqueNode.fromJson(Map<String, dynamic> j) {
    return TechniqueNode(
      id: j['id'] as String? ?? '',
      label: j['label'] as String? ?? '',
      emoji: j['emoji'] as String? ?? '🥋',
      prob: j['prob'] as int? ?? 0,
      priority: j['priority'] as int? ?? 0,
      desc: j['desc'] as String? ?? '',
      recommended: j['recommended'] as bool? ?? false,
      warning: j['warning'] as bool? ?? false,
      children: (j['children'] as List<dynamic>?)
              ?.map((c) => TechniqueNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TechniqueTreeScreen extends StatefulWidget {
  const TechniqueTreeScreen({super.key});

  @override
  State<TechniqueTreeScreen> createState() => _TechniqueTreeScreenState();
}

class _TechniqueTreeScreenState extends State<TechniqueTreeScreen> {
  TechniqueNode? _root;
  bool _loading = true;
  String? _error;
  final List<TechniqueNode> _path = [];
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        setState(() {
          _root = TechniqueNode.fromJson(data);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'HTTP ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  TechniqueNode get _current => _path.isEmpty ? _root! : _path.last;

  void _enter(TechniqueNode node) {
    if (node.children.isEmpty) return;
    setState(() {
      _path.add(node);
      _query = '';
      _searchCtrl.clear();
    });
  }

  void _back() {
    if (_path.isEmpty) return;
    setState(() {
      _path.removeLast();
      _query = '';
      _searchCtrl.clear();
    });
  }

  void _goTo(int index) {
    setState(() {
      _path.removeRange(index + 1, _path.length);
      _query = '';
      _searchCtrl.clear();
    });
  }

  List<TechniqueNode> get _filteredChildren {
    if (_query.isEmpty) return _current.children;
    return _current.children
        .where((n) =>
            n.label.contains(_query) ||
            n.desc.contains(_query) ||
            n.emoji.contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        leading: _path.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: _back,
              ),
        title: const Text(
          'テクニックツリー',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'マイフロー',
            icon: const Icon(Icons.tune, color: Colors.white70),
            onPressed: () => context.go('/technique-flow/my-flow'),
          ),
        ],
        bottom: _path.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(32),
                child: _buildBreadcrumb(),
              ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    _buildCurrentNode(),
                    _buildSearch(),
                    Expanded(child: _buildChildren()),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Color(0xFF71717A), size: 48),
          const SizedBox(height: 12),
          Text(
            'データ取得失敗',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            _error!,
            style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _fetch();
            },
            child: const Text('再試行', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          InkWell(
            onTap: () => setState(() {
              _path.clear();
              _query = '';
              _searchCtrl.clear();
            }),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text('🥋', style: TextStyle(fontSize: 14)),
            ),
          ),
          for (int i = 0; i < _path.length; i++) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(' › ', style: TextStyle(color: Color(0xFF52525B), fontSize: 12)),
            ),
            InkWell(
              onTap: i < _path.length - 1 ? () => _goTo(i) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: Text(
                  '${_path[i].emoji} ${_path[i].label}',
                  style: TextStyle(
                    color: i == _path.length - 1
                        ? Colors.white
                        : const Color(0xFF71717A),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentNode() {
    final node = _current;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: node.recommended
              ? const Color(0xFF22C55E)
              : node.warning
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF27272A),
          width: node.recommended || node.warning ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(node.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  node.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (node.recommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF22C55E), width: 1),
                  ),
                  child: const Text(
                    '推奨',
                    style: TextStyle(color: Color(0xFF22C55E), fontSize: 11),
                  ),
                ),
              if (node.warning)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                  ),
                  child: const Text(
                    '⚠️ 注意',
                    style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                  ),
                ),
            ],
          ),
          if (node.desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              node.desc,
              style: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
            ),
          ],
          if (node.prob > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('発生率 ', style: TextStyle(color: Color(0xFF52525B), fontSize: 11)),
                Text(
                  '${node.prob}%',
                  style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: node.prob / 100,
                      backgroundColor: const Color(0xFF27272A),
                      valueColor: AlwaysStoppedAnimation(
                        node.prob >= 70
                            ? const Color(0xFF22C55E)
                            : node.prob >= 40
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF3F3F46),
                      ),
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearch() {
    if (_current.children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: '🔍 検索…',
          hintStyle: const TextStyle(color: Color(0xFF52525B)),
          filled: true,
          fillColor: const Color(0xFF18181B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        onChanged: (q) => setState(() => _query = q),
      ),
    );
  }

  Widget _buildChildren() {
    final children = _filteredChildren;
    if (children.isEmpty) {
      return const Center(
        child: Text(
          '次のステップへ進んでください',
          style: TextStyle(color: Color(0xFF52525B), fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      itemCount: children.length,
      itemBuilder: (context, i) => _buildNodeCard(children[i]),
    );
  }

  Widget _buildNodeCard(TechniqueNode node) {
    final hasChildren = node.children.isNotEmpty;
    return InkWell(
      onTap: hasChildren ? () => _enter(node) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: node.recommended
                ? const Color(0xFF22C55E).withValues(alpha:0.5)
                : node.warning
                    ? const Color(0xFFF59E0B).withValues(alpha:0.5)
                    : const Color(0xFF27272A),
          ),
        ),
        child: Row(
          children: [
            Text(node.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          node.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (node.recommended)
                        const Text('✓推奨',
                            style: TextStyle(color: Color(0xFF22C55E), fontSize: 11)),
                      if (node.warning)
                        const Text('⚠️',
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11)),
                    ],
                  ),
                  if (node.desc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        node.desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF71717A), fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            if (hasChildren)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    Text(
                      '',
                      style: TextStyle(color: Color(0xFF52525B), fontSize: 11),
                    ),
                    Icon(Icons.chevron_right, color: Color(0xFF52525B), size: 18),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
