/**
 * インストラクター給与カード
 * 今月・先月の給与情報を表示
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InstructorPayrollCard extends StatelessWidget {
  final Map<String, dynamic> payrollSummary;

  const InstructorPayrollCard({
    super.key,
    required this.payrollSummary,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final currentMonth = payrollSummary['current_month'];
    final lastMonth = payrollSummary['last_month'];

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payments,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '給与情報',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 今月の給与
            _buildPayrollSection(
              context,
              '今月の給与',
              currentMonth,
              isPrimary: true,
            ),
            
            const SizedBox(height: 16),
            
            // 先月の給与
            _buildPayrollSection(
              context,
              '先月の給与',
              lastMonth,
              isPrimary: false,
            ),
            
            const SizedBox(height: 16),
            
            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: 給与明細詳細画面へ遷移
                    },
                    icon: const Icon(Icons.description, size: 18),
                    label: const Text('給与明細'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 給与履歴画面へ遷移
                    },
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('給与履歴'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollSection(
    BuildContext context,
    String title,
    Map<String, dynamic> payrollData,
    {required bool isPrimary}
  ) {
    final numberFormat = NumberFormat('#,###');
    final grossAmount = payrollData['gross_amount'] as int;
    final deductions = payrollData['deductions'] as int;
    final netAmount = payrollData['net_amount'] as int;
    final status = payrollData['status'] as String;
    
    // ステータスの表示設定
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'paid':
        statusColor = Colors.green;
        statusText = '支払済';
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = '支払待';
        statusIcon = Icons.schedule;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusText = '処理中';
        statusIcon = Icons.sync;
        break;
      default:
        statusColor = Colors.grey;
        statusText = '未確定';
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary 
          ? Theme.of(context).primaryColor.withOpacity(0.05)
          : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPrimary 
            ? Theme.of(context).primaryColor.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isPrimary 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 給与詳細
          Row(
            children: [
              Expanded(
                child: _buildAmountItem(
                  '総支給額',
                  '¥${numberFormat.format(grossAmount)}',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAmountItem(
                  '控除額',
                  '¥${numberFormat.format(deductions)}',
                  Colors.red,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 手取り額（大きく表示）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPrimary 
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '手取り額',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '¥${numberFormat.format(netAmount)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPrimary 
                      ? Theme.of(context).primaryColor
                      : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
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
}