import 'package:flutter/material.dart';
import '../../models/revenue_summary.dart';
import '../../services/api_service.dart';

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
  String _selectedPeriod = 'monthly';
  List<RevenueSummary> _revenueData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getRevenueSummary(_selectedPeriod);
      setState(() {
        _revenueData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('経営分析'),
        backgroundColor: const Color(0xFF1B5E20),
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
              const PopupMenuItem(value: 'weekly', child: Text('週間')),
              const PopupMenuItem(value: 'monthly', child: Text('月間')),
              const PopupMenuItem(value: 'quarterly', child: Text('四半期')),
              const PopupMenuItem(value: 'yearly', child: Text('年間')),
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1B5E20),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'データの読み込みに失敗しました',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadAnalyticsData,
                icon: const Icon(Icons.refresh),
                label: const Text('再読み込み'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_revenueData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'データがありません',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Summary
          _buildRevenueSection(),
          const SizedBox(height: 24),

          // Revenue Breakdown Chart
          _buildRevenueBreakdownChart(),
          const SizedBox(height: 24),

          // Revenue Trend Bar Chart
          _buildRevenueTrendChart(),
          const SizedBox(height: 24),

          // Cost & Profit Section
          _buildCostProfitSection(),
        ],
      ),
    );
  }

  Widget _buildRevenueSection() {
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
                  color: Color(0xFF1B5E20),
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

            // Total Revenue Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
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

            // Revenue Breakdown Cards
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    '会員費',
                    revenue.membershipRevenue,
                    const Color(0xFF1B5E20),
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

  Widget _buildRevenueCard(
      String title, int amount, Color color, IconData icon) {
    final formattedAmount =
        '¥${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

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

  Widget _buildRevenueBreakdownChart() {
    final revenue = _revenueData.first;
    final total = revenue.totalRevenue;
    if (total == 0) return const SizedBox.shrink();

    final membershipPct = revenue.membershipRevenue / total;
    final productPct = revenue.productRevenue / total;
    final rentalPct = revenue.rentalRevenue / total;

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
              '売上構成比',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Horizontal stacked bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 32,
                child: Row(
                  children: [
                    Expanded(
                      flex: (membershipPct * 1000).round(),
                      child: Container(color: const Color(0xFF1B5E20)),
                    ),
                    Expanded(
                      flex: (productPct * 1000).round(),
                      child: Container(color: Colors.blue),
                    ),
                    Expanded(
                      flex: (rentalPct * 1000).round(),
                      child: Container(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Legend
            _buildLegendItem(
              '会員費',
              revenue.membershipRevenue,
              (membershipPct * 100).toStringAsFixed(1),
              const Color(0xFF1B5E20),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              '物販',
              revenue.productRevenue,
              (productPct * 100).toStringAsFixed(1),
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildLegendItem(
              'レンタル',
              revenue.rentalRevenue,
              (rentalPct * 100).toStringAsFixed(1),
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
      String label, int amount, String percentage, Color color) {
    final formattedAmount =
        '¥${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const Spacer(),
        Text(
          formattedAmount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$percentage%',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueTrendChart() {
    final revenue = _revenueData.first;
    final maxValue = revenue.totalRevenue.toDouble();
    if (maxValue == 0) return const SizedBox.shrink();

    // Build bar data from the revenue categories
    final barData = [
      _BarData('会員費', revenue.membershipRevenue.toDouble(), const Color(0xFF1B5E20)),
      _BarData('物販', revenue.productRevenue.toDouble(), Colors.blue),
      _BarData('レンタル', revenue.rentalRevenue.toDouble(), Colors.orange),
      _BarData('コスト', revenue.instructorCosts.toDouble(), Colors.red[300]!),
      _BarData('粗利益', revenue.grossProfit.toDouble(), Colors.teal),
    ];

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
              '売上内訳グラフ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: barData.map((bar) {
                  final heightRatio = maxValue > 0 ? bar.value / maxValue : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatShortAmount(bar.value.round()),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: bar.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            height: 160 * heightRatio,
                            decoration: BoxDecoration(
                              color: bar.color,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            bar.label,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostProfitSection() {
    final revenue = _revenueData.first;

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
              'コスト・利益分析',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCostRow(
              '総売上',
              revenue.formattedTotalRevenue,
              const Color(0xFF1B5E20),
              Icons.account_balance_wallet,
            ),
            const Divider(height: 24),
            _buildCostRow(
              'インストラクター費用',
              revenue.formattedInstructorCosts,
              Colors.red[400]!,
              Icons.person,
            ),
            const Divider(height: 24),
            _buildCostRow(
              '粗利益',
              revenue.formattedGrossProfit,
              Colors.teal,
              Icons.trending_up,
            ),
            const SizedBox(height: 16),

            // Profit margin indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getProfitMarginColor(revenue.profitMargin)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getProfitMarginColor(revenue.profitMargin)
                      .withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    revenue.profitMargin >= 50
                        ? Icons.sentiment_very_satisfied
                        : revenue.profitMargin >= 30
                            ? Icons.sentiment_satisfied
                            : Icons.sentiment_dissatisfied,
                    color: _getProfitMarginColor(revenue.profitMargin),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '利益率',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${revenue.profitMargin.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color:
                              _getProfitMarginColor(revenue.profitMargin),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _getProfitMarginLabel(revenue.profitMargin),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getProfitMarginColor(revenue.profitMargin),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(
      String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getProfitMarginColor(double margin) {
    if (margin >= 50) return const Color(0xFF1B5E20);
    if (margin >= 30) return Colors.orange;
    return Colors.red;
  }

  String _getProfitMarginLabel(double margin) {
    if (margin >= 50) return '良好';
    if (margin >= 30) return '普通';
    return '要改善';
  }

  String _formatShortAmount(int amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}万';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}千';
    }
    return '$amount';
  }

  String _getPeriodDisplay(String period) {
    switch (period) {
      case 'weekly':
        return '週間';
      case 'monthly':
        return '月間';
      case 'quarterly':
        return '四半期';
      case 'yearly':
        return '年間';
      default:
        return '月間';
    }
  }
}

class _BarData {
  final String label;
  final double value;
  final Color color;

  _BarData(this.label, this.value, this.color);
}
