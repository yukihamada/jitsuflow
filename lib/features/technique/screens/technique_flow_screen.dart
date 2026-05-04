import 'package:flutter/material.dart';
import '../data/flow_data.dart';
import '../painters/flow_painter.dart';
import '../models/flow_node.dart';

class TechniqueFlowScreen extends StatefulWidget {
  const TechniqueFlowScreen({super.key});

  @override
  State<TechniqueFlowScreen> createState() => _TechniqueFlowScreenState();
}

class _TechniqueFlowScreenState extends State<TechniqueFlowScreen> {
  String? _highlighted;
  bool _ryozoMode = false;
  final _searchCtrl = TextEditingController();
  late final Map<String, FlowNode> _nodeMap;
  late final Set<String> _ryozoNodeIds;
  late final Set<String> _ryozoEdgeKeys;
  final TransformationController _tc = TransformationController();

  @override
  void initState() {
    super.initState();
    _nodeMap = {for (final n in FlowData.nodes) n.id: n};
    _ryozoNodeIds = FlowData.ryozoNodeIds;
    _ryozoEdgeKeys = FlowData.ryozoEdgeKeys;
    for (final id in _ryozoNodeIds) {
      _nodeMap[id]?.isRyozo = true;
    }
    for (final id in FlowData.ryozoMainIds) {
      _nodeMap[id]?.isRyozoMain = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      final scale = size.width / 2400;
      // ignore: deprecated_member_use
      _tc.value = Matrix4.identity()
        ..scale(scale)
        ..translate(0.0, -1600.0);
    });
  }

  void _onTapCanvas(TapDownDetails details) {
    final matrix = _tc.value;
    final inv = Matrix4.inverted(matrix);
    final local = MatrixUtils.transformPoint(inv, details.localPosition);

    for (final node in FlowData.nodes) {
      if (local.dx >= node.x &&
          local.dx <= node.x + node.width &&
          local.dy >= node.y &&
          local.dy <= node.y + node.height) {
        setState(() {
          _highlighted = _highlighted == node.id ? null : node.id;
          _ryozoMode = false;
        });
        return;
      }
    }
    setState(() {
      _highlighted = null;
    });
  }

  void _toggleRyozo() {
    setState(() {
      _ryozoMode = !_ryozoMode;
      _highlighted = null;
    });
  }

  void _clearHighlight() {
    setState(() {
      _highlighted = null;
      _ryozoMode = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const canvasW = 2400.0;
    const canvasH = 3600.0;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        title: const Text(
          'テクニックフロー',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: _toggleRyozo,
            icon: const Text('🔵', style: TextStyle(fontSize: 14)),
            label: Text(
              '良蔵システム',
              style: TextStyle(
                color: _ryozoMode
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF71717A),
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.clear, color: Color(0xFF71717A)),
            onPressed: _clearHighlight,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: '🔍 技・状況を検索…',
                hintStyle: const TextStyle(color: Color(0xFF52525B)),
                filled: true,
                fillColor: const Color(0xFF18181B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (q) {
                if (q.isEmpty) {
                  setState(() => _highlighted = null);
                  return;
                }
                FlowNode? match;
                for (final n in FlowData.nodes) {
                  if (n.label.contains(q)) {
                    match = n;
                    break;
                  }
                }
                setState(() => _highlighted = match?.id);
              },
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTapDown: _onTapCanvas,
              child: InteractiveViewer(
                transformationController: _tc,
                minScale: 0.05,
                maxScale: 5.0,
                constrained: false,
                child: SizedBox(
                  width: canvasW,
                  height: canvasH,
                  child: CustomPaint(
                    size: const Size(canvasW, canvasH),
                    painter: FlowPainter(
                      nodes: FlowData.nodes,
                      edges: FlowData.edges,
                      nodeMap: _nodeMap,
                      highlightedId: _highlighted,
                      ryozoMode: _ryozoMode,
                      ryozoNodes: _ryozoNodeIds,
                      ryozoEdges: _ryozoEdgeKeys,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      color: const Color(0xFF09090B),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _legendItem(color: const Color(0xFFF59E0B), label: '判断',      isDiamond: true),
            _legendItem(color: const Color(0xFF22C55E), label: 'アクション'),
            _legendItem(color: const Color(0xFFF97316), label: 'ポジション'),
            _legendItem(color: const Color(0xFF14B8A6), label: 'トップ'),
            _legendItem(color: const Color(0xFFEF4444), label: 'フィニッシュ'),
            _legendItem(color: const Color(0xFF60A5FA), label: '良蔵',       isRyozo: true),
          ],
        ),
      ),
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    bool isDiamond = false,
    bool isRyozo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              border: Border.all(color: color, width: isRyozo ? 2.5 : 1.5),
              borderRadius: isDiamond ? null : BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isRyozo
                  ? const Color(0xFF93C5FD)
                  : const Color(0xFF71717A),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
