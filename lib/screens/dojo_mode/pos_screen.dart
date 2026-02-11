import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dojo_mode/dojo_mode_bloc.dart';
import '../../blocs/dojo_mode/dojo_mode_event.dart';
import '../../blocs/dojo_mode/dojo_mode_state.dart';

class POSScreen extends StatefulWidget {
  final int dojoId;

  const POSScreen({
    super.key,
    required this.dojoId,
  });

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final List<Map<String, dynamic>> _cart = [];
  int? _selectedCustomerId;
  String _selectedPaymentMethod = 'cash';
  bool _isMemberDiscount = false;
  String _selectedCategory = 'all';

  static const Color _primaryGreen = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS - 物販・支払い'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_totalItemCount()}'),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: _showCartDialog,
            ),
        ],
      ),
      body: BlocConsumer<DojoModeBloc, DojoModeState>(
        listener: (context, state) {
          if (state is DojoModeLoaded) {
            // Payment succeeded
            if (state.lastPaymentResult != null && !state.isProcessingPayment) {
              _showReceiptDialog(context, state.lastPaymentResult!);
              setState(() {
                _cart.clear();
                _selectedCustomerId = null;
                _selectedPaymentMethod = 'cash';
                _isMemberDiscount = false;
              });
            }
            // Payment error
            if (state.lastPaymentError != null && !state.isProcessingPayment) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('エラー: ${state.lastPaymentError}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is DojoModeLoaded) {
            return _buildBody(state);
          }

          if (state is DojoModeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('エラー: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DojoModeBloc>().add(LoadDojoModeData(widget.dojoId));
                    },
                    child: const Text('再試行'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildBody(DojoModeLoaded state) {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildProductSection(state),
          ),
          SizedBox(
            width: 370,
            child: _buildCartSection(state),
          ),
        ],
      );
    }

    // Narrow layout: products with a bottom sheet cart
    return Stack(
      children: [
        _buildProductSection(state),
        if (_cart.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildCompactCartBar(state),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Product Section
  // ---------------------------------------------------------------------------

  Widget _buildProductSection(DojoModeLoaded state) {
    final products = state.products;
    final categories = _extractCategories(products);
    final filteredProducts = _selectedCategory == 'all'
        ? products
        : products.where((p) => p['category'] == _selectedCategory).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '商品一覧',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Category filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip('all', 'すべて'),
                ...categories.map((cat) => _buildCategoryChip(cat, _categoryLabel(cat))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(
                    child: Text(
                      '商品がありません',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: _primaryGreen,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) {
          setState(() {
            _selectedCategory = value;
          });
        },
      ),
    );
  }

  List<String> _extractCategories(List<Map<String, dynamic>> products) {
    final cats = <String>{};
    for (final p in products) {
      final cat = p['category'] as String?;
      if (cat != null && cat.isNotEmpty) cats.add(cat);
    }
    return cats.toList()..sort();
  }

  String _categoryLabel(String category) {
    switch (category) {
      case 'supplement':
        return 'サプリメント';
      case 'gi':
        return '道着';
      case 'belt':
        return '帯';
      case 'apparel':
        return 'アパレル';
      case 'equipment':
        return '器具';
      case 'protector':
        return '防具';
      default:
        return category;
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stock = product['current_stock'] as int? ?? 0;
    final isOutOfStock = stock <= 0;
    final price = product['selling_price'] as int? ?? 0;
    final memberPrice = product['member_price'] as int?;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isOutOfStock ? null : () => _addToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isOutOfStock ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Placeholder
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isOutOfStock
                      ? const Center(
                          child: Text(
                            '売切',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        )
                      : Icon(
                          _categoryIcon(product['category'] as String? ?? ''),
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  product['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '¥${_formatNumber(price)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                  ),
                ),
                if (memberPrice != null && memberPrice < price)
                  Text(
                    '会員 ¥${_formatNumber(memberPrice)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '在庫: $stock',
                  style: TextStyle(
                    fontSize: 12,
                    color: stock <= 3 ? Colors.red : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'supplement':
        return Icons.fitness_center;
      case 'gi':
        return Icons.checkroom;
      case 'belt':
        return Icons.horizontal_rule;
      case 'apparel':
        return Icons.dry_cleaning;
      case 'equipment':
        return Icons.sports_martial_arts;
      case 'protector':
        return Icons.shield;
      default:
        return Icons.shopping_bag;
    }
  }

  // ---------------------------------------------------------------------------
  // Cart Section (wide layout)
  // ---------------------------------------------------------------------------

  Widget _buildCartSection(DojoModeLoaded state) {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          // Cart Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: _primaryGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'カート',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_totalItemCount()}点',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),

          // Cart Items
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('カートは空です', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return _buildCartItem(item, index);
                    },
                  ),
          ),

          // Member Discount Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              title: const Text(
                '会員割引 (10%OFF)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: _isMemberDiscount
                  ? Text(
                      '-¥${_formatNumber(_calculateMemberDiscount())}',
                      style: TextStyle(color: Colors.orange[800], fontSize: 13),
                    )
                  : null,
              value: _isMemberDiscount,
              activeColor: _primaryGreen,
              dense: true,
              onChanged: (value) {
                setState(() {
                  _isMemberDiscount = value;
                });
              },
            ),
          ),

          // Customer Selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonFormField<int?>(
              value: _selectedCustomerId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '顧客選択',
                hintText: '顧客を選択 (任意)',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: const [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text('非会員'),
                ),
                DropdownMenuItem<int>(
                  value: 1,
                  child: Text('デモユーザー'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCustomerId = value;
                  if (value != null) {
                    _isMemberDiscount = true;
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 8),

          // Payment Method
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '支払い方法',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodButton(
                        'cash',
                        '現金',
                        Icons.payments,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPaymentMethodButton(
                        'credit_card',
                        'カード',
                        Icons.credit_card,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Total & Checkout
          _buildCheckoutSection(state),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : _primaryGreen,
        backgroundColor: isSelected ? _primaryGreen : Colors.transparent,
        side: BorderSide(color: _primaryGreen, width: isSelected ? 2 : 1),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }

  Widget _buildCheckoutSection(DojoModeLoaded state) {
    final subtotal = _calculateSubtotal();
    final discount = _isMemberDiscount ? _calculateMemberDiscount() : 0;
    final afterDiscount = subtotal - discount;
    final tax = (afterDiscount * 0.1).round();
    final total = afterDiscount + tax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('小計', subtotal),
          if (_isMemberDiscount) ...[
            const SizedBox(height: 4),
            _buildSummaryRow('会員割引 (10%)', -discount, color: Colors.orange[800]),
          ],
          const SizedBox(height: 4),
          _buildSummaryRow('消費税 (10%)', tax),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '合計',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '¥${_formatNumber(total)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _cart.isEmpty || state.isProcessingPayment
                  ? null
                  : _processPayment,
              icon: state.isProcessingPayment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.point_of_sale),
              label: Text(
                state.isProcessingPayment ? '処理中...' : '支払い処理 (¥${_formatNumber(total)})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, {Color? color}) {
    final prefix = amount < 0 ? '-' : '';
    final absAmount = amount.abs();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: color)),
        Text(
          '$prefix¥${_formatNumber(absAmount)}',
          style: TextStyle(fontSize: 14, color: color),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Compact Cart Bar (narrow layout)
  // ---------------------------------------------------------------------------

  Widget _buildCompactCartBar(DojoModeLoaded state) {
    final total = _calculateTotal();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_totalItemCount()}点  ¥${_formatNumber(total)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryGreen,
                    ),
                  ),
                  Text(
                    '(税込)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _showCartDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
              ),
              child: const Text('カート'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.isProcessingPayment ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: state.isProcessingPayment
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('支払い'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cart Item Widget
  // ---------------------------------------------------------------------------

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    final price = item['price'] as int;
    final qty = item['quantity'] as int;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '¥${_formatNumber(price)} x $qty = ¥${_formatNumber(price * qty)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () => _updateQuantity(index, -1),
                  iconSize: 22,
                  color: _primaryGreen,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Text(
                  '$qty',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _updateQuantity(index, 1),
                  iconSize: 22,
                  color: _primaryGreen,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeFromCart(index),
                  iconSize: 22,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cart Logic
  // ---------------------------------------------------------------------------

  void _addToCart(Map<String, dynamic> product) {
    final productId = product['id'];
    final existingIndex = _cart.indexWhere((item) => item['id'] == productId);

    if (existingIndex >= 0) {
      setState(() {
        _cart[existingIndex]['quantity']++;
      });
    } else {
      setState(() {
        _cart.add({
          'id': productId,
          'name': product['name'],
          'price': product['selling_price'] ?? 0,
          'member_price': product['member_price'],
          'quantity': 1,
        });
      });
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} をカートに追加しました'),
        duration: const Duration(seconds: 1),
        backgroundColor: _primaryGreen,
      ),
    );
  }

  void _updateQuantity(int index, int change) {
    setState(() {
      _cart[index]['quantity'] += change;
      if (_cart[index]['quantity'] <= 0) {
        _cart.removeAt(index);
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _cart.removeAt(index);
    });
  }

  int _totalItemCount() {
    return _cart.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  int _calculateSubtotal() {
    return _cart.fold(0, (sum, item) {
      final price = item['price'] as int;
      final qty = item['quantity'] as int;
      return sum + price * qty;
    });
  }

  int _calculateMemberDiscount() {
    // 10% member discount on subtotal
    return (_calculateSubtotal() * 0.1).round();
  }

  int _calculateTax() {
    final subtotal = _calculateSubtotal();
    final discount = _isMemberDiscount ? _calculateMemberDiscount() : 0;
    return ((subtotal - discount) * 0.1).round();
  }

  int _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final discount = _isMemberDiscount ? _calculateMemberDiscount() : 0;
    final afterDiscount = subtotal - discount;
    final tax = (afterDiscount * 0.1).round();
    return afterDiscount + tax;
  }

  // ---------------------------------------------------------------------------
  // Payment Processing
  // ---------------------------------------------------------------------------

  void _processPayment() {
    if (_cart.isEmpty) return;

    // Build items with final prices for the API
    final items = _cart.map((item) {
      return {
        'id': item['id'],
        'name': item['name'],
        'price': item['price'] as int,
        'quantity': item['quantity'] as int,
        'subtotal': (item['price'] as int) * (item['quantity'] as int),
      };
    }).toList();

    final total = _calculateTotal();
    final discount = _isMemberDiscount ? _calculateMemberDiscount() : 0;
    final tax = _calculateTax();

    // Confirm payment
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('支払い確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${item['name']} x${item['quantity']}  ¥${_formatNumber(item['subtotal'] as int)}'),
            )),
            const Divider(),
            Text('小計: ¥${_formatNumber(_calculateSubtotal())}'),
            if (_isMemberDiscount)
              Text('会員割引: -¥${_formatNumber(discount)}',
                  style: TextStyle(color: Colors.orange[800])),
            Text('消費税: ¥${_formatNumber(tax)}'),
            const SizedBox(height: 8),
            Text(
              '合計: ¥${_formatNumber(total)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '支払い方法: ${_selectedPaymentMethod == 'cash' ? '現金' : 'カード'}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _executePayment(items);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _executePayment(List<Map<String, dynamic>> items) {
    context.read<DojoModeBloc>().add(ProcessPayment(
      dojoId: widget.dojoId,
      items: items,
      paymentMethod: _selectedPaymentMethod,
      customerId: _selectedCustomerId,
    ));
  }

  // ---------------------------------------------------------------------------
  // Receipt Dialog
  // ---------------------------------------------------------------------------

  void _showReceiptDialog(BuildContext context, Map<String, dynamic> result) {
    final transactionId = result['transaction_id'] ?? '-';
    final totalAmount = result['total_amount'] as int? ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: _primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('支払い完了'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'お支払いが完了しました。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildReceiptRow('取引番号', '#$transactionId'),
            _buildReceiptRow('合計金額', '¥${_formatNumber(totalAmount)}'),
            _buildReceiptRow(
              '支払い方法',
              _selectedPaymentMethod == 'cash' ? '現金' : 'カード',
            ),
            _buildReceiptRow(
              '日時',
              _formatDateTime(DateTime.now()),
            ),
            if (_isMemberDiscount)
              _buildReceiptRow('会員割引', '適用済'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Cart Dialog (for narrow/mobile layout)
  // ---------------------------------------------------------------------------

  void _showCartDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final total = _calculateTotal();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Text(
                        'カート内容',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return ListTile(
                              title: Text(item['name'] as String),
                              subtitle: Text('¥${_formatNumber(item['price'] as int)} x ${item['quantity']}'),
                              trailing: Text(
                                '¥${_formatNumber((item['price'] as int) * (item['quantity'] as int))}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '合計（税込）',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '¥${_formatNumber(total)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('閉じる'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
