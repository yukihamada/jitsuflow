import 'package:flutter/material.dart';

class _MemberEntry {
  final String id;
  final String name;
  final String belt;
  bool checkedIn;

  _MemberEntry({
    required this.id,
    required this.name,
    required this.belt,
    required this.checkedIn,
  });
}

class ClassCheckinScreen extends StatefulWidget {
  final String classId;
  final String className;

  const ClassCheckinScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<ClassCheckinScreen> createState() => _ClassCheckinScreenState();
}

class _ClassCheckinScreenState extends State<ClassCheckinScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_MemberEntry> _members = [
    _MemberEntry(id: 'm1', name: '鈴木太郎', belt: '青帯', checkedIn: false),
    _MemberEntry(id: 'm2', name: '田中花子', belt: '白帯', checkedIn: false),
    _MemberEntry(id: 'm3', name: '山田次郎', belt: '紫帯', checkedIn: false),
    _MemberEntry(id: 'm4', name: '佐藤健', belt: '青帯', checkedIn: false),
    _MemberEntry(id: 'm5', name: '伊藤美咲', belt: '白帯', checkedIn: false),
    _MemberEntry(id: 'm6', name: '中村勇気', belt: '茶帯', checkedIn: false),
    _MemberEntry(id: 'm7', name: '小林道夫', belt: '黒帯', checkedIn: false),
    _MemberEntry(id: 'm8', name: '加藤奈々', belt: '白帯', checkedIn: false),
  ];

  List<_MemberEntry> get _filteredMembers {
    if (_searchQuery.isEmpty) return _members;
    return _members
        .where((m) => m.name.contains(_searchQuery))
        .toList();
  }

  int get _checkedInCount => _members.where((m) => m.checkedIn).length;

  Color _beltColor(String belt) {
    switch (belt) {
      case '白帯':
        return const Color(0xFFF5F5F5);
      case '青帯':
        return const Color(0xFF3B82F6);
      case '紫帯':
        return const Color(0xFFA855F7);
      case '茶帯':
        return const Color(0xFF92400E);
      case '黒帯':
        return const Color(0xFF1C1C1C);
      default:
        return const Color(0xFFA1A1AA);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMembers;

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Text('チェックイン - ${widget.className}'),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'メンバーを検索...',
                hintStyle: const TextStyle(color: Color(0xFF71717A)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF71717A)),
                filled: true,
                fillColor: const Color(0xFF18181B),
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  _buildMemberCard(filtered[index]),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildMemberCard(_MemberEntry member) {
    return GestureDetector(
      onTap: () => setState(() => member.checkedIn = !member.checkedIn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: member.checkedIn
              ? const Color(0xFF22C55E).withValues(alpha: 0.1)
              : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: member.checkedIn
                ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                : const Color(0xFF27272A),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF3F3F46),
              child: Text(
                member.name.characters.first,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _beltColor(member.belt),
                          borderRadius: BorderRadius.circular(3),
                          border: member.belt == '白帯'
                              ? Border.all(
                                  color: const Color(0xFF71717A), width: 0.5)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        member.belt,
                        style: const TextStyle(
                            color: Color(0xFFA1A1AA), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: member.checkedIn
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.checkedIn ? 'チェックイン済' : '未チェックイン',
                style: TextStyle(
                  color: member.checkedIn
                      ? Colors.white
                      : const Color(0xFFA1A1AA),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF18181B),
        border: Border(top: BorderSide(color: Color(0xFF27272A))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '完了 ($_checkedInCount/${_members.length}名チェックイン済)',
                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('完了',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
