class BillSettings {
  final double serviceCharge;
  final double vat;
  final double tip;
  final double discount;
  final String currency;
  final bool isVat;
  final bool isService;

  const BillSettings({
    this.serviceCharge = 0,
    this.vat = 0,
    this.tip = 0,
    this.discount = 0,
    this.currency = 'THB',
    this.isVat = false,
    this.isService = false,
  });

  factory BillSettings.fromJson(Map<String, dynamic> json) {
    return BillSettings(
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble() ?? 0,
      vat: (json['vat'] as num?)?.toDouble() ?? 0,
      tip: (json['tip'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'THB',
      isVat: json['isVat'] as bool? ?? false,
      isService: json['isService'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'serviceCharge': serviceCharge,
        'vat': vat,
        'tip': tip,
        'discount': discount,
        'currency': currency,
        'isVat': isVat,
        'isService': isService,
      };

  BillSettings copyWith({
    double? serviceCharge,
    double? vat,
    double? tip,
    double? discount,
    String? currency,
    bool? isVat,
    bool? isService,
  }) {
    return BillSettings(
      serviceCharge: serviceCharge ?? this.serviceCharge,
      vat: vat ?? this.vat,
      tip: tip ?? this.tip,
      discount: discount ?? this.discount,
      currency: currency ?? this.currency,
      isVat: isVat ?? this.isVat,
      isService: isService ?? this.isService,
    );
  }
}
