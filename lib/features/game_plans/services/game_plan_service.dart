import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_plan.dart';

class GamePlanService {
  static const _key = 'game_plans';

  Future<List<GamePlan>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      // Seed with sample plans on first launch
      final samples = _samplePlans();
      await _persist(samples);
      return samples;
    }
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => GamePlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(GamePlan plan) async {
    final plans = await loadAll();
    final idx = plans.indexWhere((p) => p.id == plan.id);
    if (idx >= 0) {
      plans[idx] = plan;
    } else {
      plans.add(plan);
    }
    await _persist(plans);
  }

  Future<void> delete(String id) async {
    final plans = await loadAll();
    plans.removeWhere((p) => p.id == id);
    await _persist(plans);
  }

  Future<void> _persist(List<GamePlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(plans.map((p) => p.toJson()).toList()));
  }

  static List<GamePlan> _samplePlans() {
    final now = DateTime.now();
    return [
      GamePlan(
        id: 'sample_1',
        title: '良蔵システム — ハーフガード攻略',
        description: '村田良蔵式ハーフガードからのスイープ＆バックテイク',
        steps: [
          GamePlanStep(id: 's1_1', positionId: 'ハーフガード', positionName: 'ハーフガード', techniqueId: 'ドッグファイト→バック', techniqueName: 'ドッグファイト→バック', notes: 'アンダーフックをしっかり確保してから立ち上がる', order: 0),
          GamePlanStep(id: 's1_2', positionId: 'バックコントロール', positionName: 'バックコントロール', techniqueId: 'RNC', techniqueName: 'RNC', notes: 'シートベルトで崩してから絞める', order: 1),
          GamePlanStep(id: 's1_3', positionId: 'バックコントロール', positionName: 'バックコントロール', techniqueId: 'ボウ＆アロー', techniqueName: 'ボウ＆アロー', notes: 'RNCが防がれたらこちらへ移行', order: 2),
        ],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      GamePlan(
        id: 'sample_2',
        title: 'クローズドガード三角システム',
        description: 'クローズドガードから三角絞めへの移行パターン',
        steps: [
          GamePlanStep(id: 's2_1', positionId: 'クローズドガード', positionName: 'クローズドガード', techniqueId: 'シザースイープ', techniqueName: 'シザースイープ', notes: '相手が重心を前に来たら仕掛ける', order: 0),
          GamePlanStep(id: 's2_2', positionId: 'マウント', positionName: 'マウント', techniqueId: 'クロスチョーク', techniqueName: 'クロスチョーク', notes: 'スイープ成功後にマウントへ移行', order: 1),
          GamePlanStep(id: 's2_3', positionId: 'クローズドガード', positionName: 'クローズドガード', techniqueId: '三角絞め', techniqueName: '三角絞め', notes: 'スイープ失敗時の二の矢', order: 2),
        ],
        createdAt: now.subtract(const Duration(days: 14)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      GamePlan(
        id: 'sample_3',
        title: 'バタフライガード → バックテイク',
        description: 'バタフライスイープからバックへの連携',
        steps: [
          GamePlanStep(id: 's3_1', positionId: 'バタフライガード', positionName: 'バタフライガード', techniqueId: 'スイープ', techniqueName: 'バタフライスイープ', notes: '両足のフックと体重移動が重要', order: 0),
          GamePlanStep(id: 's3_2', positionId: 'バタフライガード', positionName: 'バタフライガード', techniqueId: '三角絞め', techniqueName: '三角絞め', notes: 'スイープ防がれたら三角へ', order: 1),
          GamePlanStep(id: 's3_3', positionId: 'バックコントロール', positionName: 'バックコントロール', techniqueId: 'ボウ＆アロー', techniqueName: 'ボウ＆アロー', notes: 'バックを取れたらこれで締め', order: 2),
        ],
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
