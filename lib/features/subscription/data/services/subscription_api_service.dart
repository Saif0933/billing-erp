import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../models/subscription_dto.dart';

final subscriptionApiServiceProvider = Provider<SubscriptionApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return SubscriptionApiService(client);
});

class SubscriptionApiService {
  final ApiClient _apiClient;

  SubscriptionApiService(this._apiClient);

  /// Fetch all active SaaS subscription plans
  Future<List<SubscriptionPlanDto>> getPlans() async {
    final response = await _apiClient.get(ApiEndpoints.plans);
    final data = response.data;

    List<dynamic> items = [];
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        items = data['data'] as List;
      } else if (data['plans'] is List) {
        items = data['plans'] as List;
      }
    } else if (data is List) {
      items = data;
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map((e) => SubscriptionPlanDto.fromJson(e))
        .toList();
  }

  /// Fetch current active subscription for the authenticated organization
  Future<ActiveSubscriptionDto?> getActiveSubscription() async {
    final response = await _apiClient.get(ApiEndpoints.activeSubscription);
    final data = response.data;

    if (data is Map<String, dynamic> && data['data'] != null) {
      final subMap = data['data'];
      if (subMap is Map<String, dynamic>) {
        return ActiveSubscriptionDto.fromJson(subMap);
      }
    }
    return null;
  }

  /// Subscribe or upgrade to a SaaS plan
  Future<ActiveSubscriptionDto> subscribePlan({
    required String planId,
    required String billingCycle,
    String? paymentGateway,
    String? gatewayPaymentId,
  }) async {
    final body = <String, dynamic>{
      'planId': planId,
      'billingCycle': billingCycle,
    };
    if (paymentGateway != null) {
      body['paymentGateway'] = paymentGateway;
    }
    if (gatewayPaymentId != null) {
      body['gatewayPaymentId'] = gatewayPaymentId;
    }

    final response = await _apiClient.post(
      ApiEndpoints.subscribePlan,
      data: body,
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] ?? data;
      if (payload is Map<String, dynamic>) {
        final subMap = payload['subscription'] ?? payload;
        if (subMap is Map<String, dynamic>) {
          return ActiveSubscriptionDto.fromJson(subMap);
        }
      }
    }

    throw Exception('Failed to parse subscription response from server');
  }
}
