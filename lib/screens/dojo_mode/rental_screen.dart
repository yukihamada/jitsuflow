import 'package:flutter/material.dart';
import '../../models/rental.dart';

class RentalScreen extends StatefulWidget {
  final int dojoId;
  
  const RentalScreen({
    super.key,
    required this.dojoId,
  });

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  List<Rental> _rentals = [];
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadRentals();
  }

  Future<void> _loadRentals() async {
    // TODO: Load from API
    // Dummy data for demo
    setState(() {
      _rentals = [
        Rental(
          id: 1,
          itemType: 'gi',
          itemName: '道着（白帯用）',
          size: 'A2',
          color: '白',
          condition: 'good',
          dojoId: widget.dojoId,
          totalQuantity: 5,
          availableQuantity: 3,
          rentalPrice: 1000,
          depositAmount: 5000,
          status: 'available',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Rental(
          id: 2,
          itemType: 'belt',
          itemName: '白帯',
          size: null,
          color: '白',
          condition: 'new',
          dojoId: widget.dojoId,
          totalQuantity: 10,
          availableQuantity: 8,
          rentalPrice: 300,
          depositAmount: 1500,
          status: 'available',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Rental(
          id: 3,
          itemType: 'protector',
          itemName: 'マウスピース',
          size: 'フリー',
          color: null,
          condition: 'new',
          dojoId: widget.dojoId,
          totalQuantity: 20,
          availableQuantity: 15,
          rentalPrice: 200,
          depositAmount: 1000,
          status: 'available',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredRentals = _selectedCategory == 'all' 
        ? _rentals
        : _rentals.where((rental) => rental.itemType == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('レンタル管理'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRentalDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'カテゴリ:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('all', 'すべて'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('gi', '道着'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('belt', '帯'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('protector', 'プロテクター'),
                        const SizedBox(width: 8),
                        _buildCategoryChip('other', 'その他'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Rental List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRentals,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredRentals.length,
                itemBuilder: (context, index) {
                  final rental = filteredRentals[index];
                  return _buildRentalCard(rental);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = value;
        });
      },
      selectedColor: Colors.blue.withOpacity(0.3),
    );
  }

  Widget _buildRentalCard(Rental rental) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getItemTypeColor(rental.itemType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getItemTypeIcon(rental.itemType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.itemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            rental.itemTypeDisplay,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (rental.size != null) ...[
                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                            Text(
                              'サイズ: ${rental.size}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                          if (rental.color != null) ...[
                            const Text(' • ', style: TextStyle(color: Colors.grey)),
                            Text(
                              rental.color!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: rental.isAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rental.statusDisplay,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    '在庫',
                    '${rental.availableQuantity}/${rental.totalQuantity}',
                    Icons.inventory,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'レンタル料',
                    rental.formattedPrice,
                    Icons.payment,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'デポジット',
                    '¥${rental.depositAmount}',
                    Icons.account_balance_wallet,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'コンディション',
                    rental.conditionDisplay,
                    Icons.star,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: rental.isAvailable ? () => _showRentDialog(rental) : null,
                    icon: const Icon(Icons.assignment),
                    label: const Text('レンタル'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditRentalDialog(rental),
                    icon: const Icon(Icons.edit),
                    label: const Text('編集'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
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

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getItemTypeColor(String itemType) {
    switch (itemType) {
      case 'gi':
        return Colors.green;
      case 'belt':
        return Colors.orange;
      case 'protector':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getItemTypeIcon(String itemType) {
    switch (itemType) {
      case 'gi':
        return Icons.sports_martial_arts;
      case 'belt':
        return Icons.fitness_center;
      case 'protector':
        return Icons.security;
      default:
        return Icons.inventory;
    }
  }

  void _showRentDialog(Rental rental) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${rental.itemName} レンタル'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('レンタル料: ${rental.formattedPrice}'),
            Text('デポジット: ¥${rental.depositAmount}'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '顧客名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: '返却予定日',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('レンタル手続きが完了しました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('レンタル開始'),
          ),
        ],
      ),
    );
  }

  void _showAddRentalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいレンタル商品追加'),
        content: const SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: '商品名',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'レンタル料（円）',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: '在庫数',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('商品が追加されました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _showEditRentalDialog(Rental rental) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${rental.itemName} 編集'),
        content: const SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: '商品名',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'レンタル料（円）',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: '在庫数',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('商品情報が更新されました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }
}