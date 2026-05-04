import 'dart:convert';

class TrainingSession {
  final String id;
  final DateTime date;
  final int durationMinutes;
  final String sessionType; // 'gi', 'nogi', 'drilling', 'competition'
  final List<String> techniques;
  final String notes;
  final int energyLevel; // 1-5
  final int tapsGiven;
  final int tapsReceived;

  const TrainingSession({
    required this.id,
    required this.date,
    required this.durationMinutes,
    required this.sessionType,
    required this.techniques,
    required this.notes,
    required this.energyLevel,
    required this.tapsGiven,
    required this.tapsReceived,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'durationMinutes': durationMinutes,
        'sessionType': sessionType,
        'techniques': techniques,
        'notes': notes,
        'energyLevel': energyLevel,
        'tapsGiven': tapsGiven,
        'tapsReceived': tapsReceived,
      };

  factory TrainingSession.fromJson(Map<String, dynamic> json) =>
      TrainingSession(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        durationMinutes: json['durationMinutes'] as int,
        sessionType: json['sessionType'] as String,
        techniques: List<String>.from(json['techniques'] as List),
        notes: json['notes'] as String,
        energyLevel: json['energyLevel'] as int,
        tapsGiven: json['tapsGiven'] as int,
        tapsReceived: json['tapsReceived'] as int,
      );

  String toJsonString() => jsonEncode(toJson());

  factory TrainingSession.fromJsonString(String s) =>
      TrainingSession.fromJson(jsonDecode(s) as Map<String, dynamic>);

  TrainingSession copyWith({
    String? id,
    DateTime? date,
    int? durationMinutes,
    String? sessionType,
    List<String>? techniques,
    String? notes,
    int? energyLevel,
    int? tapsGiven,
    int? tapsReceived,
  }) =>
      TrainingSession(
        id: id ?? this.id,
        date: date ?? this.date,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        sessionType: sessionType ?? this.sessionType,
        techniques: techniques ?? this.techniques,
        notes: notes ?? this.notes,
        energyLevel: energyLevel ?? this.energyLevel,
        tapsGiven: tapsGiven ?? this.tapsGiven,
        tapsReceived: tapsReceived ?? this.tapsReceived,
      );
}

class JournalStats {
  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;
  final int monthlyCount;

  const JournalStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.currentStreak,
    required this.monthlyCount,
  });
}
