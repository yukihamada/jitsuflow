import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/training_session.dart';
import '../services/journal_service.dart';
import 'add_session_screen.dart';

const _kBg = Color(0xFF09090B);
const _kSurface = Color(0xFF18181B);
const _kBorder = Color(0xFF27272A);
const _kAccent = Color(0xFFDC2626);
const _kMuted = Color(0xFF71717A);

const _kSessionEmojis = {
  'gi': '🔵',
  'nogi': '🔴',
  'drilling': '🟢',
  'competition': '🏆',
};

const _kSessionColors = {
  'gi': Color(0xFF1D4ED8),
  'nogi': Color(0xFFDC2626),
  'drilling': Color(0xFF16A34A),
  'competition': Color(0xFFD97706),
};

const _kSessionLabels = {
  'gi': 'Gi',
  'nogi': 'No-Gi',
  'drilling': 'ドリル',
  'competition': '試合',
};

class TrainingJournalScreen extends StatefulWidget {
  const TrainingJournalScreen({super.key});

  @override
  State<TrainingJournalScreen> createState() => _TrainingJournalScreenState();
}

class _TrainingJournalScreenState extends State<TrainingJournalScreen> {
  final _service = JournalService();
  List<TrainingSession> _sessions = [];
  JournalStats _stats = const JournalStats(
    totalSessions: 0,
    totalMinutes: 0,
    currentStreak: 0,
    monthlyCount: 0,
  );
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sessions = await _service.getSessions();
    final stats = await _service.getStats();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _stats = stats;
        _loading = false;
      });
    }
  }

  Future<void> _openAdd() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddSessionScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _deleteSession(String id) async {
    await _service.deleteSession(id);
    _load();
  }

  // Group sessions by month
  Map<String, List<TrainingSession>> _groupByMonth() {
    final map = <String, List<TrainingSession>>{};
    for (final s in _sessions) {
      final key = DateFormat('yyyy年M月', 'ja').format(s.date);
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: Colors.white,
        title: const Text(
          '練習日誌',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdd,
        backgroundColor: _kAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _kAccent),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: _kAccent,
              backgroundColor: _kSurface,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildStatsHeader(),
                    ),
                  ),
                  if (_sessions.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    ..._buildSessionList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsHeader() {
    final totalHours = _stats.totalMinutes ~/ 60;
    final remainMins = _stats.totalMinutes % 60;
    final hoursLabel = remainMins > 0 ? '${totalHours}h${remainMins}m' : '${totalHours}h';

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: '${_stats.totalSessions}',
                  label: '総練習数',
                  icon: Icons.fitness_center,
                  iconColor: _kAccent,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _StatTile(
                  value: hoursLabel,
                  label: '総練習時間',
                  icon: Icons.timer_outlined,
                  iconColor: const Color(0xFF818CF8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _kBorder, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: _stats.currentStreak > 0
                      ? '${_stats.currentStreak}日連続'
                      : '0日',
                  label: '🔥 連続練習',
                  icon: null,
                  iconColor: Colors.orange,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _StatTile(
                  value: '${_stats.monthlyCount}',
                  label: '今月の練習',
                  icon: Icons.calendar_month_outlined,
                  iconColor: const Color(0xFF4ADE80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
        height: 50,
        color: _kBorder,
      );

  List<Widget> _buildSessionList() {
    final grouped = _groupByMonth();
    final months = grouped.keys.toList();

    return months
        .map((month) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    month,
                    style: const TextStyle(
                      color: _kMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final session = grouped[month]![i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: _SessionCard(
                        session: session,
                        onDelete: () => _deleteSession(session.id),
                      ),
                    );
                  },
                  childCount: grouped[month]!.length,
                ),
              ),
            ])
        .expand((w) => w)
        .toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center,
                color: _kAccent, size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            '練習記録がありません',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '右下の＋ボタンで最初の練習を記録しましょう',
            style: TextStyle(color: _kMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color iconColor;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor, size: 12),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(color: _kMuted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final TrainingSession session;
  final VoidCallback onDelete;

  const _SessionCard({required this.session, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final typeColor = _kSessionColors[session.sessionType] ?? _kAccent;
    final typeEmoji = _kSessionEmojis[session.sessionType] ?? '🥋';
    final typeLabel = _kSessionLabels[session.sessionType] ?? session.sessionType;

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(typeEmoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        typeLabel,
                        style: TextStyle(
                          color: typeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('M/d (E)', 'ja').format(session.date),
                  style: const TextStyle(color: _kMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Duration and energy
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: _kMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${session.durationMinutes}分',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(width: 16),
                // Energy stars
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < session.energyLevel
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i < session.energyLevel
                          ? Colors.amber
                          : const Color(0xFF3F3F46),
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                if (session.tapsGiven > 0 || session.tapsReceived > 0) ...[
                  Icon(Icons.flag_outlined, color: _kMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${session.tapsGiven}/${session.tapsReceived}',
                    style: const TextStyle(color: _kMuted, fontSize: 13),
                  ),
                ],
              ],
            ),
            // Techniques chips
            if (session.techniques.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: session.techniques
                    .take(5)
                    .map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t,
                          style: const TextStyle(
                              color: Color(0xFFA1A1AA), fontSize: 11),
                        ),
                      ),
                    )
                    .toList()
                  ..addAll(
                    session.techniques.length > 5
                        ? [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27272A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${session.techniques.length - 5}',
                                style: const TextStyle(
                                    color: Color(0xFFA1A1AA), fontSize: 11),
                              ),
                            )
                          ]
                        : [],
                  ),
              ),
            ],
            // Notes
            if (session.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                session.notes,
                style: const TextStyle(color: _kMuted, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
