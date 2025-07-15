/**
 * インストラクター専用ダッシュボード画面
 * 給与確認・スケジュール管理・実績確認が可能
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/user.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/instructor/instructor_stats_card.dart';
import '../../widgets/instructor/instructor_schedule_card.dart';
import '../../widgets/instructor/instructor_payroll_card.dart';
import '../../widgets/instructor/instructor_rating_card.dart';

class InstructorDashboardScreen extends StatefulWidget {
  const InstructorDashboardScreen({super.key});

  @override
  State<InstructorDashboardScreen> createState() => _InstructorDashboardScreenState();
}

class _InstructorDashboardScreenState extends State<InstructorDashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    // TODO: APIからインストラクターデータを取得
    await Future.delayed(const Duration(seconds: 1)); // シミュレーション

    return {
      'stats': {
        'classes_this_month': 24,
        'total_students': 180,
        'avg_rating': 4.7,
        'earnings_this_month': 150000,
      },
      'upcoming_classes': [
        {
          'id': 1,
          'class_type': 'BJJ基礎',
          'date': '2024-01-15',
          'time': '19:00-20:30',
          'dojo': 'メイン道場',
          'current_bookings': 8,
          'max_capacity': 12,
        },
        {
          'id': 2,
          'class_type': 'ノーギ',
          'date': '2024-01-16',
          'time': '20:00-21:30',
          'dojo': 'メイン道場',
          'current_bookings': 15,
          'max_capacity': 16,
        },
      ],
      'recent_ratings': [
        {
          'student_name': '田中 太郎',
          'class_type': 'BJJ基礎',
          'overall_rating': 5,
          'feedback': '非常に分かりやすい指導でした',
          'date': '2024-01-10',
        },
        {
          'student_name': '佐藤 花子',
          'class_type': 'ノーギ',
          'overall_rating': 4,
          'feedback': 'テクニックが向上しました',
          'date': '2024-01-08',
        },
      ],
      'payroll_summary': {
        'current_month': {
          'gross_amount': 180000,
          'deductions': 30000,
          'net_amount': 150000,
          'status': 'pending',
        },
        'last_month': {
          'gross_amount': 175000,
          'deductions': 25000,
          'net_amount': 150000,
          'status': 'paid',
        },
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('インストラクター ダッシュボード'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: 通知画面へ遷移
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: プロフィール編集画面へ遷移
                  break;
                case 'logout':
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Text('プロフィール編集'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('ログアウト'),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('データの読み込みに失敗しました\n${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _dashboardData = _loadDashboardData();
                      });
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardData = _loadDashboardData();
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 今月の実績サマリー
                  Text(
                    '今月の実績',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InstructorStatsCard(stats: data['stats']),
                  
                  const SizedBox(height: 24),
                  
                  // 今後のクラス
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '今後のクラス',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/instructor/schedule');
                        },
                        child: const Text('すべて見る'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InstructorScheduleCard(
                    upcomingClasses: List<Map<String, dynamic>>.from(
                      data['upcoming_classes']
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 給与情報
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '給与情報',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/instructor/payroll');
                        },
                        child: const Text('詳細'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InstructorPayrollCard(payrollSummary: data['payroll_summary']),
                  
                  const SizedBox(height: 24),
                  
                  // 最近の評価
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '最近の評価',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/instructor/ratings');
                        },
                        child: const Text('すべて見る'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InstructorRatingCard(
                    recentRatings: List<Map<String, dynamic>>.from(
                      data['recent_ratings']
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // クイックアクション
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'クイックアクション',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionButton(
                                  context,
                                  'スケジュール確認',
                                  Icons.schedule,
                                  () => Navigator.pushNamed(context, '/instructor/schedule'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickActionButton(
                                  context,
                                  '出席確認',
                                  Icons.how_to_reg,
                                  () => Navigator.pushNamed(context, '/instructor/attendance'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildQuickActionButton(
                                  context,
                                  'クラス報告',
                                  Icons.assignment,
                                  () => Navigator.pushNamed(context, '/instructor/report'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickActionButton(
                                  context,
                                  'プロフィール',
                                  Icons.person,
                                  () => Navigator.pushNamed(context, '/instructor/profile'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }
}