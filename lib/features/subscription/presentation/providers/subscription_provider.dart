import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/subscription_models.dart';

class SubscriptionNotifier extends StateNotifier<SubscriptionModel> {
  SubscriptionNotifier()
      : super(
          SubscriptionModel(
            plan: PlanType.trial,
            status: SubscriptionStatus.trial,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 14)),
            trialEndDate: DateTime.now().add(const Duration(days: 14)),
            allowedFeatures: _getFeaturesForPlan(PlanType.trial),
          ),
        );

  static Set<SubscriptionFeature> _getFeaturesForPlan(PlanType plan) {
    switch (plan) {
      case PlanType.trial:
        return {
          SubscriptionFeature.dashboard,
          SubscriptionFeature.customers,
          SubscriptionFeature.suppliers,
          SubscriptionFeature.products,
          SubscriptionFeature.services,
          SubscriptionFeature.sales,
          SubscriptionFeature.purchase,
          SubscriptionFeature.payments,
          SubscriptionFeature.receipts,
          SubscriptionFeature.reports,
        };
      case PlanType.basic:
        return {
          SubscriptionFeature.dashboard,
          SubscriptionFeature.customers,
          SubscriptionFeature.suppliers,
          SubscriptionFeature.products,
          SubscriptionFeature.services,
          SubscriptionFeature.sales,
          SubscriptionFeature.payments,
          SubscriptionFeature.receipts,
        };
      case PlanType.premium:
        return {
          SubscriptionFeature.dashboard,
          SubscriptionFeature.customers,
          SubscriptionFeature.suppliers,
          SubscriptionFeature.products,
          SubscriptionFeature.services,
          SubscriptionFeature.sales,
          SubscriptionFeature.purchase,
          SubscriptionFeature.payments,
          SubscriptionFeature.receipts,
          SubscriptionFeature.ledger,
          SubscriptionFeature.outstanding,
          SubscriptionFeature.inventory,
          SubscriptionFeature.gst,
          SubscriptionFeature.expenses,
          SubscriptionFeature.reports,
          SubscriptionFeature.pos,
          SubscriptionFeature.warehouse,
          SubscriptionFeature.eInvoice,
          SubscriptionFeature.eWayBill,
          SubscriptionFeature.banking,
        };
      case PlanType.enterprise:
        return Set.from(SubscriptionFeature.values);
    }
  }

  Future<void> upgradeTo(PlanType newPlan) async {
    await Future.delayed(const Duration(milliseconds: 300));
    state = SubscriptionModel(
      plan: newPlan,
      status: SubscriptionStatus.active,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 365)),
      renewalDate: DateTime.now().add(const Duration(days: 365)),
      allowedFeatures: _getFeaturesForPlan(newPlan),
    );
  }

  Future<void> simulateExpiry() async {
    state = SubscriptionModel(
      plan: state.plan,
      status: SubscriptionStatus.expired,
      startDate: state.startDate,
      endDate: DateTime.now().subtract(const Duration(days: 1)),
      allowedFeatures: state.allowedFeatures,
    );
  }

  Future<void> resetToTrial() async {
    state = SubscriptionModel(
      plan: PlanType.trial,
      status: SubscriptionStatus.trial,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 14)),
      trialEndDate: DateTime.now().add(const Duration(days: 14)),
      allowedFeatures: _getFeaturesForPlan(PlanType.trial),
    );
  }
}

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionModel>((ref) {
  return SubscriptionNotifier();
});
