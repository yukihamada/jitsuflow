import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../models/dojo_model.dart';
import 'dojo_detail_screen.dart';

final _apiClient = ApiClient();

class DojosScreen extends StatefulWidget {
  const DojosScreen({super.key});

  @override
  State<DojosScreen> createState() => _DojosScreenState();
}

class _DojosScreenState extends State<DojosScreen> {
  String _query = '';
  String _prefecture = 'すべて';
  List<DojoModel>? _dojos;
  List<String> _prefectures = ['すべて'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _apiClient.fetchDojos();
    if (!mounted) return;
    final prefs = <String>{'すべて'};
    for (final d in data) {
      if (d.prefecture != null && d.prefecture!.isNotEmpty) {
        prefs.add(d.prefecture!);
      }
    }
    setState(() {
      _dojos = data;
      _prefectures = prefs.toList();
    });
  }

  List<DojoModel> get _filtered {
    final all = _dojos ?? [];
    return all.where((d) {
      final matchQuery = _query.isEmpty ||
          d.name.toLowerCase().contains(_query.toLowerCase()) ||
          (d.city?.contains(_query) ?? false) ||
          (d.address?.contains(_query) ?? false);
      final matchPref = _prefecture == 'すべて' || d.prefecture == _prefecture;
      return matchQuery && matchPref;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('道場一覧',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '道場を検索...',
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
          if (_prefectures.length > 1)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _prefectures.length,
                itemBuilder: (context, i) {
                  final pref = _prefectures[i];
                  final selected = _prefecture == pref;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(pref),
                      selected: selected,
                      onSelected: (_) => setState(() => _prefecture = pref),
                      backgroundColor: const Color(0xFF18181B),
                      selectedColor: const Color(0xFFDC2626).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFFDC2626),
                      labelStyle: TextStyle(
                        color: selected ? const Color(0xFFDC2626) : const Color(0xFFA1A1AA),
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: selected ? const Color(0xFFDC2626) : const Color(0xFF27272A),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _dojos == null
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
                : _filtered.isEmpty
                    ? const Center(child: Text('道場が見つかりません', style: TextStyle(color: Color(0xFF52525B))))
                    : RefreshIndicator(
                        color: const Color(0xFFDC2626),
                        backgroundColor: const Color(0xFF18181B),
                        onRefresh: _load,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _DojoCard(dojo: _filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _DojoCard extends StatelessWidget {
  final DojoModel dojo;
  const _DojoCard({required this.dojo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DojoDetailScreen(dojo: dojo)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: dojo.photoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(dojo.photoUrl!, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.sports_martial_arts, color: Color(0xFF71717A))),
                    )
                  : const Icon(Icons.sports_martial_arts, color: Color(0xFF71717A)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dojo.name,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (dojo.prefecture != null || dojo.city != null)
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 13, color: Color(0xFF71717A)),
                        const SizedBox(width: 3),
                        Text(
                          [dojo.prefecture, dojo.city].where((e) => e != null).join(' '),
                          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                        ),
                      ],
                    ),
                  if (dojo.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      dojo.description!,
                      style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
