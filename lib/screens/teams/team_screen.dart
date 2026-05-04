/**
 * チーム管理画面
 * ユーザーのチーム一覧、チーム作成、メンバー管理
 */

import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<Map<String, dynamic>> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      setState(() => _isLoading = true);
      final teams = await ApiService.getUserTeams();
      setState(() {
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('チームの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'admin':
        return '管理者';
      case 'member':
        return 'メンバー';
      case 'coach':
        return 'コーチ';
      default:
        return role ?? '';
    }
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'coach':
        return Colors.blue;
      case 'member':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    int selectedDojoId = 1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チームを作成'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'チーム名',
                  hintText: 'チーム名を入力',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '説明',
                  hintText: 'チームの説明を入力',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDojoId,
                decoration: const InputDecoration(
                  labelText: '所属道場',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('YAWARA JIU-JITSU ACADEMY')),
                  DropdownMenuItem(value: 2, child: Text('Over Limit Sapporo')),
                  DropdownMenuItem(value: 3, child: Text('スイープ')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedDojoId = value;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('チーム名を入力してください')),
                );
                return;
              }
              Navigator.pop(context);
              await _createTeam(
                nameController.text,
                descriptionController.text,
                selectedDojoId,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTeam(
    String name,
    String description,
    int dojoId,
  ) async {
    try {
      final success = await ApiService.createTeam(
        name: name,
        description: description,
        dojoId: dojoId,
      );
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('チームを作成しました')),
          );
        }
        await _loadTeams();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('チームの作成に失敗しました: $e')),
        );
      }
    }
  }

  void _showTeamDetail(Map<String, dynamic> team) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _TeamDetailView(team: team),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('チーム'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTeamDialog,
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('チーム作成'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.groups,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'チームがありません',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '新しいチームを作成してメンバーを招待しましょう',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showCreateTeamDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('チームを作成'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTeams,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      return _buildTeamCard(team);
                    },
                  ),
                ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    final roleColor = _getRoleColor(team['role']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTeamDetail(team),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Team icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Color(0xFF1B5E20),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Team name and dojo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                team['dojo_name'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: roleColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      _getRoleLabel(team['role']),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: roleColor,
                      ),
                    ),
                  ),
                ],
              ),

              if (team['description'] != null &&
                  (team['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  team['description'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Bottom action row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showTeamDetail(team),
                    icon: const Icon(Icons.people, size: 18),
                    label: const Text('メンバーを見る'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1B5E20),
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
}

/// チーム詳細画面（メンバー一覧付き）
class _TeamDetailView extends StatefulWidget {
  final Map<String, dynamic> team;

  const _TeamDetailView({required this.team});

  @override
  State<_TeamDetailView> createState() => _TeamDetailViewState();
}

class _TeamDetailViewState extends State<_TeamDetailView> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() => _isLoading = true);
      final teamId = widget.team['id'] as int;
      final members = await ApiService.getTeamMembers(teamId);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メンバーの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Color _getBeltColor(String? beltRank) {
    switch (beltRank) {
      case 'white':
        return Colors.grey.shade300;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'brown':
        return Colors.brown;
      case 'black':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  String _getBeltLabel(String? beltRank) {
    switch (beltRank) {
      case 'white':
        return '白帯';
      case 'blue':
        return '青帯';
      case 'purple':
        return '紫帯';
      case 'brown':
        return '茶帯';
      case 'black':
        return '黒帯';
      default:
        return beltRank ?? '';
    }
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'admin':
        return '管理者';
      case 'member':
        return 'メンバー';
      case 'coach':
        return 'コーチ';
      default:
        return role ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team['name'] ?? 'チーム詳細'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.groups,
                            color: Color(0xFF1B5E20),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.team['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget.team['dojo_name'] ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.team['description'] != null &&
                        (widget.team['description'] as String).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.team['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Members section
            Row(
              children: [
                const Icon(
                  Icons.people,
                  color: Color(0xFF1B5E20),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'メンバー',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_members.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _members.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'メンバーがいません',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: _members.map((member) {
                          final beltColor = _getBeltColor(member['belt_rank']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: beltColor.withValues(alpha: 0.2),
                                child: Text(
                                  (member['name'] ?? '?')[0],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: beltColor == Colors.grey.shade300
                                        ? Colors.grey.shade700
                                        : beltColor,
                                  ),
                                ),
                              ),
                              title: Text(
                                member['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _getBeltLabel(member['belt_rank']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: member['role'] == 'admin'
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getRoleLabel(member['role']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: member['role'] == 'admin'
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          ],
        ),
      ),
    );
  }
}
