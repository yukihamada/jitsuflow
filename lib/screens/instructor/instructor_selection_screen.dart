/**
 * インストラクター選択画面
 * 生徒が担当インストラクターを設定する画面
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_widget.dart';

class InstructorSelectionScreen extends StatefulWidget {
  final int dojoId;
  
  const InstructorSelectionScreen({
    super.key,
    required this.dojoId,
  });

  @override
  State<InstructorSelectionScreen> createState() => _InstructorSelectionScreenState();
}

class _InstructorSelectionScreenState extends State<InstructorSelectionScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _availableInstructors = [];
  List<Map<String, dynamic>> _myInstructors = [];
  Set<int> _favoriteInstructorIds = {};
  bool _isLoading = true;
  String? _selectedAssignmentType = 'primary';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // 利用可能なインストラクター一覧取得
      final availableResponse = await _apiService.get(
        '/api/dojos/${widget.dojoId}/available-instructors'
      );
      
      // 自分の担当インストラクター取得
      final userId = await _apiService.getCurrentUserId();
      final myInstructorsResponse = await _apiService.get(
        '/api/students/$userId/instructors'
      );
      
      setState(() {
        _availableInstructors = List<Map<String, dynamic>>.from(
          availableResponse['instructors'] ?? []
        );
        _myInstructors = List<Map<String, dynamic>>.from(
          myInstructorsResponse['assignments'] ?? []
        );
        _favoriteInstructorIds = Set<int>.from(
          (myInstructorsResponse['favorites'] ?? [])
            .map((f) => f['instructor_id'] as int)
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('データの取得に失敗しました: $e')),
      );
    }
  }

  Future<void> _assignInstructor(int instructorId) async {
    try {
      final userId = await _apiService.getCurrentUserId();
      
      await _apiService.post(
        '/api/students/$userId/instructors',
        {
          'instructor_id': instructorId,
          'dojo_id': widget.dojoId,
          'assignment_type': _selectedAssignmentType,
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('担当インストラクターを設定しました')),
      );
      
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('設定に失敗しました: $e')),
      );
    }
  }

  Future<void> _toggleFavorite(int instructorId) async {
    try {
      final userId = await _apiService.getCurrentUserId();
      final isFavorite = _favoriteInstructorIds.contains(instructorId);
      
      await _apiService.post(
        '/api/students/$userId/favorite-instructors',
        {
          'instructor_id': instructorId,
          'action': isFavorite ? 'remove' : 'add',
        },
      );
      
      setState(() {
        if (isFavorite) {
          _favoriteInstructorIds.remove(instructorId);
        } else {
          _favoriteInstructorIds.add(instructorId);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('お気に入り設定に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('インストラクター選択'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
        ? const LoadingWidget()
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 現在の担当インストラクター
                  if (_myInstructors.isNotEmpty) ...[
                    Text(
                      '現在の担当インストラクター',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._myInstructors.map((assignment) => _buildCurrentInstructorCard(assignment)),
                    const SizedBox(height: 32),
                  ],
                  
                  // 担当タイプ選択
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '担当タイプを選択',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('主担当'),
                                  subtitle: const Text('メインの指導者'),
                                  value: 'primary',
                                  groupValue: _selectedAssignmentType,
                                  onChanged: (value) => setState(() => _selectedAssignmentType = value),
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('副担当'),
                                  subtitle: const Text('サブの指導者'),
                                  value: 'secondary',
                                  groupValue: _selectedAssignmentType,
                                  onChanged: (value) => setState(() => _selectedAssignmentType = value),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 利用可能なインストラクター一覧
                  Text(
                    '利用可能なインストラクター',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_availableInstructors.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          '利用可能なインストラクターがいません',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._availableInstructors.map((instructor) => _buildInstructorCard(instructor)),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCurrentInstructorCard(Map<String, dynamic> assignment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: assignment['assignment_type'] == 'primary' 
            ? Colors.blue 
            : Colors.green,
          child: Text(
            assignment['instructor_name']?.substring(0, 1) ?? '',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          assignment['instructor_name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${assignment['instructor_belt'] ?? ''} • ${assignment['dojo_name'] ?? ''}'),
            Text(
              assignment['assignment_type'] == 'primary' ? '主担当' : '副担当',
              style: TextStyle(
                color: assignment['assignment_type'] == 'primary' 
                  ? Colors.blue 
                  : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showUnassignDialog(assignment),
        ),
      ),
    );
  }

  Widget _buildInstructorCard(Map<String, dynamic> instructor) {
    final isAssigned = _myInstructors.any((a) => a['instructor_id'] == instructor['id']);
    final isFavorite = _favoriteInstructorIds.contains(instructor['id']);
    final rating = (instructor['avg_rating'] ?? 0).toDouble();
    final totalRatings = instructor['total_ratings'] ?? 0;
    final totalStudents = instructor['total_students'] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isAssigned ? null : () => _showAssignDialog(instructor),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      instructor['name']?.substring(0, 1) ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              instructor['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isAssigned)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '担当中',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          instructor['belt_rank'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.star : Icons.star_border,
                      color: isFavorite ? Colors.amber : Colors.grey,
                    ),
                    onPressed: () => _toggleFavorite(instructor['id']),
                  ),
                ],
              ),
              
              if (instructor['instructor_bio'] != null && instructor['instructor_bio'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  instructor['instructor_bio'],
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              if (instructor['specialties'] != null && (instructor['specialties'] as List).isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (instructor['specialties'] as List).map((specialty) => 
                    Chip(
                      label: Text(
                        specialty,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                  ).toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              Row(
                children: [
                  // 評価
                  if (totalRatings > 0) ...[
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ' ($totalRatings件)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  
                  // 生徒数
                  Icon(Icons.people, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '$totalStudents人',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  
                  const Spacer(),
                  
                  if (!isAssigned)
                    ElevatedButton.icon(
                      onPressed: () => _showAssignDialog(instructor),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('担当に設定'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignDialog(Map<String, dynamic> instructor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('担当インストラクター設定'),
        content: Text(
          '${instructor['name']}先生を${_selectedAssignmentType == 'primary' ? '主担当' : '副担当'}として設定しますか？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _assignInstructor(instructor['id']);
            },
            child: const Text('設定'),
          ),
        ],
      ),
    );
  }

  void _showUnassignDialog(Map<String, dynamic> assignment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('担当解除'),
        content: Text('${assignment['instructor_name']}先生の担当を解除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId = await _apiService.getCurrentUserId();
                await _apiService.delete(
                  '/api/students/$userId/instructors/${assignment['id']}'
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('担当を解除しました')),
                );
                await _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('解除に失敗しました: $e')),
                );
              }
            },
            child: const Text('解除'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}