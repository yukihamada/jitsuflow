import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/training_session.dart';
import '../services/journal_service.dart';

const _kBg = Color(0xFF09090B);
const _kSurface = Color(0xFF18181B);
const _kBorder = Color(0xFF27272A);
const _kAccent = Color(0xFFDC2626);
const _kMuted = Color(0xFF71717A);

const _kSessionTypes = ['gi', 'nogi', 'drilling', 'competition'];
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

const _kCommonTechniques = [
  'アームバー',
  '三角絞め',
  'ギロチン',
  'RNCチョーク',
  'ダースチョーク',
  'ニーオンベリー',
  'マウントポジション',
  'バックテイク',
  'ガードパス',
  'スイープ',
  'ダブルレッグ',
  'シングルレッグ',
  'バタフライガード',
  'デラヒーバガード',
  'ベリンボロ',
  'ヒールフック',
  'カーフスライサー',
  'クロスカラーチョーク',
  'ボウアンドアロー',
  'ワームガード',
];

class AddSessionScreen extends StatefulWidget {
  const AddSessionScreen({super.key});

  @override
  State<AddSessionScreen> createState() => _AddSessionScreenState();
}

class _AddSessionScreenState extends State<AddSessionScreen> {
  final _service = JournalService();
  final _notesController = TextEditingController();

  DateTime _date = DateTime.now();
  int _durationMinutes = 60;
  String _sessionType = 'gi';
  final Set<String> _selectedTechniques = {};
  int _energyLevel = 3;
  int _tapsGiven = 0;
  int _tapsReceived = 0;
  bool _saving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _kAccent,
            surface: _kSurface,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: _kSurface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final session = TrainingSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _date,
      durationMinutes: _durationMinutes,
      sessionType: _sessionType,
      techniques: _selectedTechniques.toList(),
      notes: _notesController.text.trim(),
      energyLevel: _energyLevel,
      tapsGiven: _tapsGiven,
      tapsReceived: _tapsReceived,
    );
    await _service.addSession(session);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: Colors.white,
        title: const Text(
          '練習を記録',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: _kAccent, strokeWidth: 2),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                        color: _kAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('日付', _buildDatePicker()),
            _buildSection('時間（分）', _buildDurationPicker()),
            _buildSection('セッションタイプ', _buildTypePicker()),
            _buildSection('テクニック', _buildTechniquePicker()),
            _buildSection('エネルギーレベル', _buildEnergyPicker()),
            _buildSection('タップ', _buildTapsRow()),
            _buildSection('メモ', _buildNotesField()),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _kMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        content,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: _kMuted, size: 16),
            const SizedBox(width: 12),
            Text(
              DateFormat('yyyy年M月d日 (E)', 'ja').format(_date),
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationPicker() {
    final presets = [30, 60, 90, 120];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: presets
              .map((m) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _durationMinutes = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _durationMinutes == m
                              ? _kAccent
                              : _kSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _durationMinutes == m
                                ? _kAccent
                                : _kBorder,
                          ),
                        ),
                        child: Text(
                          '$m分',
                          style: TextStyle(
                            color: _durationMinutes == m
                                ? Colors.white
                                : _kMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_durationMinutes > 5) {
                  setState(() => _durationMinutes -= 5);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: const Icon(Icons.remove, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$_durationMinutes 分',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _durationMinutes += 5),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _kBorder),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypePicker() {
    return Row(
      children: _kSessionTypes
          .map((type) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _sessionType = type),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _sessionType == type
                            ? (_kSessionColors[type] ??
                                    _kAccent)
                                .withValues(alpha: 0.15)
                            : _kSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _sessionType == type
                              ? (_kSessionColors[type] ?? _kAccent)
                              : _kBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _kSessionEmojis[type] ?? '',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type == 'gi'
                                ? 'Gi'
                                : type == 'nogi'
                                    ? 'No-Gi'
                                    : type == 'drilling'
                                        ? 'ドリル'
                                        : '試合',
                            style: TextStyle(
                              color: _sessionType == type
                                  ? Colors.white
                                  : _kMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTechniquePicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kCommonTechniques
          .map((t) => GestureDetector(
                onTap: () {
                  setState(() {
                    if (_selectedTechniques.contains(t)) {
                      _selectedTechniques.remove(t);
                    } else {
                      _selectedTechniques.add(t);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedTechniques.contains(t)
                        ? _kAccent.withValues(alpha: 0.15)
                        : _kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedTechniques.contains(t)
                          ? _kAccent
                          : _kBorder,
                    ),
                  ),
                  child: Text(
                    t,
                    style: TextStyle(
                      color: _selectedTechniques.contains(t)
                          ? _kAccent
                          : _kMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildEnergyPicker() {
    return Row(
      children: List.generate(
        5,
        (i) => GestureDetector(
          onTap: () => setState(() => _energyLevel = i + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              i < _energyLevel ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < _energyLevel ? Colors.amber : _kMuted,
              size: 36,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapsRow() {
    return Row(
      children: [
        Expanded(child: _buildTapCounter('タップした回数', _tapsGiven, (v) => setState(() => _tapsGiven = v))),
        const SizedBox(width: 12),
        Expanded(child: _buildTapCounter('タップされた回数', _tapsReceived, (v) => setState(() => _tapsReceived = v))),
      ],
    );
  }

  Widget _buildTapCounter(String label, int value, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: _kMuted, fontSize: 11),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () { if (value > 0) onChanged(value - 1); },
                child: const Icon(Icons.remove_circle_outline,
                    color: _kMuted, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                '$value',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onChanged(value + 1),
                child: const Icon(Icons.add_circle_outline,
                    color: _kAccent, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: _notesController,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: '今日の練習についてメモ...',
          hintStyle: TextStyle(color: _kMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }
}
