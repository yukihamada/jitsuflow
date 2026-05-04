import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _baseUrl = 'https://jiuflow-ssr.fly.dev';

const _nodeColors = {
  'start':    Color(0xFFDC2626),
  'decision': Color(0xFFF59E0B),
  'position': Color(0xFF2563EB),
  'action':   Color(0xFF16A34A),
  'result':   Color(0xFF7C3AED),
  'top':      Color(0xFFEA580C),
};

const _edgeColors = {
  'flow':       Color(0xFF71717A),
  'yes':        Color(0xFF22C55E),
  'no':         Color(0xFFEF4444),
  'sweep':      Color(0xFF22C55E),
  'sub':        Color(0xFFEF4444),
  'transition': Color(0xFF818CF8),
  'escape':     Color(0xFF94A3B8),
  'td':         Color(0xFF3B82F6),
};

Color _nodeColor(String type) => _nodeColors[type] ?? const Color(0xFF52525B);
Color _edgeColor(String cat)  => _edgeColors[cat]  ?? const Color(0xFF71717A);

class FlowNode {
  final String id, nodeType, label;
  final double x, y;

  const FlowNode({required this.id, required this.nodeType,
      required this.label, required this.x, required this.y});

  factory FlowNode.fromJson(Map<String, dynamic> j) => FlowNode(
    id: j['id'] as String,
    nodeType: j['node_type'] as String? ?? 'position',
    label: j['label'] as String,
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() =>
      {'id': id, 'node_type': nodeType, 'label': label, 'x': x, 'y': y};
}

class FlowEdge {
  final String id, sourceId, targetId, category, label;

  const FlowEdge({required this.id, required this.sourceId,
      required this.targetId, required this.category, required this.label});

  factory FlowEdge.fromJson(Map<String, dynamic> j) => FlowEdge(
    id: j['id'] as String,
    sourceId: j['source_id'] as String,
    targetId: j['target_id'] as String,
    category: j['category'] as String? ?? 'flow',
    label: j['label'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'source_id': sourceId, 'target_id': targetId,
    'category': category, 'label': label,
  };
}

class MyFlowScreen extends StatefulWidget {
  const MyFlowScreen({super.key});
  @override State<MyFlowScreen> createState() => _MyFlowScreenState();
}

class _MyFlowScreenState extends State<MyFlowScreen> {
  List<FlowNode> _nodes = [];
  List<FlowEdge> _edges = [];
  bool _loading = true, _isCustom = false, _editMode = false, _saving = false;
  bool _isLoggedIn = false;
  String? _selectedId, _error, _draggingId;
  final _storage = const FlutterSecureStorage();
  final _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.read(key: 'auth_token');
    setState(() => _isLoggedIn = token != null && token.isNotEmpty);
    await _loadFlow();
  }

  Future<String?> _getToken() => _storage.read(key: 'auth_token');

  /// Spread out overlapping nodes so nothing overlaps
  List<FlowNode> _resolveOverlaps(List<FlowNode> nodes) {
    const nw = 190.0; // min horizontal spacing
    const nh = 56.0;  // min vertical spacing
    final result = nodes.map((n) => FlowNode(
      id: n.id, nodeType: n.nodeType, label: n.label, x: n.x, y: n.y,
    )).toList();

    // Sort by y then x for stable layout
    result.sort((a, b) {
      final dy = a.y.compareTo(b.y);
      return dy != 0 ? dy : a.x.compareTo(b.x);
    });

    // Multiple passes to push apart
    for (int pass = 0; pass < 10; pass++) {
      bool moved = false;
      for (int i = 0; i < result.length; i++) {
        for (int j = i + 1; j < result.length; j++) {
          final dx = (result[i].x - result[j].x).abs();
          final dy = (result[i].y - result[j].y).abs();
          if (dx < nw && dy < nh) {
            // Push apart
            if (dx < nw) {
              final pushX = (nw - dx) / 2 + 5;
              final ni = result[i];
              final nj = result[j];
              if (ni.x <= nj.x) {
                result[i] = FlowNode(id: ni.id, nodeType: ni.nodeType, label: ni.label,
                    x: ni.x - pushX, y: ni.y);
                result[j] = FlowNode(id: nj.id, nodeType: nj.nodeType, label: nj.label,
                    x: nj.x + pushX, y: nj.y);
              } else {
                result[i] = FlowNode(id: ni.id, nodeType: ni.nodeType, label: ni.label,
                    x: ni.x + pushX, y: ni.y);
                result[j] = FlowNode(id: nj.id, nodeType: nj.nodeType, label: nj.label,
                    x: nj.x - pushX, y: nj.y);
              }
              moved = true;
            }
            if (dy < nh) {
              final pushY = (nh - dy) / 2 + 5;
              final ni = result[i];
              final nj = result[j];
              if (ni.y <= nj.y) {
                result[i] = FlowNode(id: ni.id, nodeType: ni.nodeType, label: ni.label,
                    x: ni.x, y: ni.y - pushY);
                result[j] = FlowNode(id: nj.id, nodeType: nj.nodeType, label: nj.label,
                    x: nj.x, y: nj.y + pushY);
              } else {
                result[i] = FlowNode(id: ni.id, nodeType: ni.nodeType, label: ni.label,
                    x: ni.x, y: ni.y + pushY);
                result[j] = FlowNode(id: nj.id, nodeType: nj.nodeType, label: nj.label,
                    x: nj.x, y: nj.y - pushY);
              }
              moved = true;
            }
          }
        }
      }
      if (!moved) break;
    }
    return result;
  }

  Future<void> _loadFlow() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('$_baseUrl/api/v1/my-flow'),
        headers: token != null ? {'Authorization': 'Bearer $token'} : {},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        var nodes = (data['nodes'] as List)
            .map((e) => FlowNode.fromJson(e as Map<String, dynamic>)).toList();
        final edges = (data['edges'] as List)
            .map((e) => FlowEdge.fromJson(e as Map<String, dynamic>)).toList();
        nodes = _resolveOverlaps(nodes);
        setState(() {
          _nodes = nodes;
          _edges = edges;
          _isCustom = data['is_custom'] as bool? ?? false;
          _error = null;
        });
      } else {
        setState(() => _error = 'データ取得に失敗しました (${res.statusCode})');
      }
    } catch (e) {
      debugPrint('flow load error: $e');
      setState(() => _error = 'データ取得に失敗しました');
    }
    setState(() => _loading = false);
  }

  Future<void> _saveFlow() async {
    if (!_isLoggedIn) { _showLoginRequired(); return; }
    setState(() => _saving = true);
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse('$_baseUrl/api/v1/my-flow'),
        headers: {'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'nodes': _nodes.map((n) => n.toJson()).toList(),
          'edges': _edges.map((e) => e.toJson()).toList(),
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => _isCustom = true);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存しました'),
              backgroundColor: Color(0xFF16A34A),
              duration: Duration(seconds: 2)));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました (${res.statusCode})'),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 2)));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました'),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 2)));
    }
    setState(() => _saving = false);
  }

  Future<void> _resetFlow() async {
    final ok = await showDialog<bool>(context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        title: const Text('リセット', style: TextStyle(color: Colors.white)),
        content: const Text('デフォルトに戻しますか？',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => ctx.pop(false),
              child: const Text('キャンセル')),
          TextButton(onPressed: () => ctx.pop(true),
              child: const Text('リセット',
                  style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ));
    if (ok != true) return;
    try {
      final token = await _getToken();
      await http.delete(Uri.parse('$_baseUrl/api/v1/my-flow/reset'),
          headers: {if (token != null) 'Authorization': 'Bearer $token'});
    } catch (e) {
      debugPrint('[MyFlow] reset error: $e');
    }
    await _loadFlow();
  }

  void _showLoginRequired() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: const Text('ログインが必要',
          style: TextStyle(color: Colors.white)),
      content: const Text('フローの保存にはログインしてください。',
          style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => ctx.pop(),
            child: const Text('キャンセル')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626)),
          onPressed: () { ctx.pop(); context.go('/login-magic'); },
          child: const Text('ログイン'),
        ),
      ],
    ));
  }

  void _onTapCanvas(Offset pos) {
    const nw = 170.0, nh = 44.0;
    for (final n in _nodes) {
      final r = Rect.fromLTWH(n.x, n.y, nw, nh);
      if (r.contains(pos)) {
        if (_editMode) {
          _editLabel(n);
        } else {
          setState(() => _selectedId = _selectedId == n.id ? null : n.id);
        }
        return;
      }
    }
    setState(() => _selectedId = null);
  }

  void _editLabel(FlowNode node) {
    final ctrl = TextEditingController(text: node.label);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF18181B),
      title: const Text('ノードを編集',
          style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true, fillColor: Colors.white10,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8))),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => ctx.pop(),
            child: const Text('キャンセル')),
        TextButton(
          onPressed: () {
            final idx = _nodes.indexWhere((n) => n.id == node.id);
            if (idx >= 0) {
              setState(() {
                _nodes = List.from(_nodes)
                  ..[idx] = FlowNode(id: node.id, nodeType: node.nodeType,
                      label: ctrl.text, x: node.x, y: node.y);
              });
            }
            ctx.pop();
          },
          child: const Text('OK',
              style: TextStyle(color: Color(0xFF22C55E))),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white70, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(children: [
          const Text('マイフロー',
              style: TextStyle(color: Colors.white,
                  fontSize: 17, fontWeight: FontWeight.w600)),
          if (_isCustom) Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4)),
            child: const Text('カスタム',
                style: TextStyle(color: Color(0xFFA78BFA),
                    fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ]),
        actions: [
          if (_editMode && _isCustom)
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.white54, size: 20),
              onPressed: _resetFlow,
            ),
          IconButton(
            icon: Icon(_editMode ? Icons.edit_off : Icons.edit_outlined,
                color: _editMode
                    ? const Color(0xFFDC2626) : Colors.white70, size: 22),
            onPressed: () {
              if (!_isLoggedIn && !_editMode) {
                _showLoginRequired(); return;
              }
              setState(() => _editMode = !_editMode);
            },
          ),
          if (_editMode)
            _saving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF22C55E))))
                : IconButton(
                    icon: const Icon(Icons.save_outlined,
                        color: Color(0xFF22C55E), size: 22),
                    onPressed: _saveFlow),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFFDC2626), strokeWidth: 2.5))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Color(0xFF71717A), size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () { setState(() => _error = null); _loadFlow(); },
                      child: const Text('再試行', style: TextStyle(color: Color(0xFFDC2626))),
                    ),
                  ]))
              : _nodes.isEmpty
                  ? const Center(child: Text('データなし',
                      style: TextStyle(color: Colors.white54)))
                  : _buildCanvas(),
    );
  }

  Widget _buildCanvas() {
    const nw = 170.0, nh = 44.0;
    final maxX = _nodes.fold(0.0, (m, n) => n.x > m ? n.x : m) + nw + 20;
    final maxY = _nodes.fold(0.0, (m, n) => n.y > m ? n.y : m) + nh + 20;
    final nodeMap = {for (final n in _nodes) n.id: n};

    // Set initial view to center on the start node with good zoom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transformCtrl.value == Matrix4.identity()) {
        final size = MediaQuery.of(context).size;
        // Find start node or use first node
        final start = _nodes.firstWhere(
          (n) => n.nodeType == 'start',
          orElse: () => _nodes.first,
        );
        const scale = 0.7;
        final tx = -(start.x - size.width / 2 / scale + nw / 2);
        final ty = -(start.y - size.height / 2 / scale + nh / 2);
        // ignore: deprecated_member_use
        _transformCtrl.value = Matrix4.identity()
          ..scale(scale)
          ..translate(tx, ty);
      }
    });

    return InteractiveViewer(
      transformationController: _transformCtrl,
      constrained: false,
      minScale: 0.1,
      maxScale: 3.0,
      panEnabled: !_editMode || _draggingId == null,
      child: GestureDetector(
        onTapDown: (d) => _onTapCanvas(d.localPosition),
        onPanStart: _editMode ? (d) => _onDragStart(d.localPosition) : null,
        onPanUpdate: _editMode ? (d) => _onDragUpdate(d.delta) : null,
        onPanEnd: _editMode ? (_) => _onDragEnd() : null,
        child: CustomPaint(
          size: Size(maxX, maxY),
          painter: _FlowPainter(
            nodes: _nodes,
            edges: _edges,
            nodeMap: nodeMap,
            selectedId: _selectedId,
            editMode: _editMode,
          ),
        ),
      ),
    );
  }

  void _onDragStart(Offset pos) {
    const nw = 170.0, nh = 44.0;
    for (final n in _nodes) {
      if (Rect.fromLTWH(n.x, n.y, nw, nh).contains(pos)) {
        setState(() => _draggingId = n.id);
        return;
      }
    }
    _draggingId = null;
  }

  void _onDragUpdate(Offset delta) {
    if (_draggingId == null) return;
    final scale = _transformCtrl.value.getMaxScaleOnAxis();
    final idx = _nodes.indexWhere((n) => n.id == _draggingId);
    if (idx < 0) return;
    final node = _nodes[idx];
    setState(() {
      _nodes = List.from(_nodes)
        ..[idx] = FlowNode(
          id: node.id, nodeType: node.nodeType, label: node.label,
          x: node.x + delta.dx / scale, y: node.y + delta.dy / scale,
        );
    });
  }

  void _onDragEnd() {
    setState(() => _draggingId = null);
  }
}

class _FlowPainter extends CustomPainter {
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  final Map<String, FlowNode> nodeMap;
  final String? selectedId;
  final bool editMode;

  const _FlowPainter({
    required this.nodes,
    required this.edges,
    required this.nodeMap,
    required this.selectedId,
    required this.editMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawEdgeLines(canvas);  // 1. lines behind everything
    _drawNodes(canvas);       // 2. nodes on top of lines
    _drawEdgeLabels(canvas);  // 3. labels on top of nodes
  }

  void _drawEdgeLines(Canvas canvas) {
    const nw = 170.0, nh = 44.0;
    for (final edge in edges) {
      final src = nodeMap[edge.sourceId];
      final tgt = nodeMap[edge.targetId];
      if (src == null || tgt == null) continue;

      final color = _edgeColor(edge.category);
      final isDashed = edge.category == 'transition';

      final paint = Paint()
        ..color = color.withValues(alpha: isDashed ? 0.25 : 0.45)
        ..strokeWidth = isDashed ? 1.0 : 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final sx = src.x + nw;
      final sy = src.y + nh / 2;
      final tx = tgt.x;
      final ty = tgt.y + nh / 2;
      final dx = (tx - sx).abs();
      final cp = dx * 0.5 < 40 ? 40.0 : dx * 0.5;

      final path = Path()
        ..moveTo(sx, sy)
        ..cubicTo(sx + cp, sy, tx - cp, ty, tx, ty);

      if (isDashed) {
        _drawDashed(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
        final ap = Paint()
          ..color = color.withValues(alpha: 0.55)
          ..style = PaintingStyle.fill;
        final arrow = Path()
          ..moveTo(tx, ty)
          ..lineTo(tx - 6, ty - 3)
          ..lineTo(tx - 6, ty + 3)
          ..close();
        canvas.drawPath(arrow, ap);
      }
    }
  }

  void _drawEdgeLabels(Canvas canvas) {
    const nw = 170.0, nh = 44.0;
    for (final edge in edges) {
      final src = nodeMap[edge.sourceId];
      final tgt = nodeMap[edge.targetId];
      if (src == null || tgt == null) continue;
      if (edge.label.isEmpty || edge.category == 'transition') continue;

      final color = _edgeColor(edge.category);
      final sx = src.x + nw;
      final sy = src.y + nh / 2;
      final tx = tgt.x;
      final ty = tgt.y + nh / 2;
      final mx = (sx + tx) / 2;
      final my = (sy + ty) / 2 - 12;
      _drawTextWithBg(canvas, edge.label,
          Offset(mx, my), color.withValues(alpha: 0.95), 8);
    }
  }

  void _drawNodes(Canvas canvas) {
    const nw = 170.0, nh = 44.0;
    for (final node in nodes) {
      final color = _nodeColor(node.nodeType);
      final isSelected = node.id == selectedId;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(node.x, node.y, nw, nh),
        const Radius.circular(8),
      );

      // solid background to hide edges behind
      canvas.drawRRect(rect, Paint()
        ..color = const Color(0xFF09090B)
        ..style = PaintingStyle.fill);

      // fill with color
      canvas.drawRRect(rect, Paint()
        ..color = color.withValues(alpha: isSelected ? 0.55 : 0.22)
        ..style = PaintingStyle.fill);

      // border
      canvas.drawRRect(rect, Paint()
        ..color = color.withValues(
            alpha: isSelected ? 1.0 : (editMode ? 0.8 : 0.6))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.2);

      // edit indicator
      if (editMode) {
        final ep = Paint()
          ..color = const Color(0xFFDC2626).withValues(alpha: 0.6)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(node.x + nw - 6, node.y + 6), 3, ep);
      }

      // label
      final labelColor = isSelected
          ? Colors.white
          : Colors.white.withValues(alpha: 0.92);
      _drawText(canvas, node.label,
          Offset(node.x + nw / 2, node.y + nh / 2), labelColor, 12,
          maxWidth: nw - 12, bold: true, centered: true);
    }
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color,
      double fontSize, {double maxWidth = 200, bool bold = false, bool centered = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.center,
    )..layout(maxWidth: maxWidth);

    final offset = centered
        ? Offset(center.dx - tp.width / 2, center.dy - tp.height / 2)
        : Offset(center.dx - tp.width / 2, center.dy);
    tp.paint(canvas, offset);
  }

  void _drawTextWithBg(Canvas canvas, String text, Offset center, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);

    final offset = Offset(center.dx - tp.width / 2, center.dy - tp.height / 2);
    // Draw dark background pill
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offset.dx - 4, offset.dy - 2, tp.width + 8, tp.height + 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, Paint()
      ..color = const Color(0xFF09090B).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill);
    tp.paint(canvas, offset);
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final len = draw ? 5.0 : 4.0;
        final end = (dist + len).clamp(0.0, metric.length);
        if (draw) canvas.drawPath(metric.extractPath(dist, end), paint);
        dist = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) =>
      old.nodes != nodes || old.selectedId != selectedId ||
      old.editMode != editMode;
}
