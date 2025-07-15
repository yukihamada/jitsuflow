/**
 * インストラクター評価カード
 * 最近の生徒評価を表示
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InstructorRatingCard extends StatelessWidget {
  final List<Map<String, dynamic>> recentRatings;

  const InstructorRatingCard({
    super.key,
    required this.recentRatings,
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
                  Icons.star,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '最近の評価',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (recentRatings.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '評価はまだありません',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentRatings.map((rating) => _buildRatingItem(context, rating)),
        ],
      ),
    );
  }

  Widget _buildRatingItem(BuildContext context, Map<String, dynamic> rating) {
    final date = DateTime.parse(rating['date']);
    final dateFormat = DateFormat('MM/dd', 'ja_JP');
    final overallRating = rating['overall_rating'] as int;
    
    return InkWell(
      onTap: () {
        _showRatingDetail(context, rating);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 評価星
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRatingColor(overallRating).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRatingColor(overallRating).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: _getRatingColor(overallRating),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$overallRating',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(overallRating),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 評価内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rating['student_name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        dateFormat.format(date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rating['class_type'],
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (rating['feedback'] != null && rating['feedback'].isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      rating['feedback'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
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

  Color _getRatingColor(int rating) {
    if (rating >= 5) return Colors.green;
    if (rating >= 4) return Colors.blue;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }

  void _showRatingDetail(BuildContext context, Map<String, dynamic> rating) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '評価詳細',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // 基本情報
            _buildDetailRow('生徒名', rating['student_name']),
            _buildDetailRow('クラス', rating['class_type']),
            _buildDetailRow('日付', rating['date']),
            
            const SizedBox(height: 16),
            
            // 総合評価
            Row(
              children: [
                const Text(
                  '総合評価:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                ...List.generate(5, (index) => Icon(
                  Icons.star,
                  size: 20,
                  color: index < rating['overall_rating'] 
                    ? Colors.amber 
                    : Colors.grey[300],
                )),
                const SizedBox(width: 8),
                Text(
                  '${rating['overall_rating']}/5',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            
            // フィードバック
            if (rating['feedback'] != null && rating['feedback'].isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'フィードバック:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  rating['feedback'],
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: 生徒への返信機能
                    },
                    icon: const Icon(Icons.reply),
                    label: const Text('返信'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: 全評価一覧画面へ遷移
                    },
                    icon: const Icon(Icons.list),
                    label: const Text('全評価'),
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