import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/member/member_bloc.dart';
import '../../models/member.dart';
import '../../widgets/common/loading_widget.dart';
import 'member_detail_screen.dart';
import 'member_create_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _searchController = TextEditingController();
  String? _selectedRole;
  String? _selectedStatus;
  String? _selectedBeltRank;

  @override
  void initState() {
    super.initState();
    context.read<MemberBloc>().add(const MemberLoadRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メンバー管理'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemberCreateScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'メンバーを検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                _applyFilters();
              },
            ),
          ),
          
          // Filter Chips
          if (_selectedRole != null || _selectedStatus != null || _selectedBeltRank != null)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedRole != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_getRoleDisplay(_selectedRole!)),
                        onDeleted: () {
                          setState(() {
                            _selectedRole = null;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  if (_selectedStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(_getStatusDisplay(_selectedStatus!)),
                        onDeleted: () {
                          setState(() {
                            _selectedStatus = null;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  if (_selectedBeltRank != null)
                    Chip(
                      label: Text(_getBeltRankDisplay(_selectedBeltRank!)),
                      onDeleted: () {
                        setState(() {
                          _selectedBeltRank = null;
                        });
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),
          
          // Members List
          Expanded(
            child: BlocBuilder<MemberBloc, MemberState>(
              builder: (context, state) {
                if (state is MemberLoading) {
                  return const Center(
                    child: LoadingWidget(
                      color: Color(0xFF1B5E20),
                      size: 40,
                    ),
                  );
                }
                
                if (state is MemberFailure) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'エラーが発生しました',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<MemberBloc>().add(const MemberLoadRequested());
                          },
                          child: const Text('再試行'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (state is MemberLoadSuccess) {
                  if (state.members.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'メンバーが見つかりません',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '新しいメンバーを追加してください',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<MemberBloc>().add(const MemberLoadRequested());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.members.length,
                      itemBuilder: (context, index) {
                        final member = state.members[index];
                        return _MemberCard(member: member);
                      },
                    ),
                  );
                }
                
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フィルター'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ロール'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('一般会員'),
                  selected: _selectedRole == 'user',
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = selected ? 'user' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('インストラクター'),
                  selected: _selectedRole == 'instructor',
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = selected ? 'instructor' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('管理者'),
                  selected: _selectedRole == 'admin',
                  onSelected: (selected) {
                    setState(() {
                      _selectedRole = selected ? 'admin' : null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('ステータス'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('アクティブ'),
                  selected: _selectedStatus == 'active',
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? 'active' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('非アクティブ'),
                  selected: _selectedStatus == 'inactive',
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? 'inactive' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('停止中'),
                  selected: _selectedStatus == 'suspended',
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = selected ? 'suspended' : null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('帯'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('白'),
                  selected: _selectedBeltRank == 'white',
                  onSelected: (selected) {
                    setState(() {
                      _selectedBeltRank = selected ? 'white' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('青'),
                  selected: _selectedBeltRank == 'blue',
                  onSelected: (selected) {
                    setState(() {
                      _selectedBeltRank = selected ? 'blue' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('紫'),
                  selected: _selectedBeltRank == 'purple',
                  onSelected: (selected) {
                    setState(() {
                      _selectedBeltRank = selected ? 'purple' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('茶'),
                  selected: _selectedBeltRank == 'brown',
                  onSelected: (selected) {
                    setState(() {
                      _selectedBeltRank = selected ? 'brown' : null;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('黒'),
                  selected: _selectedBeltRank == 'black',
                  onSelected: (selected) {
                    setState(() {
                      _selectedBeltRank = selected ? 'black' : null;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedRole = null;
                _selectedStatus = null;
                _selectedBeltRank = null;
              });
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('クリア'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyFilters();
            },
            child: const Text('適用'),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    context.read<MemberBloc>().add(
      MemberFilterRequested(
        role: _selectedRole,
        status: _selectedStatus,
        beltRank: _selectedBeltRank,
        searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
      ),
    );
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'admin':
        return '管理者';
      case 'instructor':
        return 'インストラクター';
      case 'user':
        return '一般会員';
      default:
        return role;
    }
  }

  String _getStatusDisplay(String status) {
    switch (status) {
      case 'active':
        return 'アクティブ';
      case 'inactive':
        return '非アクティブ';
      case 'suspended':
        return '停止中';
      default:
        return status;
    }
  }

  String _getBeltRankDisplay(String beltRank) {
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
        return beltRank;
    }
  }
}

class _MemberCard extends StatelessWidget {
  final Member member;

  const _MemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberDetailScreen(member: member),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: _getAvatarColor(member.role),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (member.hasActiveSubscription)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'プレミアム',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(member.role).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.roleDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getRoleColor(member.role),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(member.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.statusDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(member.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (member.beltRank != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getBeltColor(member.beltRank!).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              member.beltRankDisplay,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getBeltColor(member.beltRank!),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'instructor':
        return Colors.blue;
      default:
        return const Color(0xFF1B5E20);
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'instructor':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.orange;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getBeltColor(String beltRank) {
    switch (beltRank) {
      case 'white':
        return Colors.grey;
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
}