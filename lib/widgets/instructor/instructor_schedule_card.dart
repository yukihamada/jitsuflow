/**
 * インストラクタースケジュールカード
 * 今後のクラススケジュールを表示
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InstructorScheduleCard extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingClasses;

  const InstructorScheduleCard({
    super.key,
    required this.upcomingClasses,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '今後のクラス',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (upcomingClasses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '今後のクラスはありません',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...upcomingClasses.map((classData) => _buildClassItem(context, classData)),
        ],
      ),
    );
  }

  Widget _buildClassItem(BuildContext context, Map<String, dynamic> classData) {
    final date = DateTime.parse(classData['date']);
    final dateFormat = DateFormat('MM/dd (E)', 'ja_JP');
    final currentBookings = classData['current_bookings'] as int;
    final maxCapacity = classData['max_capacity'] as int;
    final utilizationRate = (currentBookings / maxCapacity * 100).round();
    
    // 予約率に応じて色を決定
    Color utilizationColor;
    if (utilizationRate >= 90) {
      utilizationColor = Colors.red;
    } else if (utilizationRate >= 70) {
      utilizationColor = Colors.orange;
    } else if (utilizationRate >= 50) {
      utilizationColor = Colors.blue;
    } else {
      utilizationColor = Colors.grey;
    }

    return InkWell(
      onTap: () {
        // TODO: クラス詳細画面へ遷移
        _showClassDetail(context, classData);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // 日付・時間
            Container(
              width: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormat.format(date),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    classData['time'],
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // クラス情報
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classData['class_type'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    classData['dojo'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            // 予約状況
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: utilizationColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: utilizationColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$currentBookings/$maxCapacity人',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: utilizationColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$utilizationRate%',
                  style: TextStyle(
                    fontSize: 10,
                    color: utilizationColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showClassDetail(BuildContext context, Map<String, dynamic> classData) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'クラス詳細',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('クラス', classData['class_type']),
            _buildDetailRow('日時', '${classData['date']} ${classData['time']}'),
            _buildDetailRow('道場', classData['dojo']),
            _buildDetailRow('予約数', '${classData['current_bookings']}/${classData['max_capacity']}人'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: 出席確認画面へ遷移
                    },
                    icon: const Icon(Icons.how_to_reg),
                    label: const Text('出席確認'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: クラス報告画面へ遷移
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text('クラス報告'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}