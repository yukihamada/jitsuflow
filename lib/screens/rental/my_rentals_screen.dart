/**
 * レンタル履歴画面
 * ユーザーのアクティブ・過去のレンタル一覧を表示する画面
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  List<Map<String, dynamic>> _rentals = [];
  bool _isLoading = true;
  final _dateFormat = DateFormat('yyyy年MM月dd日');

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    try {
      setState(() => _isLoading = true);
      final rentals = await ApiService.getUserRentals();
      setState(() {
        _rentals = rentals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('レンタル履歴の読み込みに失敗しました: $e')),
        );
      }
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'レンタル中';
      case 'pending':
        return '申請中';
      case 'returned':
        return '返却済み';
      case 'overdue':
        return '延滞中';
      default:
        return status ?? '';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'returned':
        return Colors.grey;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'gi':
        return Icons.checkroom;
      case 'belt':
        return Icons.horizontal_rule;
      case 'protector':
        return Icons.shield;
      default:
        return Icons.inventory_2;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'gi':
        return Colors.blue;
      case 'belt':
        return Colors.orange;
      case 'protector':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  bool _isOverdue(Map<String, dynamic> rental) {
    if (rental['status'] == 'overdue') return true;
    if (rental['status'] != 'active') return false;
    final endDate = DateTime.parse(rental['end_date']);
    return DateTime.now().isAfter(endDate);
  }

  @override
  Widget build(BuildContext context) {
    final activeRentals = _rentals
        .where((r) => r['status'] == 'active' || r['status'] == 'overdue')
        .toList();
    final pastRentals = _rentals
        .where((r) => r['status'] != 'active' && r['status'] != 'overdue')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('レンタル履歴'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rentals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'レンタル履歴がありません',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'レンタルページから道着や防具をレンタルできます',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRentals,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (activeRentals.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_filled,
                                color: Color(0xFF1B5E20),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '現在レンタル中',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                  '${activeRentals.length}',
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
                          ...activeRentals.map(
                            (rental) => _buildRentalCard(rental),
                          ),
                          const SizedBox(height: 24),
                        ],
                        if (pastRentals.isNotEmpty) ...[
                          const Row(
                            children: [
                              Icon(
                                Icons.history,
                                color: Colors.grey,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '過去のレンタル',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...pastRentals.map(
                            (rental) => _buildRentalCard(rental),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildRentalCard(Map<String, dynamic> rental) {
    final startDate = DateTime.parse(rental['start_date']);
    final endDate = DateTime.parse(rental['end_date']);
    final isOverdue = _isOverdue(rental);
    final status = isOverdue ? 'overdue' : rental['status'] as String;
    final statusColor = _getStatusColor(status);
    final totalDays = endDate.difference(startDate).inDays;
    final totalCost = (rental['deposit_amount'] ?? 0) +
        ((rental['daily_rate'] ?? 0) * totalDays);

    // Calculate remaining days for active rentals
    String? remainingText;
    if (rental['status'] == 'active' && !isOverdue) {
      final remaining = endDate.difference(DateTime.now()).inDays;
      remainingText = '残り$remaining日';
    } else if (isOverdue) {
      final overdueDays = DateTime.now().difference(endDate).inDays;
      remainingText = '$overdueDays日延滞';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      color: isOverdue ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Category icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(rental['category']).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getCategoryIcon(rental['category']),
                    color: _getCategoryColor(rental['category']),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Item name and dates
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental['item_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_dateFormat.format(startDate)} ~ ${_dateFormat.format(endDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (remainingText != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        remainingText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOverdue ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Cost info
            Row(
              children: [
                _buildInfoChip(
                  'デポジット',
                  '¥${rental['deposit_amount']}',
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'レンタル料',
                  '¥${rental['daily_rate']}/日',
                ),
                const Spacer(),
                Text(
                  '合計: ¥${totalCost.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),

            // Overdue warning
            if (isOverdue) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '返却期限を過ぎています。速やかに返却してください。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
