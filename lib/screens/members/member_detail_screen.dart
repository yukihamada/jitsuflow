import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/member/member_bloc.dart';
import '../../models/member.dart';
import 'member_edit_screen.dart';

class MemberDetailScreen extends StatelessWidget {
  final Member member;

  const MemberDetailScreen({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(member.name),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MemberEditScreen(member: member),
                    ),
                  );
                  break;
                case 'delete':
                  _showDeleteConfirmation(context);
                  break;
                case 'change_role':
                  _showRoleChangeDialog(context);
                  break;
                case 'change_status':
                  _showStatusChangeDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('編集'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'change_role',
                child: ListTile(
                  leading: Icon(Icons.admin_panel_settings),
                  title: Text('ロール変更'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'change_status',
                child: ListTile(
                  leading: Icon(Icons.toggle_on),
                  title: Text('ステータス変更'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('削除', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: BlocListener<MemberBloc, MemberState>(
        listener: (context, state) {
          if (state is MemberDeleteSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('メンバーを削除しました'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is MemberUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('更新しました'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is MemberFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: _getAvatarColor(member.role),
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(member.role).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    member.roleDisplay,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _getRoleColor(member.role),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(member.status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    member.statusDisplay,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _getStatusColor(member.status),
                                      fontWeight: FontWeight.bold,
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
                ),
              ),
              const SizedBox(height: 16),

              // Basic Information
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '基本情報',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('電話番号', member.phone ?? '未設定'),
                      _buildInfoRow('帯', member.beltRankDisplay),
                      if (member.birthDate != null)
                        _buildInfoRow(
                          '生年月日',
                          '${member.birthDate!.year}年${member.birthDate!.month}月${member.birthDate!.day}日',
                        ),
                      _buildInfoRow('主所属道場', member.primaryDojoName ?? '未設定'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subscription Status
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'サブスクリプション',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            member.hasActiveSubscription
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: member.hasActiveSubscription
                                ? Colors.green
                                : Colors.grey,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            member.hasActiveSubscription
                                ? 'プレミアムプラン契約中'
                                : '未契約',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: member.hasActiveSubscription
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Activity Information
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'アクティビティ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        '登録日',
                        '${member.joinedAt.year}年${member.joinedAt.month}月${member.joinedAt.day}日',
                      ),
                      if (member.lastLoginAt != null)
                        _buildInfoRow(
                          '最終ログイン',
                          '${member.lastLoginAt!.year}年${member.lastLoginAt!.month}月${member.lastLoginAt!.day}日',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              if (member.status != 'suspended')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Send message
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'メッセージを送る',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text('${member.name}さんを削除してもよろしいですか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<MemberBloc>().add(
                MemberDeleteRequested(memberId: member.id),
              );
            },
            child: const Text(
              '削除',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ロール変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('一般会員'),
              value: 'user',
              groupValue: member.role,
              onChanged: (value) {
                Navigator.pop(dialogContext);
                if (value != null && value != member.role) {
                  context.read<MemberBloc>().add(
                    MemberRoleChangeRequested(
                      memberId: member.id,
                      newRole: value,
                    ),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('インストラクター'),
              value: 'instructor',
              groupValue: member.role,
              onChanged: (value) {
                Navigator.pop(dialogContext);
                if (value != null && value != member.role) {
                  context.read<MemberBloc>().add(
                    MemberRoleChangeRequested(
                      memberId: member.id,
                      newRole: value,
                    ),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('管理者'),
              value: 'admin',
              groupValue: member.role,
              onChanged: (value) {
                Navigator.pop(dialogContext);
                if (value != null && value != member.role) {
                  context.read<MemberBloc>().add(
                    MemberRoleChangeRequested(
                      memberId: member.id,
                      newRole: value,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ステータス変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('アクティブ'),
              value: 'active',
              groupValue: member.status,
              onChanged: (value) {
                Navigator.pop(dialogContext);
                if (value != null && value != member.status) {
                  context.read<MemberBloc>().add(
                    MemberStatusChangeRequested(
                      memberId: member.id,
                      newStatus: value,
                    ),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('非アクティブ'),
              value: 'inactive',
              groupValue: member.status,
              onChanged: (value) {
                Navigator.pop(dialogContext);
                if (value != null && value != member.status) {
                  context.read<MemberBloc>().add(
                    MemberStatusChangeRequested(
                      memberId: member.id,
                      newStatus: value,
                    ),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('停止中'),
              value: 'suspended',
              groupValue: member.status,
              onChanged: (value) {
                Navigator.pop(dialogContext);
                if (value != null && value != member.status) {
                  context.read<MemberBloc>().add(
                    MemberStatusChangeRequested(
                      memberId: member.id,
                      newStatus: value,
                    ),
                  );
                }
              },
            ),
          ],
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
}