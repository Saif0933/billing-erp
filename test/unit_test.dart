import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/permissions/permission_models.dart';
import 'package:frontend/core/permissions/permission_service.dart';
import 'package:frontend/features/subscription/domain/entities/subscription_models.dart';

void main() {
  group('Permission Service Tests', () {
    test('Owner should have all permissions', () {
      for (final perm in AppPermission.values) {
        expect(PermissionService.hasPermission(UserRole.owner, perm), isTrue);
      }
    });

    test('Inventory User should have limited permissions', () {
      expect(
        PermissionService.hasPermission(UserRole.inventoryUser, AppPermission.viewDashboard),
        isTrue,
      );
      expect(
        PermissionService.hasPermission(UserRole.inventoryUser, AppPermission.manageSettings),
        isFalse,
      );
    });
  });

  group('Subscription Gating Tests', () {
    test('Trial plan feature access rules', () {
      final sub = SubscriptionModel(
        plan: PlanType.trial,
        status: SubscriptionStatus.trial,
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 14)),
        allowedFeatures: {
          SubscriptionFeature.dashboard,
          SubscriptionFeature.sales,
        },
      );

      expect(sub.canAccess(SubscriptionFeature.dashboard), isTrue);
      expect(sub.canAccess(SubscriptionFeature.sales), isTrue);
      expect(sub.canAccess(SubscriptionFeature.pos), isFalse);
    });

    test('Expired subscription denies all accesses', () {
      final sub = SubscriptionModel(
        plan: PlanType.premium,
        status: SubscriptionStatus.expired,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().subtract(const Duration(days: 1)),
        allowedFeatures: {
          SubscriptionFeature.dashboard,
          SubscriptionFeature.sales,
        },
      );

      expect(sub.canAccess(SubscriptionFeature.dashboard), isFalse);
      expect(sub.canAccess(SubscriptionFeature.sales), isFalse);
    });
  });
}
