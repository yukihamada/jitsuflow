import 'package:flutter/material.dart';
import '../models/builtin_template.dart';

class TemplateViewScreen extends StatelessWidget {
  final BuiltinTemplate template;

  const TemplateViewScreen({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: Text(template.name,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Text(
                template.description,
                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 14, height: 1.6),
              ),
            ),
            const SizedBox(height: 20),

            // Principles
            if (template.principles.isNotEmpty) ...[
              _sectionLabel('📌 原則'),
              const SizedBox(height: 10),
              ...template.principles.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            e.value,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 20),
            ],

            // Submissions / Attacks
            _sectionLabel('⚔️ サブミッション・スイープ'),
            const SizedBox(height: 10),
            ...template.submissions.map((s) => _SubmissionCard(submission: s)),
            const SizedBox(height: 20),

            // Positions
            _sectionLabel('📍 ポジション'),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: Column(
                children: template.positions.asMap().entries.map((e) {
                  final pos = e.value;
                  final isLast = e.key == template.positions.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pos.marker == '*')
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 5, right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDC2626),
                                  shape: BoxShape.circle,
                                ),
                              )
                            else if (pos.marker == '!')
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 5, right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              )
                            else
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 5, right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3F3F46),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pos.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (pos.description.isNotEmpty)
                                    Text(
                                      pos.description,
                                      style: const TextStyle(
                                        color: Color(0xFF71717A),
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        const Divider(color: Color(0xFF27272A), height: 1, indent: 32),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Transitions
            if (template.transitions.isNotEmpty) ...[
              _sectionLabel('🔄 フロー（遷移）'),
              const SizedBox(height: 10),
              ...template.transitions.map((t) => _TransitionCard(transition: t, positions: template.positions)),
            ],

            // Legend
            const SizedBox(height: 24),
            Row(
              children: [
                _legendDot(const Color(0xFFDC2626)),
                const SizedBox(width: 6),
                const Text('メインポジション', style: TextStyle(color: Color(0xFF71717A), fontSize: 11)),
                const SizedBox(width: 16),
                _legendDot(const Color(0xFFF59E0B)),
                const SizedBox(width: 6),
                const Text('注意ポジション', style: TextStyle(color: Color(0xFF71717A), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: const TextStyle(
          color: Color(0xFF52525B),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      );

  Widget _legendDot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _SubmissionCard extends StatelessWidget {
  final JjfSubmission submission;
  const _SubmissionCard({required this.submission});

  Color get _priorityColor {
    switch (submission.priorityLevel) {
      case 1:
        return const Color(0xFFDC2626);
      case 2:
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF71717A);
    }
  }

  IconData get _typeIcon =>
      submission.type == 'sweep' ? Icons.swap_vert : Icons.lock_outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: submission.priorityLevel == 1
              ? const Color(0xFFDC2626).withValues(alpha: 0.3)
              : const Color(0xFF27272A),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_typeIcon, color: _priorityColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  submission.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _priorityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  submission.priority,
                  style: TextStyle(
                    color: _priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (submission.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              submission.description,
              style: const TextStyle(color: Color(0xFF71717A), fontSize: 12, height: 1.5),
            ),
          ],
          if (submission.from.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: submission.from.map((f) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(f, style: const TextStyle(color: Color(0xFF71717A), fontSize: 10)),
                  )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransitionCard extends StatelessWidget {
  final JjfTransition transition;
  final List<JjfPosition> positions;

  const _TransitionCard({required this.transition, required this.positions});

  String _posName(String id) {
    final pos = positions.where((p) => p.id == id).firstOrNull;
    return pos?.name ?? id;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_posName(transition.from),
                    style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
              ),
              const Icon(Icons.arrow_forward, color: Color(0xFFDC2626), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_posName(transition.to),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.right),
              ),
            ],
          ),
          if (transition.action.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              transition.action,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
          if (transition.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              transition.description,
              style: const TextStyle(color: Color(0xFF52525B), fontSize: 11, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
