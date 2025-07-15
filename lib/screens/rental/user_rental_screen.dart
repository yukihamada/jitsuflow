/**
 * ユーザー向けレンタル画面
 * 道着や防具のレンタル申請
 */

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class UserRentalScreen extends StatefulWidget {
  const UserRentalScreen({super.key});

  @override
  State<UserRentalScreen> createState() => _UserRentalScreenState();
}

class _UserRentalScreenState extends State<UserRentalScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _rentalItems = [];
  List<Map<String, dynamic>> _myRentals = [];
  bool _isLoading = true;
  String? _selectedCategory;
  final _dateFormat = DateFormat('yyyy年MM月dd日');

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': '全て'},
    {'value': 'gi', 'label': '道着'},
    {'value': 'belt', 'label': '帯'},
    {'value': 'protector', 'label': '防具'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      // レンタル可能アイテム取得
      final itemsResponse = await _apiService.get('/api/rentals/available');
      
      // 自分のレンタル履歴取得
      final userId = await _apiService.getCurrentUserId();
      final rentalsResponse = await _apiService.get('/api/rentals/user/$userId');
      
      setState(() {
        _rentalItems = List<Map<String, dynamic>>.from(itemsResponse['items'] ?? []);
        _myRentals = List<Map<String, dynamic>>.from(rentalsResponse['rentals'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('データの読み込みに失敗しました: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedCategory == null || _selectedCategory == 'all') {
      return _rentalItems;
    }
    return _rentalItems.where((item) => item['category'] == _selectedCategory).toList();
  }

  Future<void> _requestRental(Map<String, dynamic> item) async {
    final startDate = DateTime.now();
    final endDate = startDate.add(const Duration(days: 7)); // デフォルト1週間
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('レンタル申請'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item['name']}をレンタルしますか？'),
            const SizedBox(height: 16),
            Text('レンタル期間: ${_dateFormat.format(startDate)} 〜 ${_dateFormat.format(endDate)}'),
            Text('デポジット: ¥${item['deposit_amount']}'),
            Text('レンタル料: ¥${item['daily_rate']} / 日'),
            const SizedBox(height: 8),
            Text(
              '合計: ¥${(item['deposit_amount'] + item['daily_rate'] * 7).toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processRental(item, startDate, endDate);
            },
            child: const Text('申請する'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRental(Map<String, dynamic> item, DateTime startDate, DateTime endDate) async {
    try {
      final userId = await _apiService.getCurrentUserId();
      
      await _apiService.post('/api/rentals/request', {
        'user_id': userId,
        'rental_item_id': item['id'],
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('レンタル申請を送信しました')),
      );
      
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('申請に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('レンタル'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'レンタル可能アイテム'),
              Tab(text: 'レンタル履歴'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // レンタル可能アイテムタブ
            _buildAvailableItemsTab(),
            // レンタル履歴タブ
            _buildRentalHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableItemsTab() {
    return Column(
      children: [
        // カテゴリーフィルター
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['value'] ||
                  (category['value'] == 'all' && _selectedCategory == null);
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(category['label']!),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected && category['value'] != 'all' 
                        ? category['value'] 
                        : null;
                    });
                  },
                  selectedColor: Theme.of(context).primaryColor,
                  checkmarkColor: Colors.white,
                ),
              );
            },
          ),
        ),
        
        // アイテムリスト
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredItems.isEmpty
              ? const Center(
                  child: Text(
                    'レンタル可能なアイテムがありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    return _buildRentalItemCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRentalItemCard(Map<String, dynamic> item) {
    final isAvailable = item['is_available'] == 1 || item['is_available'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getCategoryColor(item['category']),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(item['category']),
            color: Colors.white,
            size: 30,
          ),
        ),
        title: Text(
          item['name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('サイズ: ${item['size'] ?? 'フリー'} • ${item['condition'] ?? '良好'}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'デポジット: ¥${item['deposit_amount']}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
                Text(
                  '¥${item['daily_rate']}/日',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isAvailable
          ? ElevatedButton(
              onPressed: () => _requestRental(item),
              child: const Text('レンタル'),
            )
          : const Chip(
              label: Text('貸出中'),
              backgroundColor: Colors.grey,
            ),
      ),
    );
  }

  Widget _buildRentalHistoryTab() {
    final activeRentals = _myRentals.where((r) => r['status'] == 'active').toList();
    final pastRentals = _myRentals.where((r) => r['status'] != 'active').toList();
    
    return _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _myRentals.isEmpty
        ? const Center(
            child: Text(
              'レンタル履歴がありません',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (activeRentals.isNotEmpty) ...[
                  const Text(
                    '現在レンタル中',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...activeRentals.map((rental) => _buildRentalHistoryCard(rental, isActive: true)),
                  const SizedBox(height: 24),
                ],
                
                if (pastRentals.isNotEmpty) ...[
                  const Text(
                    '過去のレンタル',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...pastRentals.map((rental) => _buildRentalHistoryCard(rental, isActive: false)),
                ],
              ],
            ),
          );
  }

  Widget _buildRentalHistoryCard(Map<String, dynamic> rental, {required bool isActive}) {
    final startDate = DateTime.parse(rental['start_date']);
    final endDate = DateTime.parse(rental['end_date']);
    final totalDays = endDate.difference(startDate).inDays;
    final totalCost = (rental['deposit_amount'] ?? 0) + ((rental['daily_rate'] ?? 0) * totalDays);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isActive ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rental['item_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(_getStatusLabel(rental['status'])),
                  backgroundColor: _getStatusColor(rental['status']),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('期間: ${_dateFormat.format(startDate)} 〜 ${_dateFormat.format(endDate)}'),
            Text('合計金額: ¥${totalCost.toStringAsFixed(0)}'),
            
            if (isActive) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _showReturnDialog(rental),
                    child: const Text('返却手続き'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReturnDialog(Map<String, dynamic> rental) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('返却手続き'),
        content: Text('${rental['item_name']}を返却しますか？\n返却後、スタッフが確認してデポジットを返金します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _apiService.post('/api/rentals/${rental['id']}/return', {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('返却手続きを開始しました')),
                );
                await _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('返却手続きに失敗しました: $e')),
                );
              }
            },
            child: const Text('返却する'),
          ),
        ],
      ),
    );
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
}