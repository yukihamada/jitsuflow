/**
 * 商品モデル
 * JitsuFlowの道着、帯、防具、アパレル等の商品情報
 */

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String category; // gi, belt, protector, apparel, equipment
  final String? imageUrl;
  final int stockQuantity;
  final bool isActive;
  final String? size;
  final String? color;
  final Map<String, dynamic>? attributes; // サイズ展開、カラー展開など
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    required this.stockQuantity,
    required this.isActive,
    this.size,
    this.color,
    this.attributes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? 'equipment',
      imageUrl: json['image_url'],
      stockQuantity: json['stock_quantity'] ?? 0,
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      size: json['size'],
      color: json['color'],
      attributes: json['attributes'] != null
          ? Map<String, dynamic>.from(json['attributes'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'stock_quantity': stockQuantity,
      'is_active': isActive,
      'size': size,
      'color': color,
      'attributes': attributes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // カテゴリー名を日本語で取得
  String get categoryLabel {
    switch (category) {
      case 'gi':
        return '道着';
      case 'belt':
        return '帯';
      case 'protector':
        return '防具';
      case 'apparel':
        return 'アパレル';
      case 'equipment':
        return '器具・用品';
      case 'training':
        return 'パーソナルトレーニング';
      case 'healing':
        return 'ヒーリング・カイロ';
      case 'bjj_training':
        return '柔術パーソナル';
      case 'rental':
        return 'レンタル';
      case 'trial':
        return '体験・トライアル';
      case 'other':
        return 'その他';
      default:
        return category;
    }
  }

  // 在庫状態を取得
  String get stockStatus {
    if (stockQuantity == 0) {
      return '在庫切れ';
    } else if (stockQuantity < 5) {
      return '残りわずか';
    } else {
      return '在庫あり';
    }
  }

  // 価格を通貨形式で取得
  String get formattedPrice {
    return '¥${price.toStringAsFixed(0)}';
  }

  // トレーナー名を取得（パーソナルトレーニング・ヒーリング用）
  String? get trainer {
    return attributes?['trainer'];
  }

  // セッション数を取得
  int? get sessions {
    return attributes?['sessions'];
  }

  // セッション時間を取得
  int? get duration {
    return attributes?['duration'];
  }

  // 有効期限（日数）を取得
  int? get validityDays {
    return attributes?['validity_days'];
  }

  // 顧客タイプを取得（新規/継続）
  String? get customerType {
    return attributes?['customer_type'];
  }

  // 商品タイプを取得
  String? get productType {
    return attributes?['type'];
  }

  // 商品の詳細情報を取得（トレーニングセッション用）
  String get detailInfo {
    if (isTrainingSession) {
      final parts = <String>[];
      if (trainer != null) parts.add('指導: $trainer');
      if (sessions != null && duration != null) {
        parts.add('$duration分 × ${sessions}回');
      } else if (duration != null) {
        parts.add('$duration分');
      }
      if (validityDays != null) parts.add('有効期限: ${validityDays}日');
      return parts.join(' / ');
    } else if (isRental) {
      return productType?.replaceAll('_', ' ') ?? 'レンタル商品';
    }
    return '';
  }

  // パーソナルトレーニング・ヒーリングセッションかどうか
  bool get isTrainingSession {
    return ['training', 'healing', 'bjj_training'].contains(category);
  }

  // レンタル商品かどうか
  bool get isRental {
    return category == 'rental';
  }

  // 体験・トライアル商品かどうか
  bool get isTrial {
    return category == 'trial';
  }

  // 無料商品かどうか
  bool get isFree {
    return price == 0;
  }
}

// カート内の商品
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  String get formattedTotalPrice => '¥${totalPrice.toStringAsFixed(0)}';
}

// 注文
class Order {
  final int id;
  final int userId;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String status; // pending, processing, shipped, delivered, cancelled
  final String? shippingAddress;
  final String? trackingNumber;
  final DateTime createdAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.shippingAddress,
    this.trackingNumber,
    required this.createdAt,
    this.shippedAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      items: (json['items'] as List?)
          ?.map((item) => OrderItem.fromJson(item))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      shippingAddress: json['shipping_address'],
      trackingNumber: json['tracking_number'],
      createdAt: DateTime.parse(json['created_at']),
      shippedAt: json['shipped_at'] != null
          ? DateTime.parse(json['shipped_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return '処理待ち';
      case 'processing':
        return '処理中';
      case 'shipped':
        return '発送済み';
      case 'delivered':
        return '配達完了';
      case 'cancelled':
        return 'キャンセル';
      default:
        return status;
    }
  }
}

// 注文アイテム
class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'] ?? '',
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      totalPrice: (json['total_price'] ?? 0).toDouble(),
    );
  }
}