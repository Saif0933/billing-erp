class SubscriptionPlanDto {
  final String id;
  final String name;
  final String tagline;
  final double priceMonthly;
  final double priceYearly;
  final int maxUsers;
  final int maxInvoicesPerMonth;
  final double storageLimitGb;
  final List<String> features;
  final bool isPopular;
  final String themeColor;
  final bool hasPOS;
  final bool hasManufacturing;
  final bool hasAdvancedReports;
  final bool hasApiAccess;

  const SubscriptionPlanDto({
    required this.id,
    required this.name,
    required this.tagline,
    required this.priceMonthly,
    required this.priceYearly,
    required this.maxUsers,
    required this.maxInvoicesPerMonth,
    required this.storageLimitGb,
    required this.features,
    required this.isPopular,
    required this.themeColor,
    this.hasPOS = false,
    this.hasManufacturing = false,
    this.hasAdvancedReports = false,
    this.hasApiAccess = false,
  });

  factory SubscriptionPlanDto.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final features = <String>[];
    if (rawFeatures is List) {
      for (final f in rawFeatures) {
        if (f != null && f.toString().trim().isNotEmpty) {
          features.add(f.toString().trim());
        }
      }
    }

    final priceMonthly = (json['priceMonthly'] as num?)?.toDouble() ??
        (json['price'] as num?)?.toDouble() ??
        0.0;
    final priceYearly = (json['priceYearly'] as num?)?.toDouble() ?? (priceMonthly * 10);

    return SubscriptionPlanDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      priceMonthly: priceMonthly,
      priceYearly: priceYearly,
      maxUsers: (json['maxUsers'] as num?)?.toInt() ?? 10,
      maxInvoicesPerMonth: (json['maxInvoicesPerMonth'] as num?)?.toInt() ?? 5000,
      storageLimitGb: (json['storageLimitGb'] as num?)?.toDouble() ?? 25.0,
      features: features,
      isPopular: json['isPopular'] == true,
      themeColor: json['themeColor']?.toString() ?? '#2563EB',
      hasPOS: json['hasPOS'] == true,
      hasManufacturing: json['hasManufacturing'] == true,
      hasAdvancedReports: json['hasAdvancedReports'] == true,
      hasApiAccess: json['hasApiAccess'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'priceMonthly': priceMonthly,
      'priceYearly': priceYearly,
      'maxUsers': maxUsers,
      'maxInvoicesPerMonth': maxInvoicesPerMonth,
      'storageLimitGb': storageLimitGb,
      'features': features,
      'isPopular': isPopular,
      'themeColor': themeColor,
      'hasPOS': hasPOS,
      'hasManufacturing': hasManufacturing,
      'hasAdvancedReports': hasAdvancedReports,
      'hasApiAccess': hasApiAccess,
    };
  }
}

class ActiveSubscriptionDto {
  final String id;
  final String businessId;
  final String status;
  final String billingCycle;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? trialEndsAt;
  final DateTime? cancelledAt;
  final bool autoRenew;
  final SubscriptionPlanDto plan;

  const ActiveSubscriptionDto({
    required this.id,
    required this.businessId,
    required this.status,
    required this.billingCycle,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.trialEndsAt,
    this.cancelledAt,
    required this.autoRenew,
    required this.plan,
  });

  factory ActiveSubscriptionDto.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null) return DateTime.now();
      try {
        return DateTime.parse(dateStr.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    DateTime? parseOptionalDate(dynamic dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr.toString());
      } catch (_) {
        return null;
      }
    }

    final planJson = json['plan'] is Map<String, dynamic>
        ? json['plan'] as Map<String, dynamic>
        : <String, dynamic>{};

    return ActiveSubscriptionDto(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'TRIALING',
      billingCycle: json['billingCycle']?.toString() ?? 'MONTHLY',
      currentPeriodStart: parseDate(json['currentPeriodStart']),
      currentPeriodEnd: parseDate(json['currentPeriodEnd']),
      trialEndsAt: parseOptionalDate(json['trialEndsAt']),
      cancelledAt: parseOptionalDate(json['cancelledAt']),
      autoRenew: json['autoRenew'] ?? true,
      plan: SubscriptionPlanDto.fromJson(planJson),
    );
  }
}
