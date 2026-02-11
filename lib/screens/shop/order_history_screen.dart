/**
 * 注文履歴画面
 * ユーザーの過去の注文一覧を表示する画面
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  final _dateFormat = DateFormat('yyyy年MM月dd日');
  final Set<int> _expandedOrders = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() => _isLoading = true);
      final orders = await ApiService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('注文履歴の読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.sync;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('注文履歴'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '注文履歴がありません',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ショップで商品を購入してみましょう',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isExpanded = _expandedOrders.contains(order.id);
    final statusColor = _getStatusColor(order.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedOrders.remove(order.id);
            } else {
              _expandedOrders.add(order.id);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '注文 #${order.id}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order.status),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          order.statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date and total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '注文日: ${_dateFormat.format(order.createdAt)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '合計: ¥${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),

              // Items summary (collapsed)
              if (!isExpanded) ...[
                const SizedBox(height: 8),
                Text(
                  '${order.items.length}点の商品',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.expand_more,
                    color: Colors.grey[400],
                  ),
                ),
              ],

              // Expanded detail
              if (isExpanded) ...[
                const Divider(height: 24),

                // Order items
                const Text(
                  '注文内容',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            '${item.quantity}点',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '¥${item.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),

                const Divider(height: 16),

                // Price breakdown
                _buildPriceRow('小計', '¥${order.subtotal.toStringAsFixed(0)}'),
                _buildPriceRow('消費税', '¥${order.tax.toStringAsFixed(0)}'),
                _buildPriceRow(
                  '合計',
                  '¥${order.total.toStringAsFixed(0)}',
                  isBold: true,
                ),

                // Shipping info
                if (order.shippingAddress != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.shippingAddress!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Tracking number
                if (order.trackingNumber != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_shipping, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '追跡番号: ${order.trackingNumber}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],

                // Shipped/Delivered dates
                if (order.shippedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '発送日: ${_dateFormat.format(order.shippedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
                if (order.deliveredAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '配達日: ${_dateFormat.format(order.deliveredAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],

                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    Icons.expand_less,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? null : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFF1B5E20) : null,
            ),
          ),
        ],
      ),
    );
  }
}
