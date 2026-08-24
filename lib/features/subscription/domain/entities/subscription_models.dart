enum SubscriptionStatus {
  trial,
  active,
  pastDue,
  expired,
  cancelled,
  suspended;
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

  const SubscriptionModel({
    required this.plan,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.trialEndDate,
    this.renewalDate,
    required this.allowedFeatures,
  });

  bool canAccess(SubscriptionFeature feature) {
    if (status == SubscriptionStatus.expired || status == SubscriptionStatus.suspended) {
      return false;
    }
    return allowedFeatures.contains(feature);
  }
}
