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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS - 物販・支払い'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_cart.length}'),
                child: const Icon(Icons.shopping_cart),
              ),
              onPressed: _showCartDialog,
            ),
        ],
      ),
      body: BlocBuilder<DojoModeBloc, DojoModeState>(
        builder: (context, state) {
          if (state is DojoModeLoaded) {
            return Row(
              children: [
                // Product Grid
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '商品一覧',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: state.products.length,
                            itemBuilder: (context, index) {
                              final product = state.products[index];
                              return _buildProductCard(product);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Cart & Checkout
                Container(
                  width: 350,
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      // Cart Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_cart,
                              color: Colors.white,
                            ),
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
                              '${_cart.length}点',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Cart Items
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cart.length,
                          itemBuilder: (context, index) {
                            final item = _cart[index];
                            return _buildCartItem(item, index);
                          },
                        ),
                      ),
                      
                      // Customer Selection
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '顧客選択',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int?>(
                              value: _selectedCustomerId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: '顧客を選択 (任意)',
                              ),
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('非会員'),
                                ),
                                // TODO: Load actual members
                                const DropdownMenuItem<int>(
                                  value: 1,
                                  child: Text('デモユーザー'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCustomerId = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Payment Method
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '支払い方法',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('現金'),
                                    value: 'cash',
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPaymentMethod = value!;
                                      });
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('カード'),
                                    value: 'credit_card',
                                    groupValue: _selectedPaymentMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPaymentMethod = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Total & Checkout
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Colors.grey),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '小計:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '¥${_calculateSubtotal()}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '消費税:',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '¥${_calculateTax()}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '合計:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '¥${_calculateTotal()}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _cart.isEmpty ? null : _processPayment,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: state.isProcessingPayment
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text(
                                        '支払い処理',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _addToCart(product),
        borderRadius: BorderRadius.circular(12),
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
                child: const Icon(
                  Icons.shopping_bag,
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
                '¥${product['selling_price'] ?? 0}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '在庫: ${product['current_stock'] ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item, int index) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '¥${item['price']} x ${item['quantity']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _updateQuantity(index, -1),
                  iconSize: 20,
                ),
                Text('${item['quantity']}'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _updateQuantity(index, 1),
                  iconSize: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFromCart(index),
                  iconSize: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) {
    final existingIndex = _cart.indexWhere((item) => item['id'] == product['id']);
    
    if (existingIndex >= 0) {
      setState(() {
        _cart[existingIndex]['quantity']++;
      });
    } else {
      setState(() {
        _cart.add({
          'id': product['id'],
          'name': product['name'],
          'price': product['selling_price'],
          'quantity': 1,
        });
      });
    }
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

  int _calculateSubtotal() {
    return _cart.fold(0, (sum, item) => sum + (item['price'] * item['quantity']) as int);
  }

  int _calculateTax() {
    return (_calculateSubtotal() * 0.1).round();
  }

  int _calculateTotal() {
    return _calculateSubtotal() + _calculateTax();
  }

  void _processPayment() {
    if (_cart.isEmpty) return;
    
    context.read<DojoModeBloc>().add(ProcessPayment(
      dojoId: widget.dojoId,
      items: _cart,
      paymentMethod: _selectedPaymentMethod,
      customerId: _selectedCustomerId,
    ));
    
    // Clear cart on successful payment
    setState(() {
      _cart.clear();
      _selectedCustomerId = null;
      _selectedPaymentMethod = 'cash';
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('支払い処理が完了しました'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カート内容'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: _cart.length,
            itemBuilder: (context, index) {
              final item = _cart[index];
              return ListTile(
                title: Text(item['name']),
                subtitle: Text('¥${item['price']} x ${item['quantity']}'),
                trailing: Text('¥${item['price'] * item['quantity']}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}