class Rental {
  final int id;
  final String itemType; // gi, belt, protector, other
  final String itemName;
  final String? size;
  final String? color;
  final String condition; // new, good, fair, poor
  final int dojoId;
  final int totalQuantity;
  final int availableQuantity;
  final int rentalPrice;
  final int depositAmount;
  final String status; // available, maintenance, retired
  final String? barcode;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Rental({
    required this.id,
    required this.itemType,
    required this.itemName,
    this.size,
    this.color,
    required this.condition,
    required this.dojoId,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.rentalPrice,
    required this.depositAmount,
    required this.status,
    this.barcode,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'],
      itemType: json['item_type'],
      itemName: json['item_name'],
      size: json['size'],
      color: json['color'],
      condition: json['condition'],
      dojoId: json['dojo_id'],
      totalQuantity: json['total_quantity'],
      availableQuantity: json['available_quantity'],
      rentalPrice: json['rental_price'],
      depositAmount: json['deposit_amount'],
      status: json['status'],
      barcode: json['barcode'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_type': itemType,
      'item_name': itemName,
      'size': size,
      'color': color,
      'condition': condition,
      'dojo_id': dojoId,
      'total_quantity': totalQuantity,
      'available_quantity': availableQuantity,
      'rental_price': rentalPrice,
      'deposit_amount': depositAmount,
      'status': status,
      'barcode': barcode,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get itemTypeDisplay {
    switch (itemType) {
      case 'gi':
        return '道着';
      case 'belt':
        return '帯';
      case 'protector':
        return 'プロテクター';
      case 'other':
        return 'その他';
      default:
        return itemType;
    }
  }

  String get conditionDisplay {
    switch (condition) {
      case 'new':
        return '新品';
      case 'good':
        return '良好';
      case 'fair':
        return '普通';
      case 'poor':
        return '要交換';
      default:
        return condition;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'available':
        return '利用可能';
      case 'maintenance':
        return 'メンテナンス中';
      case 'retired':
        return '廃棄済み';
      default:
        return status;
    }
  }

  bool get isAvailable {
    return status == 'available' && availableQuantity > 0;
  }

  String get formattedPrice {
    return '¥${rentalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}