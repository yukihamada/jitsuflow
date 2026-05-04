import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/athlete_model.dart';

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
      return const Color(0xFF374151);
    default:
      return const Color(0xFF6B7280);
  }
}

class AthleteDetailScreen extends StatelessWidget {
  final AthleteModel athlete;
  const AthleteDetailScreen({super.key, required this.athlete});

  @override
  Widget build(BuildContext context) {
    final initials = athlete.name.isNotEmpty ? athlete.name[0] : '?';
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(athlete.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 56,
                backgroundColor: const Color(0xFFDC2626).withValues(alpha: 0.2),
                backgroundImage: athlete.photoUrl != null
                    ? NetworkImage(athlete.photoUrl!)
                    : null,
                child: athlete.photoUrl == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                athlete.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (athlete.nameEn != null)
              Center(
                child: Text(
                  athlete.nameEn!,
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoCard(athlete),
            const SizedBox(height: 16),
            if (athlete.bio != null) ...[
              const Text(
                'プロフィール',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF18181B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Text(
                  athlete.bio!,
                  style: const TextStyle(
                    color: Color(0xFFD4D4D8),
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/technique-flow'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'テクニックを見る',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(AthleteModel a) {
    final items = <(String, String?)>[
      ('🥋 帯', a.belt),
      ('🏫 所属', a.affiliation),
      ('🌏 国籍', a.nationality),
      ('⚖️ 体重', a.weight),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        children: items
            .where((i) => i.$2 != null)
            .map(
              (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        i.$1,
                        style: const TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (i.$1.contains('帯'))
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _beltColor(i.$2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4B5563),
                                width: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            i.$2!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        i.$2!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
