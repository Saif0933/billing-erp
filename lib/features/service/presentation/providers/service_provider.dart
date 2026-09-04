import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/billing_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/service_dto.dart';
import '../../data/services/service_api_service.dart';

/// Provider for ServiceApiService
final serviceApiServiceProvider = Provider<ServiceApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServiceApiService(apiClient);
});

/// State for the Service Directory screen
class ServiceListState {
  final List<Service> services;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedUnitFilter;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final ServiceMetricsDto? metrics;

  const ServiceListState({
    this.services = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedUnitFilter = 'All',
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
    this.metrics,
  });

  ServiceListState copyWith({
    List<Service>? services,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    String? selectedUnitFilter,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    ServiceMetricsDto? metrics,
  }) {
    return ServiceListState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedUnitFilter: selectedUnitFilter ?? this.selectedUnitFilter,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      metrics: metrics ?? this.metrics,
    );
  }
}

/// StateNotifier for service operations, connecting frontend directly to backend
class ServiceListNotifier extends StateNotifier<ServiceListState> {
  final ServiceApiService _apiService;
  final Ref _ref;

  ServiceListNotifier(this._apiService, this._ref)
      : super(const ServiceListState()) {
    loadServices();
  }

  /// Load services from backend API
  Future<void> loadServices({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final unitParam = state.selectedUnitFilter == 'All'
          ? null
          : state.selectedUnitFilter;

      final res = await _apiService.getServices(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        unit: unitParam,
        isActive: true, // Only fetch active services
        page: state.page,
        limit: state.limit,
      );

      ServiceMetricsDto? metrics;
      try {
        metrics = await _apiService.getServiceMetrics();
      } catch (_) {}

      state = state.copyWith(
        services: res.services,
        total: res.total,
        page: res.page,
        limit: res.limit,
        totalPages: res.totalPages,
        metrics: metrics,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      _syncToBillingRepo(res.services);
    } catch (e) {
      // If network/server fails, fall back to billing repository services
      final fallbackServices =
          _ref.read(billingRepositoryProvider).services;
      state = state.copyWith(
        services: fallbackServices,
        total: fallbackServices.length,
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  /// Update search query and reload
  void setSearchQuery(String query) {
    if (state.searchQuery != query) {
      state = state.copyWith(searchQuery: query, page: 1);
      loadServices();
    }
  }

  /// Update unit filter and reload
  void setUnitFilter(String unit) {
    if (state.selectedUnitFilter != unit) {
      state = state.copyWith(selectedUnitFilter: unit, page: 1);
      loadServices();
    }
  }

  /// Create a new service on backend
  Future<Service> addService(Service service) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _apiService.createService(service);

      final updatedList = [created, ...state.services];
      state = state.copyWith(
        services: updatedList,
        total: state.total + 1,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      await _ref.read(billingRepositoryProvider.notifier).addService(created);
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Update an existing service on backend
  Future<Service> updateService(Service service) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _apiService.updateService(service);

      final updatedList = state.services
          .map((s) => s.id == updated.id ? updated : s)
          .toList();
      state = state.copyWith(
        services: updatedList,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      await _ref
          .read(billingRepositoryProvider.notifier)
          .updateService(updated);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Delete a service on backend
  Future<void> deleteService(String serviceId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteService(serviceId);

      final updatedList =
          state.services.where((s) => s.id != serviceId).toList();
      state = state.copyWith(
        services: updatedList,
        total: state.total > 0 ? state.total - 1 : 0,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      await _ref
          .read(billingRepositoryProvider.notifier)
          .deleteService(serviceId);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void _syncToBillingRepo(List<Service> list) {
    try {
      _ref.read(billingRepositoryProvider.notifier).setServices(list);
    } catch (_) {}
  }
}

/// Main Service Provider for Service directory & operations
final serviceProvider =
    StateNotifierProvider<ServiceListNotifier, ServiceListState>((ref) {
  final apiService = ref.watch(serviceApiServiceProvider);
  return ServiceListNotifier(apiService, ref);
});

/// Future provider for fetching single service details by ID
final serviceDetailProvider =
    FutureProvider.family<Service, String>((ref, serviceId) async {
  final apiService = ref.watch(serviceApiServiceProvider);
  return apiService.getServiceById(serviceId);
});
