import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'class_checkin_screen.dart';

class _ClassInfo {
  final String id;
  final String name;
  final String time;
  final int enrolled;
  final int capacity;

  const _ClassInfo({
    required this.id,
    required this.name,
    required this.time,
    required this.enrolled,
    required this.capacity,
  });
}

class _ReservationInfo {
  final String userName;
  final String className;
  final String time;
  final String status; // 'confirmed', 'pending', 'cancelled'

  const _ReservationInfo({
    required this.userName,
    required this.className,
    required this.time,
    required this.status,
  });
}

class DojoOwnerScreen extends StatelessWidget {
  const DojoOwnerScreen({super.key});

  static final List<_ClassInfo> _todayClasses = [
    _ClassInfo(
        id: 'c1', name: '基礎クラス', time: '10:00 - 11:30', enrolled: 8, capacity: 15),
    _ClassInfo(
        id: 'c2', name: 'ノーギクラス', time: '13:00 - 14:30', enrolled: 12, capacity: 12),
    _ClassInfo(
        id: 'c3', name: '競技クラス', time: '19:00 - 21:00', enrolled: 6, capacity: 10),
  ];

  static final List<_ReservationInfo> _recentReservations = [
    _ReservationInfo(
        userName: '田中花子', className: '基礎クラス', time: '10:00', status: 'confirmed'),
    _ReservationInfo(
        userName: '山田次郎', className: 'ノーギクラス', time: '13:00', status: 'pending'),
    _ReservationInfo(
        userName: '鈴木太郎', className: '競技クラス', time: '19:00', status: 'confirmed'),
    _ReservationInfo(
        userName: '伊藤美咲', className: '基礎クラス', time: '10:00', status: 'cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeatureAuthBloc, FeatureAuthState>(
      builder: (context, state) {
        if (state is! FeatureAuthAuthenticated ||
            state.user.role != 'dojo_owner') {
          return _buildNonOwnerView(context);
        }

        final userName = state.user.name ?? state.user.email;

        return _buildDashboard(context, userName);
      },
    );
  }

  Widget _buildNonOwnerView(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('道場オーナー'),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront,
                    color: Color(0xFFDC2626), size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                '道場オーナーダッシュボード',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                '道場オーナーとして登録すると、クラス管理・予約管理・売上分析などの機能が使えます。',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFA1A1AA), height: 1.6),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('道場オーナー登録は近日公開予定です')),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('道場オーナーとして登録する',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, String ownerName) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('ダッシュボード'),
        backgroundColor: const Color(0xFF09090B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(ownerName),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildTodayClasses(context),
            const SizedBox(height: 24),
            _buildRecentReservations(),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String ownerName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'JiuFlow 渋谷道場',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$ownerName さん、おはようございます',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      ('今日の予約', '14件', const Color(0xFFDC2626)),
      ('今月の売上', '¥248,000', const Color(0xFF22C55E)),
      ('総会員数', '87名', const Color(0xFFF59E0B)),
      ('出席率', '78%', const Color(0xFF06B6D4)),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final s = stats[index];
          return Container(
            width: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.$1,
                  style: const TextStyle(
                    color: Color(0xFFA1A1AA),
                    fontSize: 11,
                  ),
                ),
                Text(
                  s.$2,
                  style: TextStyle(
                    color: s.$3,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayClasses(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('今日のクラス'),
        const SizedBox(height: 12),
        ..._todayClasses.map((c) => _buildClassCard(context, c)),
      ],
    );
  }

  Widget _buildClassCard(BuildContext context, _ClassInfo cls) {
    final isFull = cls.enrolled >= cls.capacity;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cls.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 13, color: Color(0xFFA1A1AA)),
                    const SizedBox(width: 4),
                    Text(
                      cls.time,
                      style: const TextStyle(
                          color: Color(0xFFA1A1AA), fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.people_outline,
                        size: 13, color: Color(0xFFA1A1AA)),
                    const SizedBox(width: 4),
                    Text(
                      '${cls.enrolled}/${cls.capacity}名',
                      style: TextStyle(
                        color: isFull
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFFA1A1AA),
                        fontSize: 12,
                        fontWeight: isFull ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClassCheckinScreen(
                    classId: cls.id,
                    className: cls.name,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 12),
            ),
            child: const Text('チェックイン'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReservations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('最近の予約'),
        const SizedBox(height: 12),
        ..._recentReservations.map(_buildReservationCard),
      ],
    );
  }

  Widget _buildReservationCard(_ReservationInfo r) {
    Color statusColor;
    String statusLabel;
    switch (r.status) {
      case 'confirmed':
        statusColor = const Color(0xFF22C55E);
        statusLabel = '確定';
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        statusLabel = '保留';
        break;
      default:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'キャンセル';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF3F3F46),
            child: Text(
              r.userName.characters.first,
              style: const TextStyle(
                color: Color(0xFFA1A1AA),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.userName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
                Text(
                  '${r.className} · ${r.time}',
                  style: const TextStyle(
                      color: Color(0xFFA1A1AA), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('クイックアクション'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'クラスを追加',
                color: const Color(0xFFDC2626),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.how_to_reg_outlined,
                label: '出席を記録',
                color: const Color(0xFF22C55E),
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildActionButton(
                icon: Icons.person_add_outlined,
                label: '会員を追加',
                color: const Color(0xFFF59E0B),
                onTap: () => context.go('/members'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
