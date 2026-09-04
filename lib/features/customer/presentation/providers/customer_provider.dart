import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/billing_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/customer_dto.dart';
import '../../data/services/customer_api_service.dart';

/// Provider for CustomerApiService
final customerApiServiceProvider = Provider<CustomerApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomerApiService(apiClient);
});

/// State for the Customer Directory screen
class CustomerListState {
  final List<Customer> customers;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String selectedTypeFilter;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final CustomerMetricsDto? metrics;

  const CustomerListState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedTypeFilter = 'All',
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
    this.metrics,
  });

  CustomerListState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    String? selectedTypeFilter,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    CustomerMetricsDto? metrics,
  }) {
    return CustomerListState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTypeFilter: selectedTypeFilter ?? this.selectedTypeFilter,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      metrics: metrics ?? this.metrics,
    );
  }
}

/// StateNotifier for customer operations, connecting the frontend directly to the backend
class CustomerListNotifier extends StateNotifier<CustomerListState> {
  final CustomerApiService _apiService;
  final Ref _ref;

  CustomerListNotifier(this._apiService, this._ref)
      : super(const CustomerListState()) {
    loadCustomers();
  }

  /// Load customers from backend API
  Future<void> loadCustomers({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final typeParam = state.selectedTypeFilter == 'All' ? null : state.selectedTypeFilter;

      final res = await _apiService.getCustomers(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        type: typeParam,
        isActive: true,
        page: state.page,
        limit: state.limit,
      );


      CustomerMetricsDto? metrics;
      try {
        metrics = await _apiService.getCustomerMetrics();
      } catch (_) {}

      state = state.copyWith(
        customers: res.customers,
        total: res.total,
        page: res.page,
        limit: res.limit,
        totalPages: res.totalPages,
        metrics: metrics,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository so offline/local features have active customer list
      _syncToBillingRepo(res.customers);
    } catch (e) {
      // If network/server fails, fall back to billing repository customers
      final fallbackCustomers = _ref.read(billingRepositoryProvider).customers;
      state = state.copyWith(
        customers: fallbackCustomers,
        total: fallbackCustomers.length,
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  /// Update search query and reload
  void setSearchQuery(String query) {
    if (state.searchQuery != query) {
      state = state.copyWith(searchQuery: query, page: 1);
      loadCustomers();
    }
  }

  /// Update type filter and reload
  void setTypeFilter(String type) {
    if (state.selectedTypeFilter != type) {
      state = state.copyWith(selectedTypeFilter: type, page: 1);
      loadCustomers();
    }
  }

  /// Create a new customer on backend
  Future<Customer> addCustomer(Customer customer) async {
    state = state.copyWith(isLoading: true);
    try {
      final created = await _apiService.createCustomer(customer);
      
      final updatedList = [created, ...state.customers];
      state = state.copyWith(
        customers: updatedList,
        total: state.total + 1,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      await _ref.read(billingRepositoryProvider.notifier).addCustomer(created);
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Update an existing customer on backend
  Future<Customer> updateCustomer(Customer customer) async {
    state = state.copyWith(isLoading: true);
    try {
      final updated = await _apiService.updateCustomer(customer);

      final updatedList = state.customers.map((c) => c.id == updated.id ? updated : c).toList();
      state = state.copyWith(
        customers: updatedList,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      await _ref.read(billingRepositoryProvider.notifier).updateCustomer(updated);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  /// Delete a customer on backend
  Future<void> deleteCustomer(String customerId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _apiService.deleteCustomer(customerId);

      final updatedList = state.customers.where((c) => c.id != customerId).toList();
      state = state.copyWith(
        customers: updatedList,
        total: state.total > 0 ? state.total - 1 : 0,
        isLoading: false,
        clearError: true,
      );

      // Sync with billing repository
      await _ref.read(billingRepositoryProvider.notifier).deleteCustomer(customerId);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  void _syncToBillingRepo(List<Customer> list) {
    try {
      _ref.read(billingRepositoryProvider.notifier).setCustomers(list);
    } catch (_) {}
  }
}

/// Main Customer Provider for Customer directory & operations
final customerProvider = StateNotifierProvider<CustomerListNotifier, CustomerListState>((ref) {
  final apiService = ref.watch(customerApiServiceProvider);
  return CustomerListNotifier(apiService, ref);
});

/// Future provider for fetching customer details by ID from backend
final customerDetailProvider = FutureProvider.family<CustomerDetailDto, String>((ref, customerId) async {
  final apiService = ref.watch(customerApiServiceProvider);
  return apiService.getCustomerById(customerId);
});
