class InstructorAssignment {
  final int id;
  final int instructorId;
  final int dojoId;
  final String dojoName;
  final int usageFee;
  final double revenueSharePercentage;
  final int? hourlyRate;
  final String paymentType; // revenue_share, hourly, fixed
  final int? fixedMonthlyFee;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  InstructorAssignment({
    required this.id,
    required this.instructorId,
    required this.dojoId,
    required this.dojoName,
    required this.usageFee,
    required this.revenueSharePercentage,
    this.hourlyRate,
    required this.paymentType,
    this.fixedMonthlyFee,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InstructorAssignment.fromJson(Map<String, dynamic> json) {
    return InstructorAssignment(
      id: json['id'],
      instructorId: json['instructor_id'],
      dojoId: json['dojo_id'],
      dojoName: json['dojo_name'] ?? '',
      usageFee: json['usage_fee'],
      revenueSharePercentage: json['revenue_share_percentage'].toDouble(),
      hourlyRate: json['hourly_rate'],
      paymentType: json['payment_type'],
      fixedMonthlyFee: json['fixed_monthly_fee'],
      status: json['status'],
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instructor_id': instructorId,
      'dojo_id': dojoId,
      'dojo_name': dojoName,
      'usage_fee': usageFee,
      'revenue_share_percentage': revenueSharePercentage,
      'hourly_rate': hourlyRate,
      'payment_type': paymentType,
      'fixed_monthly_fee': fixedMonthlyFee,
      'status': status,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get paymentTypeDisplay {
    switch (paymentType) {
      case 'revenue_share':
        return '歩合制 (${revenueSharePercentage.toStringAsFixed(0)}%)';
      case 'hourly':
        return '時給制 (¥${hourlyRate ?? 0}/時間)';
      case 'fixed':
        return '固定給 (¥${fixedMonthlyFee ?? 0}/月)';
      default:
        return paymentType;
    }
  }

  String get statusDisplay {
    switch (status) {
      case 'active':
        return '契約中';
      case 'inactive':
        return '非アクティブ';
      case 'pending':
        return '承認待ち';
      default:
        return status;
    }
  }
}