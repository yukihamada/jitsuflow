import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/builtin_template.dart';
import '../models/game_plan.dart';
import '../services/game_plan_service.dart';
import 'game_plan_editor_screen.dart';
import 'template_view_screen.dart';

class GamePlansScreen extends StatefulWidget {
  const GamePlansScreen({super.key});

  @override
  State<GamePlansScreen> createState() => _GamePlansScreenState();
}

class _GamePlansScreenState extends State<GamePlansScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = GamePlanService();
  List<GamePlan> _myPlans = [];
  List<BuiltinTemplate> _templates = [];
  bool _loadingPlans = true;
  bool _loadingTemplates = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyPlans();
    _loadTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyPlans() async {
    final plans = await _service.loadAll();
    if (mounted) setState(() { _myPlans = plans; _loadingPlans = false; });
  }

  Future<void> _loadTemplates() async {
    final templates = <BuiltinTemplate>[];
    for (final meta in kBuiltinMeta) {
      try {
        final raw = await rootBundle.loadString('assets/${meta.id}.json');
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final t = BuiltinTemplate.fromJson(meta.id, json);
        templates.add(BuiltinTemplate(
          id: t.id, name: t.name, description: t.description,
          icon: meta.icon, tag: meta.tag, tagColor: meta.color,
          principles: t.principles, positions: t.positions,
          transitions: t.transitions, submissions: t.submissions,
        ));
      } catch (e) { debugPrint('[GamePlans] template parse error: $e'); }
    }
    if (mounted) setState(() { _templates = templates; _loadingTemplates = false; });
  }

  Future<void> _createNew() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const GamePlanEditorScreen(plan: null)),
    );
    if (result == true) _loadMyPlans();
  }

  Future<void> _openEditor(GamePlan plan) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => GamePlanEditorScreen(plan: plan)),
    );
    if (result == true) _loadMyPlans();
  }

  Future<void> _cloneTemplate(BuiltinTemplate t) async {
    final now = DateTime.now();
    final steps = t.submissions.asMap().entries.map((e) {
      final s = e.value;
      final fromPos = s.from.isNotEmpty ? s.from.first : '';
      final posName = t.positions.where((p) => p.id == fromPos).firstOrNull?.name ?? fromPos;
      return GamePlanStep(
        id: '${t.id}_${e.key}', positionId: fromPos, positionName: posName,
        techniqueId: s.id, techniqueName: s.name, notes: s.description, order: e.key,
      );
    }).toList();
    final plan = GamePlan(
      id: '${t.id}_${now.millisecondsSinceEpoch}',
      title: '${t.name}（コピー）', description: t.description,
      steps: steps, createdAt: now, updatedAt: now,
    );
    await _service.save(plan);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('「${t.name}」をマイプランに追加しました'),
        backgroundColor: const Color(0xFF18181B),
      ));
      _loadMyPlans();
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('ゲームプラン',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFDC2626),
          unselectedLabelColor: const Color(0xFF71717A),
          indicatorColor: const Color(0xFFDC2626),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [Tab(text: 'テンプレート'), Tab(text: 'マイプラン')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _createNew,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTemplatesTab(), _buildMyPlansTab()],
      ),
    );
  }

  Widget _buildTemplatesTab() {
    if (_loadingTemplates) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: _templates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _TemplateCard(
        template: _templates[i],
        onView: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TemplateViewScreen(template: _templates[i])),
        ),
        onClone: () => _cloneTemplate(_templates[i]),
      ),
    );
  }

  Widget _buildMyPlansTab() {
    if (_loadingPlans) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)));
    }
    if (_myPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📋', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('まだマイプランがありません',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('テンプレートをコピーするか新規作成',
                style: TextStyle(color: Color(0xFF71717A), fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createNew,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('新規作成'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _myPlans.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final plan = _myPlans[i];
        return _MyPlanCard(
          plan: plan,
          onTap: () => _openEditor(plan),
          onDelete: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF18181B),
                title: const Text('削除', style: TextStyle(color: Colors.white)),
                content: Text('「${plan.title}」を削除しますか？',
                    style: const TextStyle(color: Color(0xFFA1A1AA))),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('キャンセル', style: TextStyle(color: Color(0xFFA1A1AA)))),
                  TextButton(onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('削除', style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            );
            if (ok == true) { await _service.delete(plan.id); _loadMyPlans(); }
          },
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final BuiltinTemplate template;
  final VoidCallback onView;
  final VoidCallback onClone;
  const _TemplateCard({required this.template, required this.onView, required this.onClone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(template.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.name,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(4)),
                      child: Text(template.tag,
                          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${template.positions.length} ポジション',
                      style: const TextStyle(color: Color(0xFF52525B), fontSize: 10)),
                  Text('${template.submissions.length} 技',
                      style: const TextStyle(color: Color(0xFF52525B), fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(template.description,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF71717A), fontSize: 12, height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onView,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(color: const Color(0xFF27272A), borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('👁  閲覧', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13))),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onClone,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(8)),
                    child: const Center(child: Text('📋  コピー保存',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyPlanCard extends StatelessWidget {
  final GamePlan plan;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _MyPlanCard({required this.plan, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final d = plan.updatedAt;
    final dateStr = '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  if (plan.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(plan.description,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF71717A), fontSize: 12)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${plan.steps.length} ステップ',
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      Text(dateStr, style: const TextStyle(color: Color(0xFF52525B), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF3F3F46), size: 18),
          ],
        ),
      ),
    );
  }
}
