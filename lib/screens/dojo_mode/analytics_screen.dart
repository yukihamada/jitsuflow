import 'package:flutter/material.dart';
import '../../models/revenue_summary.dart';

class AnalyticsScreen extends StatefulWidget {
  final int dojoId;
  
  const AnalyticsScreen({
    super.key,
    required this.dojoId,
  });

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'month';
  List<RevenueSummary> _revenueData = [];
  Map<String, dynamic> _kpiData = {};

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    // TODO: Load from API
    // Dummy data for demo
    setState(() {
      _revenueData = [
        RevenueSummary(
          dojoId: widget.dojoId,
          dojoName: 'デモ道場',
          period: DateTime.now(),
          membershipRevenue: 850000,
          productRevenue: 120000,
          rentalRevenue: 35000,
          totalRevenue: 1005000,
          instructorCosts: 350000,
          grossProfit: 655000,
        ),
      ];
      
      _kpiData = {
        'total_members': 45,
        'active_members': 38,
        'new_members_this_month': 3,
        'retention_rate': 92.5,
        'average_revenue_per_member': 26315,
        'class_attendance_rate': 78.5,
        'instructor_utilization': 85.0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('経営分析'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
              _loadAnalyticsData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('週間')),
              const PopupMenuItem(value: 'month', child: Text('月間')),
              const PopupMenuItem(value: 'quarter', child: Text('四半期')),
              const PopupMenuItem(value: 'year', child: Text('年間')),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPeriodDisplay(_selectedPeriod),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnalyticsData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Revenue Summary
              _buildRevenueSection(),
              const SizedBox(height: 24),
              
              // KPI Cards
              _buildKPISection(),
              const SizedBox(height: 24),
              
              // Charts Section
              _buildChartsSection(),
              const SizedBox(height: 24),
              
              // Instructor Performance
              _buildInstructorSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueSection() {
    if (_revenueData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final revenue = _revenueData.first;
    
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  color: Colors.purple,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_getPeriodDisplay(_selectedPeriod)}売上',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Total Revenue
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.deepPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '総売上',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        revenue.formattedTotalRevenue,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '粗利益',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        revenue.formattedGrossProfit,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '利益率: ${revenue.profitMargin.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Revenue Breakdown
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    '会員費',
                    revenue.membershipRevenue,
                    Colors.green,
                    Icons.people,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    '物販',
                    revenue.productRevenue,
                    Colors.blue,
                    Icons.shopping_bag,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'レンタル',
                    revenue.rentalRevenue,
                    Colors.orange,
                    Icons.inventory,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String title, int amount, Color color, IconData icon) {
    final formattedAmount = '¥${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KPI指標',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildKPICard(
              '総会員数',
              '${_kpiData['total_members'] ?? 0}人',
              Icons.people,
              Colors.blue,
            ),
            _buildKPICard(
              'アクティブ会員',
              '${_kpiData['active_members'] ?? 0}人',
              Icons.person_pin,
              Colors.green,
            ),
            _buildKPICard(
              '継続率',
              '${_kpiData['retention_rate'] ?? 0}%',
              Icons.trending_up,
              Colors.purple,
            ),
            _buildKPICard(
              '出席率',
              '${_kpiData['class_attendance_rate'] ?? 0}%',
              Icons.check_circle,
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '売上推移',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'チャートライブラリ統合予定',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'インストラクター実績',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInstructorItem(
              '村田良蔵',
              45,
              280000,
              '黒帯',
            ),
            const Divider(),
            _buildInstructorItem(
              '廣鰭翔大',
              32,
              190000,
              '茶帯',
            ),
            const Divider(),
            _buildInstructorItem(
              '佐藤正幸',
              28,
              150000,
              '紫帯',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructorItem(String name, int classes, int payment, String belt) {
    final formattedPayment = '¥${payment.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getBeltColor(belt),
            child: Text(
              name[0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$belt • ${classes}クラス担当',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formattedPayment,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBeltColor(String belt) {
    switch (belt) {
      case '黒帯':
        return Colors.black;
      case '茶帯':
        return Colors.brown;
      case '紫帯':
        return Colors.purple;
      case '青帯':
        return Colors.blue;
      case '白帯':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPeriodDisplay(String period) {
    switch (period) {
      case 'week':
        return '週間';
      case 'month':
        return '月間';
      case 'quarter':
        return '四半期';
      case 'year':
        return '年間';
      default:
        return '月間';
    }
  }
}