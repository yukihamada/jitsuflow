class RevenueSummary {
  final int dojoId;
  final String dojoName;
  final DateTime period;
  final int membershipRevenue;
  final int productRevenue;
  final int rentalRevenue;
  final int totalRevenue;
  final int instructorCosts;
  final int grossProfit;

  RevenueSummary({
    required this.dojoId,
    required this.dojoName,
    required this.period,
    required this.membershipRevenue,
    required this.productRevenue,
    required this.rentalRevenue,
    required this.totalRevenue,
    required this.instructorCosts,
    required this.grossProfit,
  });

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      dojoId: json['dojo_id'],
      dojoName: json['dojo_name'],
      period: DateTime.parse(json['period']),
      membershipRevenue: json['membership_revenue'] ?? 0,
      productRevenue: json['product_revenue'] ?? 0,
      rentalRevenue: json['rental_revenue'] ?? 0,
      totalRevenue: json['total_revenue'] ?? 0,
      instructorCosts: json['instructor_costs'] ?? 0,
      grossProfit: json['gross_profit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dojo_id': dojoId,
      'dojo_name': dojoName,
      'period': period.toIso8601String(),
      'membership_revenue': membershipRevenue,
      'product_revenue': productRevenue,
      'rental_revenue': rentalRevenue,
      'total_revenue': totalRevenue,
      'instructor_costs': instructorCosts,
      'gross_profit': grossProfit,
    };
  }

  double get profitMargin {
    if (totalRevenue == 0) return 0.0;
    return (grossProfit / totalRevenue) * 100;
  }

  String get formattedTotalRevenue {
    return '¥${totalRevenue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String get formattedGrossProfit {
    return '¥${grossProfit.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  String get formattedInstructorCosts {
    return '¥${instructorCosts.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }
}