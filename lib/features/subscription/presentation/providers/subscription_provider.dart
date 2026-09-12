import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/subscription_dto.dart';
import '../../data/services/subscription_api_service.dart';
import '../../domain/entities/subscription_models.dart';

// ============================================================================
// Available SaaS Plans State & Notifier (Fetched from Platform Admin)
// ============================================================================

class PlansState {
  final List<SubscriptionPlanDto> plans;
  final bool isLoading;
  final String? error;
  final String billingCycle; // 'MONTHLY' or 'YEARLY'

  const PlansState({
    this.plans = const [],
    this.isLoading = false,
    this.error,
    this.billingCycle = 'MONTHLY',
  });

  PlansState copyWith({
    List<SubscriptionPlanDto>? plans,
    bool? isLoading,
    String? error,
    String? billingCycle,
  }) {
    return PlansState(
      plans: plans ?? this.plans,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      billingCycle: billingCycle ?? this.billingCycle,
    );
  }
}

class PlansNotifier extends StateNotifier<PlansState> {
  final SubscriptionApiService _apiService;

  PlansNotifier(this._apiService) : super(const PlansState()) {
    fetchPlans();
  }

  void setBillingCycle(String cycle) {
    state = state.copyWith(billingCycle: cycle);
  }

  Future<void> fetchPlans() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final plans = await _apiService.getPlans();
      state = state.copyWith(plans: plans, isLoading: false);
    } catch (e) {
      debugPrint('[PlansNotifier] Error fetching SaaS plans: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final availablePlansProvider =
    StateNotifierProvider<PlansNotifier, PlansState>((ref) {
  final apiService = ref.watch(subscriptionApiServiceProvider);
  return PlansNotifier(apiService);
});

// ============================================================================
// Active Organization Subscription Notifier
// ============================================================================

class SubscriptionNotifier extends StateNotifier<SubscriptionModel> {
  final SubscriptionApiService? _apiService;

  SubscriptionNotifier([this._apiService])
      : super(
          SubscriptionModel(
            plan: PlanType.trial,
            status: SubscriptionStatus.trial,
            startDate: DateTime.now(),
            endDate: DateTime.now().add(const Duration(days: 14)),
            trialEndDate: DateTime.now().add(const Duration(days: 14)),
            allowedFeatures: _getFeaturesForPlan(PlanType.trial),
          ),
        ) {
    if (_apiService != null) {
      loadSubscription();
    }
  }

  static Set<SubscriptionFeature> _getFeaturesForPlan(PlanType plan) {
    switch (plan) {
      case PlanType.trial:
        return Set.from(SubscriptionFeature.values);
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
          SubscriptionFeature.accounting,
          SubscriptionFeature.manufacturing,
          SubscriptionFeature.eInvoice,
          SubscriptionFeature.eWayBill,
          SubscriptionFeature.banking,
        };
      case PlanType.enterprise:
        return Set.from(SubscriptionFeature.values);
    }
  }

  static Set<SubscriptionFeature> getFeaturesForPlanDto(SubscriptionPlanDto plan) {
    final features = <SubscriptionFeature>{
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
      SubscriptionFeature.warehouse,
      SubscriptionFeature.accounting,
      SubscriptionFeature.eInvoice,
      SubscriptionFeature.eWayBill,
      SubscriptionFeature.banking,
    };

    if (plan.hasPOS) {
      features.add(SubscriptionFeature.pos);
    }
    if (plan.hasManufacturing || plan.name.toLowerCase().contains('enterprise')) {
      features.add(SubscriptionFeature.manufacturing);
    }
    if (plan.hasApiAccess || plan.name.toLowerCase().contains('enterprise')) {
      features.add(SubscriptionFeature.api);
    }

    return features;
  }

  /// Load active subscription from backend API
  Future<void> loadSubscription() async {
    if (_apiService == null) return;
    try {
      final activeSub = await _apiService.getActiveSubscription();
      if (activeSub != null) {
        final planType = SubscriptionModel.mapNameToPlanType(activeSub.plan.name);
        final status = SubscriptionModel.mapStatus(activeSub.status);
        final features = getFeaturesForPlanDto(activeSub.plan);

        state = SubscriptionModel(
          plan: planType,
          status: status,
          startDate: activeSub.currentPeriodStart,
          endDate: activeSub.currentPeriodEnd,
          trialEndDate: activeSub.trialEndsAt,
          renewalDate: activeSub.currentPeriodEnd,
          allowedFeatures: features,
          planId: activeSub.plan.id,
          customPlanName: activeSub.plan.name,
          billingCycle: activeSub.billingCycle,
          price: activeSub.billingCycle == 'YEARLY'
              ? activeSub.plan.priceYearly
              : activeSub.plan.priceMonthly,
          maxUsers: activeSub.plan.maxUsers,
          maxInvoicesPerMonth: activeSub.plan.maxInvoicesPerMonth,
          storageLimitGb: activeSub.plan.storageLimitGb,
          featureDescriptions: activeSub.plan.features,
        );
      }
    } catch (e) {
      debugPrint('[SubscriptionNotifier] Error loading active subscription: $e');
    }
  }

  /// Purchase or upgrade subscription through backend API
  Future<void> purchasePlan({
    required String planId,
    required String billingCycle,
    String? paymentGateway,
    String? gatewayPaymentId,
  }) async {
    if (_apiService == null) {
      throw Exception('API service not initialized');
    }

    final activeSub = await _apiService.subscribePlan(
      planId: planId,
      billingCycle: billingCycle,
      paymentGateway: paymentGateway,
      gatewayPaymentId: gatewayPaymentId,
    );

    final planType = SubscriptionModel.mapNameToPlanType(activeSub.plan.name);
    final status = SubscriptionModel.mapStatus(activeSub.status);
    final features = getFeaturesForPlanDto(activeSub.plan);

    state = SubscriptionModel(
      plan: planType,
      status: status,
      startDate: activeSub.currentPeriodStart,
      endDate: activeSub.currentPeriodEnd,
      trialEndDate: activeSub.trialEndsAt,
      renewalDate: activeSub.currentPeriodEnd,
      allowedFeatures: features,
      planId: activeSub.plan.id,
      customPlanName: activeSub.plan.name,
      billingCycle: activeSub.billingCycle,
      price: activeSub.billingCycle == 'YEARLY'
          ? activeSub.plan.priceYearly
          : activeSub.plan.priceMonthly,
      maxUsers: activeSub.plan.maxUsers,
      maxInvoicesPerMonth: activeSub.plan.maxInvoicesPerMonth,
      storageLimitGb: activeSub.plan.storageLimitGb,
      featureDescriptions: activeSub.plan.features,
    );
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
    state = state.copyWith(
      status: SubscriptionStatus.expired,
      endDate: DateTime.now().subtract(const Duration(days: 1)),
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

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionModel>((ref) {
  final apiService = ref.watch(subscriptionApiServiceProvider);
  return SubscriptionNotifier(apiService);
});
