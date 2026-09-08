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
