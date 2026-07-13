class RidePromo {
  final String id;
  final String code;
  final String name;
  final String description;
  final String discountType; // 'fixed' or 'percentage'
  final double discountValue;
  final double? maxDiscount;
  final double minSpend;
  final String validUntil;
  final String appliesTo;

  RidePromo({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maxDiscount,
    required this.minSpend,
    required this.validUntil,
    required this.appliesTo,
  });

  factory RidePromo.fromJson(Map<String, dynamic> json) {
    return RidePromo(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'fixed',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: json['max_discount'] != null ? (json['max_discount'] as num?)?.toDouble() : null,
      minSpend: (json['min_spend'] as num?)?.toDouble() ?? 0.0,
      validUntil: json['valid_until']?.toString() ?? '',
      appliesTo: json['applies_to']?.toString() ?? 'RIDE',
    );
  }
}
