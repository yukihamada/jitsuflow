import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../models/athlete_model.dart';
import 'athlete_detail_screen.dart';

final _apiClient = ApiClient();

Color _beltColor(String? belt) {
  switch (belt) {
    case '白帯':
      return Colors.white;
    case '青帯':
      return const Color(0xFF3B82F6);
    case '紫帯':
      return const Color(0xFF8B5CF6);
    case '茶帯':
      return const Color(0xFF92400E);
    case '黒帯':
      return const Color(0xFF111827);
    default:
      return const Color(0xFF6B7280);
  }
}

class AthletesScreen extends StatefulWidget {
  const AthletesScreen({super.key});

  @override
  State<AthletesScreen> createState() => _AthletesScreenState();
}

class _AthletesScreenState extends State<AthletesScreen> {
  String _query = '';
  List<AthleteModel>? _athletes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _apiClient.fetchAthletes();
    if (mounted) setState(() => _athletes = data);
  }

  List<AthleteModel> get _filtered {
    final all = _athletes ?? [];
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((a) =>
        a.name.toLowerCase().contains(q) ||
        (a.nameEn?.toLowerCase().contains(q) ?? false) ||
        (a.affiliation?.toLowerCase().contains(q) ?? false)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('選手一覧',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '選手を検索...',
                hintStyle: const TextStyle(color: Color(0xFF71717A)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF71717A)),
                filled: true,
                fillColor: const Color(0xFF18181B),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF27272A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF27272A)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFDC2626)),
                ),
              ),
            ),
          ),
          Expanded(
            child: _athletes == null
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
                : _filtered.isEmpty
                    ? const Center(child: Text('選手が見つかりません', style: TextStyle(color: Color(0xFF52525B))))
                    : RefreshIndicator(
                        color: const Color(0xFFDC2626),
                        backgroundColor: const Color(0xFF18181B),
                        onRefresh: _load,
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _AthleteCard(athlete: _filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _AthleteCard extends StatelessWidget {
  final AthleteModel athlete;
  const _AthleteCard({required this.athlete});

  @override
  Widget build(BuildContext context) {
    final initials = athlete.name.isNotEmpty ? athlete.name[0] : '?';
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AthleteDetailScreen(athlete: athlete)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.2),
              backgroundImage: athlete.photoUrl != null
                  ? NetworkImage(athlete.photoUrl!)
                  : null,
              onBackgroundImageError: athlete.photoUrl != null
                  ? (_, __) {}
                  : null,
              child: athlete.photoUrl == null
                  ? Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              athlete.name,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (athlete.belt != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _beltColor(athlete.belt),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF27272A), width: 0.5),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    athlete.belt!,
                    style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              athlete.affiliation ?? '',
              style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
