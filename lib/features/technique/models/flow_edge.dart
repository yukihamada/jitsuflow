enum EdgeCategory { flow, yes, no, sweep, sub, transition, escape, td }

class FlowEdge {
  final String source;
  final String target;
  final EdgeCategory category;
  final String label;

  const FlowEdge({
    required this.source,
    required this.target,
    required this.category,
    this.label = '',
  });

  String get key => '$source→$target';
}
