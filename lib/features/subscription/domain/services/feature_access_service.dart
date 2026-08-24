import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/subscription_models.dart';
import '../../presentation/providers/subscription_provider.dart';

class FeatureAccessService {
  final SubscriptionModel _subscription;

  FeatureAccessService(this._subscription);

  bool canAccess(SubscriptionFeature feature) {
    return _subscription.canAccess(feature);
  }

  bool canAccessPOS() => canAccess(SubscriptionFeature.pos);
  bool canAccessWarehouse() => canAccess(SubscriptionFeature.warehouse);
  bool canAccessReports() => canAccess(SubscriptionFeature.reports);
  bool canAccessInventory() => canAccess(SubscriptionFeature.inventory);
  bool canAccessLedger() => canAccess(SubscriptionFeature.ledger);
  bool canAccessOutstanding() => canAccess(SubscriptionFeature.outstanding);
  bool canAccessExpenses() => canAccess(SubscriptionFeature.expenses);
}

final featureAccessServiceProvider = Provider<FeatureAccessService>((ref) {
  final subscriptionState = ref.watch(subscriptionProvider);
  return FeatureAccessService(subscriptionState);
});
