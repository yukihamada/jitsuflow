import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureAuthBloc, FeatureAuthState>(
      builder: (context, state) {
        final user = state is FeatureAuthAuthenticated ? state.user : null;
        return _MyPageContent(user: user);
      },
    );
  }
}

class _MyPageContent extends StatelessWidget {
  final UserModel? user;

  const _MyPageContent({this.user});

  String get _displayName => user?.name ?? user?.email ?? 'ゲスト';
  String get _email => user?.email ?? '';
  String get _belt => '青帯';
  String get _initials {
    final name = _displayName;
    if (name.isEmpty) return 'G';
    return name.characters.first.toUpperCase();
  }

  Color _beltColor(String belt) {
    switch (belt) {
      case '白帯':
        return const Color(0xFFF5F5F5);
      case '青帯':
        return const Color(0xFF3B82F6);
      case '紫帯':
        return const Color(0xFFA855F7);
      case '茶帯':
        return const Color(0xFF92400E);
      case '黒帯':
        return const Color(0xFF1C1C1C);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  void _logout(BuildContext context) {
    context.read<FeatureAuthBloc>().add(AuthLogoutRequested());
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileBlock(),
              const SizedBox(height: 20),
              _buildBeltRow(),
              const SizedBox(height: 28),
              const Divider(color: Color(0xFF1F1F23), thickness: 1),
              const SizedBox(height: 8),
              _buildMenuList(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileBlock() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFDC2626),
          child: Text(
            _initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              if (_email.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  _email,
                  style: const TextStyle(
                    color: Color(0xFF71717A),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBeltRow() {
    final beltColor = _beltColor(_belt);
    final displayColor = _belt == '白帯' ? const Color(0xFFA1A1AA) : beltColor;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: beltColor,
            shape: BoxShape.circle,
            border: _belt == '白帯'
                ? Border.all(color: const Color(0xFF71717A), width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _belt,
          style: TextStyle(
            color: displayColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          '·',
          style: TextStyle(color: Color(0xFF52525B), fontSize: 14),
        ),
        const SizedBox(width: 6),
        const Text(
          'JiuFlow Academy',
          style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildMenuList(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.workspace_premium,
        label: 'サブスクリプション',
        onTap: () => context.push('/subscription'),
        color: const Color(0xFFDC2626),
      ),
      _MenuItem(
        icon: Icons.menu_book_rounded,
        label: '練習日誌',
        onTap: () => context.push('/training-journal'),
      ),
      _MenuItem(
        icon: Icons.dashboard_outlined,
        label: '道場オーナーダッシュボード',
        onTap: () => context.push('/dojo-owner'),
      ),
      _MenuItem(
        icon: Icons.assignment_outlined,
        label: 'ゲームプラン',
        onTap: () => context.go('/game-plans'),
      ),
      _MenuItem(
        icon: Icons.school_outlined,
        label: 'インストラクター講座',
        onTap: () => context.push('/instructors'),
      ),
      _MenuItem(
        icon: Icons.forum_outlined,
        label: 'コミュニティ',
        onTap: () => context.push('/community'),
      ),
    ];

    return Column(
      children: [
        ...List.generate(items.length, (i) {
          return Column(
            children: [
              _buildMenuRow(items[i]),
              if (i < items.length - 1)
                const Divider(
                  color: Color(0xFF1F1F23),
                  height: 1,
                  indent: 38,
                ),
            ],
          );
        }),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFF1F1F23), height: 1),
        const SizedBox(height: 8),
        _buildMenuRow(
          _MenuItem(
            icon: Icons.settings_outlined,
            label: '設定',
            onTap: () {},
          ),
        ),
        const Divider(
          color: Color(0xFF1F1F23),
          height: 1,
          indent: 38,
        ),
        _buildLogoutRow(context),
      ],
    );
  }

  Widget _buildMenuRow(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(item.icon, size: 18, color: const Color(0xFF71717A)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF3F3F46),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutRow(BuildContext context) {
    return InkWell(
      onTap: () => _logout(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: const Row(
          children: [
            SizedBox(width: 30),
            Text(
              'ログアウト',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}
