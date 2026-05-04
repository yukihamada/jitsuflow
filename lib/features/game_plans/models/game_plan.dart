class GamePlanStep {
  final String id;
  final String positionId;
  final String positionName;
  final String techniqueId;
  final String techniqueName;
  final String notes;
  final int order;

  const GamePlanStep({
    required this.id,
    required this.positionId,
    required this.positionName,
    required this.techniqueId,
    required this.techniqueName,
    this.notes = '',
    required this.order,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'positionId': positionId,
        'positionName': positionName,
        'techniqueId': techniqueId,
        'techniqueName': techniqueName,
        'notes': notes,
        'order': order,
      };

  factory GamePlanStep.fromJson(Map<String, dynamic> j) => GamePlanStep(
        id: j['id'] as String,
        positionId: j['positionId'] as String,
        positionName: j['positionName'] as String,
        techniqueId: j['techniqueId'] as String,
        techniqueName: j['techniqueName'] as String,
        notes: (j['notes'] as String?) ?? '',
        order: j['order'] as int,
      );

  GamePlanStep copyWith({String? notes}) => GamePlanStep(
        id: id,
        positionId: positionId,
        positionName: positionName,
        techniqueId: techniqueId,
        techniqueName: techniqueName,
        notes: notes ?? this.notes,
        order: order,
      );
}

class GamePlan {
  final String id;
  final String title;
  final String description;
  final List<GamePlanStep> steps;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GamePlan({
    required this.id,
    required this.title,
    this.description = '',
    required this.steps,
    required this.createdAt,
    required this.updatedAt,
  });

  GamePlan copyWith({
    String? title,
    String? description,
    List<GamePlanStep>? steps,
  }) =>
      GamePlan(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        steps: steps ?? this.steps,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'steps': steps.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory GamePlan.fromJson(Map<String, dynamic> j) => GamePlan(
        id: j['id'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        steps: (j['steps'] as List)
            .map((s) => GamePlanStep.fromJson(s as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}
