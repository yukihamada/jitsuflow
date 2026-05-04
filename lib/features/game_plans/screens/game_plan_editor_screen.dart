import 'package:flutter/material.dart';
import '../models/game_plan.dart';
import '../services/game_plan_service.dart';

/// Map of position → techniques
const _positionTechniques = <String, List<String>>{
  'クローズドガード': [
    '三角絞め',
    '腕十字',
    'オモプラッタ',
    'シザースイープ',
    'ヒップバンプ',
    'キムラ',
    'ループチョーク',
  ],
  'ハーフガード': [
    'ドッグファイト→バック',
    'ウェイタースイープ',
    'エレクトリックチェア',
  ],
  'バタフライガード': ['スイープ', '三角絞め', '腕十字'],
  'DLR': ['スイープ', '三角絞め', '腕十字'],
  'マウント': ['クロスチョーク', 'エゼキエル', '腕十字(Sマウント)'],
  'バックコントロール': ['RNC', 'ボウ＆アロー', '腕十字'],
  'サイドコントロール': ['スイープ', '三角絞め', '腕十字'],
  'ニーオンベリー': ['スイープ', '三角絞め', '腕十字'],
  'スパイダーガード': ['スイープ', '三角絞め', '腕十字'],
  'ラッソーガード': ['スイープ', '三角絞め', '腕十字'],
};

class GamePlanEditorScreen extends StatefulWidget {
  final GamePlan? plan;

  const GamePlanEditorScreen({super.key, required this.plan});

  @override
  State<GamePlanEditorScreen> createState() => _GamePlanEditorScreenState();
}

class _GamePlanEditorScreenState extends State<GamePlanEditorScreen> {
  final _service = GamePlanService();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late List<GamePlanStep> _steps;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.plan?.title ?? '新しいゲームプラン');
    _descController =
        TextEditingController(text: widget.plan?.description ?? '');
    _steps = List<GamePlanStep>.from(widget.plan?.steps ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    final plan = GamePlan(
      id: widget.plan?.id ?? now.millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim().isEmpty
          ? '無題のプラン'
          : _titleController.text.trim(),
      description: _descController.text.trim(),
      steps: _steps,
      createdAt: widget.plan?.createdAt ?? now,
      updatedAt: now,
    );
    await _service.save(plan);
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _addStep(GamePlanStep step) {
    setState(() => _steps.add(step));
  }

  void _deleteStep(int index) {
    setState(() => _steps.removeAt(index));
  }

  void _reorderSteps(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final step = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, step);
      // recompute order
      for (var i = 0; i < _steps.length; i++) {
        _steps[i] = GamePlanStep(
          id: _steps[i].id,
          positionId: _steps[i].positionId,
          positionName: _steps[i].positionName,
          techniqueId: _steps[i].techniqueId,
          techniqueName: _steps[i].techniqueName,
          notes: _steps[i].notes,
          order: i,
        );
      }
    });
  }

  void _editNotes(int index) {
    final step = _steps[index];
    final controller = TextEditingController(text: step.notes);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${step.positionName} → ${step.techniqueName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'メモを入力...',
                hintStyle: TextStyle(color: Color(0xFF71717A)),
                filled: true,
                fillColor: Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _steps[index] = step.copyWith(notes: controller.text);
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddStep() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _AddStepBottomSheet(
        onAdd: (step) {
          Navigator.pop(ctx);
          final withOrder = GamePlanStep(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            positionId: step.positionId,
            positionName: step.positionName,
            techniqueId: step.techniqueId,
            techniqueName: step.techniqueName,
            notes: step.notes,
            order: _steps.length,
          );
          _addStep(withOrder);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('プランを編集'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text(
                    '保存',
                    style: TextStyle(color: Color(0xFFDC2626), fontSize: 16),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // Title & description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'プランのタイトル',
                    hintStyle: TextStyle(color: Color(0xFF71717A)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const Divider(color: Color(0xFF27272A)),
                TextField(
                  controller: _descController,
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: '説明（任意）',
                    hintStyle: TextStyle(color: Color(0xFF71717A)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF27272A), height: 1),
          // Steps
          Expanded(
            child: _steps.isEmpty
                ? const Center(
                    child: Text(
                      'ステップを追加してプランを構築しましょう',
                      style: TextStyle(color: Color(0xFF71717A), fontSize: 14),
                    ),
                  )
                : ReorderableListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: _steps.length,
                    onReorder: _reorderSteps,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return _StepCard(
                        key: ValueKey(step.id),
                        step: step,
                        index: index,
                        onDelete: () => _deleteStep(index),
                        onEditNotes: () => _editNotes(index),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: const Color(0xFF09090B),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openAddStep,
            icon: const Icon(Icons.add, color: Color(0xFFDC2626)),
            label: const Text(
              '＋ ステップを追加',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDC2626)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final GamePlanStep step;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEditNotes;

  const _StepCard({
    super.key,
    required this.step,
    required this.index,
    required this.onDelete,
    required this.onEditNotes,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEditNotes,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.drag_handle,
                  color: Color(0xFF71717A),
                  size: 20,
                ),
              ),
            ),
            // Position chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                step.positionName,
                style: const TextStyle(
                  color: Color(0xFFF97316),
                  fontSize: 11,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.arrow_forward, color: Color(0xFF71717A), size: 14),
            ),
            // Technique name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.techniqueName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (step.notes.isNotEmpty)
                    Text(
                      step.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFA1A1AA),
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            // Delete button
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close, color: Color(0xFF71717A), size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStepBottomSheet extends StatefulWidget {
  final void Function(GamePlanStep) onAdd;

  const _AddStepBottomSheet({required this.onAdd});

  @override
  State<_AddStepBottomSheet> createState() => _AddStepBottomSheetState();
}

class _AddStepBottomSheetState extends State<_AddStepBottomSheet> {
  String? _selectedPosition;
  String? _selectedTechnique;
  final _notesController = TextEditingController();

  static final _positions = _positionTechniques.keys.toList();

  List<String> get _techniques =>
      _selectedPosition != null
          ? (_positionTechniques[_selectedPosition!] ?? [])
          : [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF71717A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ポジション選択',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _positions.map((pos) {
                  final selected = pos == _selectedPosition;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedPosition = pos;
                        _selectedTechnique = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          pos,
                          style: TextStyle(
                            color: selected ? Colors.white : const Color(0xFFA1A1AA),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (_selectedPosition != null) ...[
              const SizedBox(height: 16),
              const Text(
                'テクニック選択',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _techniques.map((tech) {
                  final selected = tech == _selectedTechnique;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTechnique = tech),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF27272A),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tech,
                        style: TextStyle(
                          color: selected ? Colors.white : const Color(0xFFA1A1AA),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'メモ（任意）',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'コツや注意点など...',
                hintStyle: TextStyle(color: Color(0xFF71717A)),
                filled: true,
                fillColor: Color(0xFF27272A),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPosition != null && _selectedTechnique != null
                    ? () {
                        widget.onAdd(GamePlanStep(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          positionId: _selectedPosition!,
                          positionName: _selectedPosition!,
                          techniqueId: _selectedTechnique!,
                          techniqueName: _selectedTechnique!,
                          notes: _notesController.text.trim(),
                          order: 0,
                        ));
                      }
                    : null,
                child: const Text('追加'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
