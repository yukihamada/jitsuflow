import 'dart:math';
import 'package:flutter/material.dart';
import '../models/flow_node.dart';
import '../models/flow_edge.dart';

class FlowPainter extends CustomPainter {
  final List<FlowNode> nodes;
  final List<FlowEdge> edges;
  final Map<String, FlowNode> nodeMap;
  final String? highlightedId;
  final bool ryozoMode;
  final Set<String> ryozoNodes;
  final Set<String> ryozoEdges;

  FlowPainter({
    required this.nodes,
    required this.edges,
    required this.nodeMap,
    this.highlightedId,
    this.ryozoMode = false,
    required this.ryozoNodes,
    required this.ryozoEdges,
  });

  Color edgeColor(EdgeCategory cat) {
    switch (cat) {
      case EdgeCategory.yes:        return const Color(0xFF22C55E);
      case EdgeCategory.no:         return const Color(0xFFEF4444);
      case EdgeCategory.sweep:      return const Color(0xFF22C55E);
      case EdgeCategory.sub:        return const Color(0xFFEF4444);
      case EdgeCategory.transition: return const Color(0xFFF97316);
      case EdgeCategory.escape:     return const Color(0xFF94A3B8);
      case EdgeCategory.td:         return const Color(0xFF3B82F6);
      default:                      return const Color(0xFF52525B);
    }
  }

  Color nodeFill(FlowNode n) {
    switch (n.type) {
      case NodeType.start:    return const Color(0xFF1E3A8A);
      case NodeType.decision: return const Color(0x23F59E0B);
      case NodeType.action:   return const Color(0x1A22C55E);
      case NodeType.position: return const Color(0x1F6366F1);
      case NodeType.top:      return const Color(0x1A14B8A6);
      case NodeType.result:   return const Color(0x1FEF4444);
    }
  }

  Color nodeStroke(FlowNode n) {
    if (n.isRyozoMain) return const Color(0xFF93C5FD);
    if (n.isRyozo)     return const Color(0xFF60A5FA);
    switch (n.type) {
      case NodeType.start:    return const Color(0xFF60A5FA);
      case NodeType.decision: return const Color(0xFFF59E0B);
      case NodeType.action:   return const Color(0x7F22C55E);
      case NodeType.position: return const Color(0xFFF97316);
      case NodeType.top:      return const Color(0xFF14B8A6);
      case NodeType.result:   return const Color(0x7FEF4444);
    }
  }

  Color textColor(FlowNode n) {
    switch (n.type) {
      case NodeType.start:    return Colors.white;
      case NodeType.decision: return const Color(0xFFFCD34D);
      case NodeType.action:   return const Color(0xFF86EFAC);
      case NodeType.position: return const Color(0xFFA5B4FC);
      case NodeType.top:      return const Color(0xFF5EEAD4);
      case NodeType.result:   return const Color(0xFFFCA5A5);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      _drawEdge(canvas, edge);
    }
    for (final node in nodes) {
      _drawNode(canvas, node);
    }
  }

  void _drawEdge(Canvas canvas, FlowEdge edge) {
    final ns = nodeMap[edge.source];
    final nt = nodeMap[edge.target];
    if (ns == null || nt == null) return;

    final isRyo = ryozoEdges.contains(edge.key);
    bool isDim = false;
    if (ryozoMode && !isRyo) isDim = true;
    if (highlightedId != null) {
      final connected = edge.source == highlightedId || edge.target == highlightedId;
      isDim = !connected;
    }

    final color = isRyo && ryozoMode
        ? const Color(0xFF60A5FA)
        : edgeColor(edge.category);

    final paint = Paint()
      ..color = color.withValues(alpha: isDim ? 0.05 : (isRyo && ryozoMode ? 0.95 : 0.6))
      ..strokeWidth = isRyo && ryozoMode ? 2.8 : 1.4
      ..style = PaintingStyle.stroke;

    if (edge.category == EdgeCategory.transition || edge.category == EdgeCategory.escape) {
      paint.strokeWidth = 1.2;
    }

    final sx = ns.x + ns.width;
    final sy = ns.cy;
    final tx = nt.x;
    final ty = nt.cy;
    final dx = (tx - sx).abs();
    final cp = max(dx * 0.5, 60.0);

    final path = Path()
      ..moveTo(sx, sy)
      ..cubicTo(sx + cp, sy, tx - cp, ty, tx, ty);

    if (edge.category == EdgeCategory.transition || edge.category == EdgeCategory.escape) {
      _drawDashedPath(canvas, path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    _drawArrow(canvas, tx, ty, color.withValues(alpha: isDim ? 0.05 : 0.8));
  }

  void _drawArrow(Canvas canvas, double x, double y, Color color) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(x, y)
      ..lineTo(x - 8, y - 4)
      ..lineTo(x - 8, y + 4)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashLen = 6.0, gapLen = 4.0;
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      bool draw = true;
      while (dist < metric.length) {
        final len = draw ? dashLen : gapLen;
        if (draw) {
          canvas.drawPath(metric.extractPath(dist, dist + len), paint);
        }
        dist += len;
        draw = !draw;
      }
    }
  }

  void _drawNode(Canvas canvas, FlowNode node) {
    final isRyo = node.isRyozo;
    bool isDim = false;
    if (ryozoMode && !isRyo) isDim = true;
    if (highlightedId != null && node.id != highlightedId) {
      isDim = true;
    }

    final fillColor = nodeFill(node).withValues(alpha: isDim ? 0.05 : 1.0);
    final strokeColor = nodeStroke(node).withValues(alpha: isDim ? 0.1 : 1.0);
    final strokeWidth = node.isRyozoMain ? 4.0 : (node.isRyozo ? 3.0 : 1.5);

    final fillPaint = Paint()..color = fillColor..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (node.type == NodeType.decision) {
      _drawDiamond(canvas, node, fillPaint, strokePaint);
    } else {
      _drawRect(canvas, node, fillPaint, strokePaint);
    }

    _drawLabel(canvas, node, isDim);

    if (node.isRyozo && !isDim) {
      _drawRyozoBadge(canvas, node);
    }
  }

  void _drawRect(Canvas canvas, FlowNode node, Paint fill, Paint stroke) {
    final rect = RRect.fromLTRBR(
      node.x, node.y, node.x + node.width, node.y + node.height,
      const Radius.circular(9),
    );
    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, stroke);
  }

  void _drawDiamond(Canvas canvas, FlowNode node, Paint fill, Paint stroke) {
    final cx = node.x + node.width / 2;
    final cy = node.y + node.height / 2;
    final path = Path()
      ..moveTo(cx, node.y)
      ..lineTo(node.x + node.width, cy)
      ..lineTo(cx, node.y + node.height)
      ..lineTo(node.x, cy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawLabel(Canvas canvas, FlowNode node, bool dim) {
    final color = textColor(node).withValues(alpha: dim ? 0.1 : 1.0);
    final lines = node.label.split('\n');
    final fontSize = node.type == NodeType.start ? 14.0 : 11.0;

    for (int i = 0; i < lines.length; i++) {
      final text = lines[i].length > 16 ? '${lines[i].substring(0, 15)}…' : lines[i];
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: node.type == NodeType.start ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: node.width - 8);

      final offset = (i - (lines.length - 1) / 2) * 13;
      tp.paint(canvas, Offset(
        node.x + (node.width - tp.width) / 2,
        node.y + node.height / 2 + offset - tp.height / 2,
      ));
    }
  }

  void _drawRyozoBadge(Canvas canvas, FlowNode node) {
    final badgeRect = RRect.fromLTRBR(
      node.x + node.width - 18, node.y - 10,
      node.x + node.width,      node.y + 2,
      const Radius.circular(3),
    );
    canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFF1D4ED8));
    final tp = TextPainter(
      text: const TextSpan(
        text: '良',
        style: TextStyle(
          color: Color(0xFFBFDBFE),
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(
      node.x + node.width - 18 + (18 - tp.width) / 2,
      node.y - 10 + (12 - tp.height) / 2,
    ));
  }

  @override
  bool shouldRepaint(FlowPainter old) =>
      old.highlightedId != highlightedId || old.ryozoMode != ryozoMode;
}
