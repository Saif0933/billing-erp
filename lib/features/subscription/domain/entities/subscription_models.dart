enum SubscriptionStatus {
  trial,
  active,
  pastDue,
  expired,
  cancelled,
  suspended;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.trial:
        return 'Trial';
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.pastDue:
        return 'Past due';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.cancelled:
        return 'Cancelled';
      case SubscriptionStatus.suspended:
        return 'Suspended';
    }
  }
}

enum SubscriptionFeature {
  dashboard,
  customers,
  suppliers,
  products,
  services,
  sales,
  purchase,
  payments,
  receipts,
  ledger,
  outstanding,
  inventory,
  gst,
  expenses,
  reports,
  pos,
  warehouse,
  accounting,
  manufacturing,
  eInvoice,
  eWayBill,
  banking,
  api;

  String get displayName {
    switch (this) {
      case SubscriptionFeature.dashboard:
        return 'Dashboard';
      case SubscriptionFeature.customers:
        return 'Customers';
      case SubscriptionFeature.suppliers:
        return 'Suppliers';
      case SubscriptionFeature.products:
        return 'Products';
      case SubscriptionFeature.services:
        return 'Services';
      case SubscriptionFeature.sales:
        return 'Sales';
      case SubscriptionFeature.purchase:
        return 'Purchases';
      case SubscriptionFeature.payments:
        return 'Payments';
      case SubscriptionFeature.receipts:
        return 'Receipts';
      case SubscriptionFeature.ledger:
        return 'Ledger';
      case SubscriptionFeature.outstanding:
        return 'Outstanding';
      case SubscriptionFeature.inventory:
        return 'Inventory';
      case SubscriptionFeature.gst:
        return 'GST';
      case SubscriptionFeature.expenses:
        return 'Expenses';
      case SubscriptionFeature.reports:
        return 'Reports';
      case SubscriptionFeature.pos:
        return 'POS';
      case SubscriptionFeature.warehouse:
        return 'Warehouse';
      case SubscriptionFeature.accounting:
        return 'Accounting';
      case SubscriptionFeature.manufacturing:
        return 'Manufacturing';
      case SubscriptionFeature.eInvoice:
        return 'E-Invoice';
      case SubscriptionFeature.eWayBill:
        return 'E-Way Bill';
      case SubscriptionFeature.banking:
        return 'Banking';
      case SubscriptionFeature.api:
        return 'API access';
    }
  }
}

enum PlanType {
  trial('Trial Plan'),
  basic('Basic Billing'),
  premium('Standard Premium'),
  enterprise('Enterprise Custom');

  final String displayName;
  const PlanType(this.displayName);
}

class SubscriptionModel {
  final PlanType plan;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? trialEndDate;
  final DateTime? renewalDate;
  final Set<SubscriptionFeature> allowedFeatures;

  // Dynamic plan fields from backend
  final String? planId;
  final String? customPlanName;
  final String? billingCycle;
  final double? price;
  final int? maxUsers;
  final int? maxInvoicesPerMonth;
  final double? storageLimitGb;
  final List<String> featureDescriptions;

  const SubscriptionModel({
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.trialEndDate,
    this.renewalDate,
    required this.allowedFeatures,
    this.planId,
    this.customPlanName,
    this.billingCycle,
    this.price,
    this.maxUsers,
    this.maxInvoicesPerMonth,
    this.storageLimitGb,
    this.featureDescriptions = const [],
  });

  String get displayName => customPlanName ?? plan.displayName;

  bool canAccess(SubscriptionFeature feature) {
    if (status == SubscriptionStatus.expired || status == SubscriptionStatus.suspended) {
      return false;
    }
    return allowedFeatures.contains(feature);
  }

  SubscriptionModel copyWith({
    PlanType? plan,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? trialEndDate,
    DateTime? renewalDate,
    Set<SubscriptionFeature>? allowedFeatures,
    String? planId,
    String? customPlanName,
    String? billingCycle,
    double? price,
    int? maxUsers,
    int? maxInvoicesPerMonth,
    double? storageLimitGb,
    List<String>? featureDescriptions,
  }) {
    return SubscriptionModel(
      plan: plan ?? this.plan,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      renewalDate: renewalDate ?? this.renewalDate,
      allowedFeatures: allowedFeatures ?? this.allowedFeatures,
      planId: planId ?? this.planId,
      customPlanName: customPlanName ?? this.customPlanName,
      billingCycle: billingCycle ?? this.billingCycle,
      price: price ?? this.price,
      maxUsers: maxUsers ?? this.maxUsers,
      maxInvoicesPerMonth: maxInvoicesPerMonth ?? this.maxInvoicesPerMonth,
      storageLimitGb: storageLimitGb ?? this.storageLimitGb,
      featureDescriptions: featureDescriptions ?? this.featureDescriptions,
    );
  }

  static PlanType mapNameToPlanType(String? name) {
    if (name == null) return PlanType.trial;
    final lower = name.toLowerCase();
    if (lower.contains('enterprise')) return PlanType.enterprise;
    if (lower.contains('growth') || lower.contains('premium') || lower.contains('pro')) {
      return PlanType.premium;
    }
    if (lower.contains('basic') || lower.contains('starter')) return PlanType.basic;
    if (lower.contains('trial')) return PlanType.trial;
    return PlanType.premium;
  }

  static SubscriptionStatus mapStatus(String? status) {
    if (status == null) return SubscriptionStatus.trial;
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return SubscriptionStatus.active;
      case 'TRIALING':
      case 'TRIAL':
        return SubscriptionStatus.trial;
      case 'PAST_DUE':
        return SubscriptionStatus.pastDue;
      case 'EXPIRED':
        return SubscriptionStatus.expired;
      case 'CANCELLED':
        return SubscriptionStatus.cancelled;
      case 'SUSPENDED':
        return SubscriptionStatus.suspended;
      default:
        return SubscriptionStatus.active;
    }
  }
}
