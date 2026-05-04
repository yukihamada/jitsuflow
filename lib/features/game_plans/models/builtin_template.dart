class JjfPosition {
  final String id;
  final String name;
  final String type; // position, submission etc.
  final String marker; // *, !, or ''
  final String description;

  const JjfPosition({
    required this.id,
    required this.name,
    required this.type,
    required this.marker,
    required this.description,
  });

  factory JjfPosition.fromJson(Map<String, dynamic> j) => JjfPosition(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String? ?? 'position',
        marker: j['_type'] as String? ?? '',
        description: j['description'] as String? ?? '',
      );
}

class JjfTransition {
  final String id;
  final String from;
  final String to;
  final String action;
  final String description;

  const JjfTransition({
    required this.id,
    required this.from,
    required this.to,
    required this.action,
    required this.description,
  });

  factory JjfTransition.fromJson(Map<String, dynamic> j) => JjfTransition(
        id: j['id'] as String? ?? '',
        from: j['from'] as String,
        to: j['to'] as String,
        action: j['action'] as String? ?? '',
        description: j['description'] as String? ?? '',
      );
}

class JjfSubmission {
  final String id;
  final String name;
  final String type; // submission, sweep
  final String priority;
  final int priorityLevel;
  final List<String> from;
  final String description;

  const JjfSubmission({
    required this.id,
    required this.name,
    required this.type,
    required this.priority,
    required this.priorityLevel,
    required this.from,
    required this.description,
  });

  factory JjfSubmission.fromJson(Map<String, dynamic> j) => JjfSubmission(
        id: j['id'] as String? ?? '',
        name: j['name'] as String,
        type: j['type'] as String? ?? 'submission',
        priority: j['priority'] as String? ?? '',
        priorityLevel: j['priorityLevel'] as int? ?? 3,
        from: (j['from'] as List?)?.map((e) => e as String).toList() ?? [],
        description: j['description'] as String? ?? '',
      );
}

class BuiltinTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String tag;
  final String tagColor;
  final List<String> principles;
  final List<JjfPosition> positions;
  final List<JjfTransition> transitions;
  final List<JjfSubmission> submissions;

  const BuiltinTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.tag,
    required this.tagColor,
    required this.principles,
    required this.positions,
    required this.transitions,
    required this.submissions,
  });

  factory BuiltinTemplate.fromJson(String id, Map<String, dynamic> j) {
    final meta = j['meta'] as Map<String, dynamic>;
    return BuiltinTemplate(
      id: id,
      name: meta['name'] as String? ?? id,
      description: meta['description'] as String? ?? '',
      icon: '📋',
      tag: '',
      tagColor: '#dc2626',
      principles: (meta['principles'] as List?)?.map((e) => e as String).toList() ?? [],
      positions: (j['positions'] as List?)
              ?.map((e) => JjfPosition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      transitions: (j['transitions'] as List?)
              ?.map((e) => JjfTransition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      submissions: (j['submissions'] as List?)
              ?.map((e) => JjfSubmission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

const kBuiltinMeta = [
  // Belt progression
  (id: 'belt-white', icon: '🤍', tag: '白帯', color: '#E4E4E7'),
  (id: 'belt-blue', icon: '💙', tag: '青帯', color: '#3B82F6'),
  (id: 'belt-purple', icon: '💜', tag: '紫帯', color: '#A855F7'),
  (id: 'belt-brown', icon: '🤎', tag: '茶帯', color: '#92400E'),
  (id: 'belt-black', icon: '🖤', tag: '黒帯', color: '#27272A'),
  // Systems
  (id: 'ryozo-system', icon: '🔴', tag: '良蔵システム', color: '#DC2626'),
  (id: 'template-top-game', icon: '⬆️', tag: 'トップ系', color: '#F59E0B'),
  (id: 'template-back-taker', icon: '🎯', tag: 'バック系', color: '#DC2626'),
  (id: 'template-leg-locker', icon: '🦵', tag: '足関節系', color: '#22C55E'),
  (id: 'template-half-guard', icon: '🌓', tag: 'ハーフ系', color: '#A78BFA'),
  // Famous players
  (id: 'player-gordon-ryan', icon: '👑', tag: '有名選手', color: '#F59E0B'),
  (id: 'player-marcelo-garcia', icon: '🦋', tag: '有名選手', color: '#F59E0B'),
  (id: 'player-roger-gracie', icon: '🔴', tag: '有名選手', color: '#F59E0B'),
  (id: 'player-mikey-musumeci', icon: '🦵', tag: '有名選手', color: '#F59E0B'),
  (id: 'player-bernardo-faria', icon: '⚓', tag: '有名選手', color: '#F59E0B'),
  (id: 'player-craig-jones', icon: '⚡', tag: '有名選手', color: '#F59E0B'),
  (id: 'player-andre-galvao', icon: '🦅', tag: '有名選手', color: '#F59E0B'),
  (id: 'player-garry-tonon', icon: '🤸', tag: '有名選手', color: '#F59E0B'),
];
