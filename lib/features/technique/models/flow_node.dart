enum NodeType { start, decision, action, position, top, result }

class FlowNode {
  final String id;
  final NodeType type;
  final String label;
  final double x;
  final double y;
  bool isRyozo;
  bool isRyozoMain;

  FlowNode({
    required this.id,
    required this.type,
    required this.label,
    required this.x,
    required this.y,
    this.isRyozo = false,
    this.isRyozoMain = false,
  });

  static const double rectWidth = 170;
  static const double rectHeight = 36;
  static const double diamondWidth = 170;
  static const double diamondHeight = 52;

  double get width => type == NodeType.decision ? diamondWidth : rectWidth;
  double get height => type == NodeType.decision ? diamondHeight : rectHeight;
  double get cx => x + width / 2;
  double get cy => y + height / 2;
}
