/**
 * ショップ画面
 * ユーザーが商品を閲覧・購入する画面
 */

import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import 'cart_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _apiService = ApiService();
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  String? _selectedCategory;
  final _searchController = TextEditingController();

  // カテゴリーリスト
  final List<Map<String, dynamic>> _categories = [
    {'value': null, 'label': '全て', 'icon': Icons.all_inclusive},
    {'value': 'training', 'label': 'パーソナル', 'icon': Icons.fitness_center},
    {'value': 'healing', 'label': 'ヒーリング', 'icon': Icons.spa},
    {'value': 'bjj_training', 'label': '柔術パーソナル', 'icon': Icons.sports_martial_arts},
    {'value': 'rental', 'label': 'レンタル', 'icon': Icons.shopping_basket},
    {'value': 'trial', 'label': '体験', 'icon': Icons.play_circle},
    {'value': 'gi', 'label': '道着', 'icon': Icons.checkroom},
    {'value': 'belt', 'label': '帯', 'icon': Icons.horizontal_rule},
    {'value': 'protector', 'label': '防具', 'icon': Icons.shield},
    {'value': 'apparel', 'label': 'アパレル', 'icon': Icons.shopping_bag},
    {'value': 'equipment', 'label': '器具', 'icon': Icons.fitness_center},
    {'value': 'other', 'label': 'その他', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCart();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _apiService.get(
        '/api/products${_selectedCategory != null ? '?category=$_selectedCategory' : ''}'
      );
      
      setState(() {
        _products = (response['products'] as List)
            .map((p) => Product.fromJson(p))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('商品の読み込みに失敗しました: $e')),
      );
    }
  }

  Future<void> _loadCart() async {
    try {
      final response = await _apiService.get('/api/cart');
      
      setState(() {
        _cartItems = (response['items'] as List).map((item) {
          final product = Product.fromJson(item['product']);
          return CartItem(
            product: product,
            quantity: item['quantity'],
          );
        }).toList();
      });
    } catch (e) {
      // カート読み込みエラーは無視（初回など）
    }
  }

  Future<void> _addToCart(Product product) async {
    try {
      await _apiService.post('/api/cart/add', {
        'product_id': product.id,
        'quantity': 1,
      });
      
      // カートを再読み込み
      await _loadCart();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name}をカートに追加しました'),
          action: SnackBarAction(
            label: 'カートを見る',
            onPressed: _navigateToCart,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('カートへの追加に失敗しました: $e')),
      );
    }
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(cartItems: _cartItems),
      ),
    ).then((_) => _loadCart()); // カート画面から戻ったら再読み込み
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = _cartItems.fold<int>(
      0, (sum, item) => sum + item.quantity
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ショップ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _navigateToCart,
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      cartItemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
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
                final isSelected = _selectedCategory == category['value'];
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            category['label'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category['value'] : null;
                      });
                      _loadProducts();
                    },
                    selectedColor: Theme.of(context).primaryColor,
                    checkmarkColor: Colors.white,
                  ),
                );
              },
            ),
          ),
          
          // 検索バー
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '商品を検索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                // TODO: 検索機能の実装
              },
            ),
          ),
          
          // 商品グリッド
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                ? const Center(
                    child: Text(
                      '商品が見つかりません',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return _buildProductCard(product);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isOutOfStock = product.stockQuantity == 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isOutOfStock ? null : () => _showProductDetail(product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品画像
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: product.imageUrl != null
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image, size: 60, color: Colors.grey[400]),
                          )
                        : Icon(Icons.image, size: 60, color: Colors.grey[400]),
                    ),
                    // 在庫状態バッジ
                    if (isOutOfStock)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '在庫切れ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (!isOutOfStock && product.stockQuantity < 5)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '残りわずか',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 商品情報
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.detailInfo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.detailInfo,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            product.formattedPrice,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isOutOfStock)
                          IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () => _addToCart(product),
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetail(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 画像
              Center(
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.image, size: 100, color: Colors.grey[400]),
                        ),
                      )
                    : Icon(Icons.image, size: 100, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 20),
              
              // 商品名
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // カテゴリーとサイズ/詳細情報
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(product.categoryLabel),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  if (product.trainer != null)
                    Chip(
                      label: Text('指導: ${product.trainer}'),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                    ),
                  if (product.sessions != null)
                    Chip(
                      label: Text('${product.sessions}回セッション'),
                      backgroundColor: Colors.green.withOpacity(0.1),
                    ),
                  if (product.duration != null)
                    Chip(
                      label: Text('${product.duration}分'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                    ),
                  if (product.validityDays != null)
                    Chip(
                      label: Text('有効期限${product.validityDays}日'),
                      backgroundColor: Colors.purple.withOpacity(0.1),
                    ),
                  if (product.customerType != null)
                    Chip(
                      label: Text(product.customerType == 'new' ? '新規限定' : '継続者向け'),
                      backgroundColor: product.customerType == 'new' 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.teal.withOpacity(0.1),
                    ),
                  if (product.size != null) ...[
                    Chip(
                      label: Text('サイズ: ${product.size}'),
                      backgroundColor: Colors.grey[200],
                    ),
                  ],
                  if (product.color != null) ...[
                    Chip(
                      label: Text(product.color!),
                      backgroundColor: Colors.grey[200],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              
              // 価格と在庫
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    '在庫: ${product.stockQuantity}個',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // 商品説明
              const Text(
                '商品説明',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 30),
              
              // カートに追加ボタン
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: product.stockQuantity > 0 
                    ? () {
                        _addToCart(product);
                        Navigator.pop(context);
                      }
                    : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text(
                    'カートに追加',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}