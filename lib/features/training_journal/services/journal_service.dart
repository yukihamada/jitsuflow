import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_session.dart';

class JournalService {
  static const String _key = 'training_journal_sessions';

  Future<List<TrainingSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((s) => TrainingSession.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addSession(TrainingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(session.toJson()));
    await prefs.setStringList(_key, raw);
  }

  Future<void> deleteSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return map['id'] == id;
    });
    await prefs.setStringList(_key, raw);
  }

  Future<JournalStats> getStats() async {
    final sessions = await getSessions();
    if (sessions.isEmpty) {
      return const JournalStats(
        totalSessions: 0,
        totalMinutes: 0,
        currentStreak: 0,
        monthlyCount: 0,
      );
    }

    final totalMinutes =
        sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

    // Current streak: consecutive training days ending today or yesterday
    final streak = _calculateStreak(sessions);

    final now = DateTime.now();
    final monthlyCount = sessions
        .where((s) => s.date.year == now.year && s.date.month == now.month)
        .length;

    return JournalStats(
      totalSessions: sessions.length,
      totalMinutes: totalMinutes,
      currentStreak: streak,
      monthlyCount: monthlyCount,
    );
  }

  int _calculateStreak(List<TrainingSession> sessions) {
    if (sessions.isEmpty) return 0;

    // Collect unique training dates (date only, no time)
    final dates = sessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Streak must include today or yesterday
    if (dates.first != today && dates.first != yesterday) return 0;

    int streak = 1;
    for (int i = 1; i < dates.length; i++) {
      final expected = dates[i - 1].subtract(const Duration(days: 1));
      if (dates[i] == expected) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}
