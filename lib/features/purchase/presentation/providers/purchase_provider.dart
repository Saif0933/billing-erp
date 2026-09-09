import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/billing_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/purchase_dto.dart';
import '../../data/services/purchase_api_service.dart';

final purchaseApiServiceProvider = Provider<PurchaseApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PurchaseApiService(apiClient);
});

class PurchaseListState {
  final List<Purchase> purchases;
  final List<Product> products;
  final List<PurchaseCategoryNode> categories;
  final bool isLoading;
  final bool isSaving;
  final bool isLoadingProducts;
  final String? error;
  final String searchQuery;
  final String selectedStatusFilter;
  final String selectedCategory;
  final String selectedSubCategory;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final PurchaseMetricsDto? metrics;

  const PurchaseListState({
    this.purchases = const [],
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.isLoadingProducts = false,
    this.error,
    this.searchQuery = '',
    this.selectedStatusFilter = 'All',
    this.selectedCategory = 'All',
    this.selectedSubCategory = 'All',
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
    this.metrics,
  });

  List<String> get categoryNames => [
        'All',
        ...categories.map((c) => c.category),
      ];

  List<String> get subCategoryNames {
    if (selectedCategory == 'All') {
      final all = <String>{};
      for (final c in categories) {
        all.addAll(c.subCategories);
      }
      return ['All', ...all];
    }
    final match = categories.where((c) => c.category == selectedCategory);
    if (match.isEmpty) return const ['All'];
    return ['All', ...match.first.subCategories];
  }

  PurchaseListState copyWith({
    List<Purchase>? purchases,
    List<Product>? products,
    List<PurchaseCategoryNode>? categories,
    bool? isLoading,
    bool? isSaving,
    bool? isLoadingProducts,
    String? error,
    bool clearError = false,
    String? searchQuery,
    String? selectedStatusFilter,
    String? selectedCategory,
    String? selectedSubCategory,
    int? total,
    int? page,
    int? limit,
    int? totalPages,
    PurchaseMetricsDto? metrics,
  }) {
    return PurchaseListState(
      purchases: purchases ?? this.purchases,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedSubCategory: selectedSubCategory ?? this.selectedSubCategory,
      total: total ?? this.total,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      totalPages: totalPages ?? this.totalPages,
      metrics: metrics ?? this.metrics,
    );
  }
}

class PurchaseListNotifier extends StateNotifier<PurchaseListState> {
  final PurchaseApiService _apiService;
  final Ref _ref;

  PurchaseListNotifier(this._apiService, this._ref)
      : super(const PurchaseListState()) {
    loadPurchases();
    loadProducts();
    loadCategories();
  }

  Future<void> loadPurchases({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiService.getPurchases(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        status: state.selectedStatusFilter,
        page: state.page,
        limit: state.limit,
      );

      PurchaseMetricsDto? metrics;
      try {
        metrics = await _apiService.getMetrics();
      } catch (_) {}

      state = state.copyWith(
        purchases: res.purchases,
        total: res.total,
        page: res.page,
        limit: res.limit,
        totalPages: res.totalPages,
        metrics: metrics,
        isLoading: false,
        clearError: true,
      );

      _syncPurchasesToBillingRepo(res.purchases);
    } catch (e) {
      final fallback = _ref.read(billingRepositoryProvider).purchases;
      state = state.copyWith(
        purchases: fallback,
        total: fallback.length,
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<void> loadProducts({String? search}) async {
    state = state.copyWith(isLoadingProducts: true);
    try {
      final res = await _apiService.getPurchaseProducts(
        search: search,
        category: state.selectedCategory,
        subCategory: state.selectedSubCategory,
        limit: 100,
      );

      state = state.copyWith(
        products: res.products,
        isLoadingProducts: false,
        clearError: true,
      );

      try {
        _ref.read(billingRepositoryProvider.notifier).setProducts(res.products);
      } catch (_) {}
    } catch (e) {
      final fallback = _ref.read(billingRepositoryProvider).products;
      state = state.copyWith(
        products: fallback,
        isLoadingProducts: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _apiService.getProductCategories();
      state = state.copyWith(categories: categories);
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query, page: 1);
    loadPurchases();
  }

  void setStatusFilter(String status) {
    if (state.selectedStatusFilter == status) return;
    state = state.copyWith(selectedStatusFilter: status, page: 1);
    loadPurchases();
  }

  void setCategoryFilter(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(
      selectedCategory: category,
      selectedSubCategory: 'All',
    );
    loadProducts();
  }

  void setSubCategoryFilter(String subCategory) {
    if (state.selectedSubCategory == subCategory) return;
    state = state.copyWith(selectedSubCategory: subCategory);
    loadProducts();
  }

  Future<String> getNextPurchaseNumber() {
    return _apiService.getNextPurchaseNumber();
  }

  Future<Purchase> createPurchase(
    Purchase purchase, {
    required PurchaseStatus saveAs,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final created = await _apiService.createPurchase(
        purchase,
        saveAs: saveAs,
      );

      final updatedList = [created, ...state.purchases];
      state = state.copyWith(
        purchases: updatedList,
        total: state.total + 1,
        isSaving: false,
        clearError: true,
      );

      _syncPurchasesToBillingRepo(updatedList);
      return created;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
      rethrow;
    }
  }

  Future<Purchase> confirmPurchase(String purchaseId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final confirmed = await _apiService.confirmPurchase(purchaseId);
      final updatedList = state.purchases
          .map((p) => p.id == confirmed.id ? confirmed : p)
          .toList();
      state = state.copyWith(
        purchases: updatedList,
        isSaving: false,
        clearError: true,
      );
      _syncPurchasesToBillingRepo(updatedList);
      return confirmed;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
      rethrow;
    }
  }

  Future<Purchase> cancelPurchase(String purchaseId) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final cancelled = await _apiService.cancelPurchase(purchaseId);
      final updatedList = state.purchases
          .map((p) => p.id == cancelled.id ? cancelled : p)
          .toList();
      state = state.copyWith(
        purchases: updatedList,
        isSaving: false,
        clearError: true,
      );
      _syncPurchasesToBillingRepo(updatedList);
      return cancelled;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
      );
      rethrow;
    }
  }

  Future<Product> createProductFromPurchase({
    required String name,
    String? itemCode,
    String? hsnCode,
    String primaryUnit = 'PCS',
    double gstRate = 0,
    double purchasePrice = 0,
    double sellingPrice = 0,
    String? category,
    String? subCategory,
    String? brand,
  }) async {
    final product = await _apiService.createPurchaseProduct(
      name: name,
      itemCode: itemCode,
      hsnCode: hsnCode,
      primaryUnit: primaryUnit,
      gstRate: gstRate,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      mrp: sellingPrice,
      category: category,
      subCategory: subCategory,
      brand: brand,
    );

    state = state.copyWith(products: [product, ...state.products]);
    try {
      await _ref.read(billingRepositoryProvider.notifier).addProduct(product);
    } catch (_) {}
    await loadCategories();
    return product;
  }

  Future<Purchase?> getPurchaseById(String id) async {
    try {
      final purchase = await _apiService.getPurchaseById(id);
      final exists = state.purchases.any((p) => p.id == id);
      final updatedList = exists
          ? state.purchases.map((p) => p.id == id ? purchase : p).toList()
          : [purchase, ...state.purchases];
      state = state.copyWith(purchases: updatedList);
      _syncPurchasesToBillingRepo(updatedList);
      return purchase;
    } catch (_) {
      try {
        return state.purchases.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  void _syncPurchasesToBillingRepo(List<Purchase> list) {
    try {
      _ref.read(billingRepositoryProvider.notifier).setPurchases(list);
    } catch (_) {}
  }
}

final purchaseProvider =
    StateNotifierProvider<PurchaseListNotifier, PurchaseListState>((ref) {
  final apiService = ref.watch(purchaseApiServiceProvider);
  return PurchaseListNotifier(apiService, ref);
});

final purchaseDetailProvider =
    FutureProvider.family<Purchase?, String>((ref, purchaseId) async {
  final notifier = ref.read(purchaseProvider.notifier);
  return notifier.getPurchaseById(purchaseId);
});
