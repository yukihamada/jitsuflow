class Payment {
  final int id;
  final String paymentType; // instructor_payment, dojo_fee, rental_fee, purchase
  final int amount;
  final int taxAmount;
  final int totalAmount;
  final int? instructorId;
  final int? dojoId;
  final int? userId;
  final String status; // pending, completed, cancelled, refunded
  final String? paymentMethod;
  final String? stripePaymentId;
  final DateTime paymentDate;
  final DateTime? dueDate;
  final DateTime? paidAt;
  final String? description;
  final String? receiptUrl;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.paymentType,
    required this.amount,
    required this.taxAmount,
    required this.totalAmount,
    this.instructorId,
    this.dojoId,
    this.userId,
    required this.status,
    this.paymentMethod,
    this.stripePaymentId,
    required this.paymentDate,
    this.dueDate,
    this.paidAt,
    this.description,
    this.receiptUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      paymentType: json['payment_type'],
      amount: json['amount'],
      taxAmount: json['tax_amount'],
      totalAmount: json['total_amount'],
      instructorId: json['instructor_id'],
      dojoId: json['dojo_id'],
      userId: json['user_id'],
      status: json['status'],
      paymentMethod: json['payment_method'],
      stripePaymentId: json['stripe_payment_id'],
      paymentDate: DateTime.parse(json['payment_date']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      description: json['description'],
      receiptUrl: json['receipt_url'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_type': paymentType,
      'amount': amount,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'instructor_id': instructorId,
      'dojo_id': dojoId,
      'user_id': userId,
      'status': status,
      'payment_method': paymentMethod,
      'stripe_payment_id': stripePaymentId,
      'payment_date': paymentDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'description': description,
      'receipt_url': receiptUrl,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get paymentTypeDisplay {
    switch (paymentType) {
      case 'instructor_payment':
        return 'インストラクター報酬';
      case 'dojo_fee':
        return '道場使用料';
      case 'rental_fee':
        return 'レンタル料';
      case 'purchase':
        return '商品購入';
      default:
        return paymentType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return '処理中';
      case 'completed':
        return '完了';
      case 'cancelled':
        return 'キャンセル';
      case 'refunded':
        return '返金済み';
      default:
        return status;
    }
  }

  String get formattedAmount {
    return '¥${totalAmount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}