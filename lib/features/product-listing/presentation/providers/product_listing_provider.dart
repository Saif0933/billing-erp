import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/product_dto.dart';
import '../../data/services/product_api_service.dart';
import '../../domain/models/product_listing_models.dart';
import '../../domain/utils/barcode_validator.dart';
import 'billing_cart_provider.dart';

class ProductListingState {
  final List<ProductListingItem> allProducts;
  final List<ProductListingItem> recentScans;
  final String searchQuery;
  final String selectedCategory;
  final int currentPage;
  final int itemsPerPage;
  final bool isTorchOn;
  final bool isScanning;
  final ProductListingItem? lastScannedItem;
  final bool isLoading;
  final String? error;
  final ProductMetricsDto? metrics;

  const ProductListingState({
    required this.allProducts,
    required this.recentScans,
    this.searchQuery = '',
    this.selectedCategory = 'All',
    this.currentPage = 1,
    this.itemsPerPage = 8,
    this.isTorchOn = false,
    this.isScanning = false,
    this.lastScannedItem,
    this.isLoading = false,
    this.error,
    this.metrics,
  });

  List<ProductListingItem> get filteredProducts {
    return allProducts.where((p) {
      final matchesCategory = selectedCategory == 'All' ||
          p.category.toLowerCase() == selectedCategory.toLowerCase() ||
          (selectedCategory == 'Groceries' &&
              (p.category == 'Dairy' ||
                  p.category == 'Biscuits' ||
                  p.category == 'Home Care'));

      final q = searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get totalPages =>
      (filteredProducts.length / itemsPerPage).ceil().clamp(1, 999);

  List<ProductListingItem> get paginatedProducts {
    final filtered = filteredProducts;
    final startIndex = (currentPage - 1) * itemsPerPage;
    if (startIndex >= filtered.length) {
      return [];
    }
    final endIndex = (startIndex + itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  int get totalProductsCount => metrics?.totalProducts ?? allProducts.length;

  List<String> get availableCategories {
    final cats = {'All', ...allProducts.map((p) => p.category).where((c) => c.isNotEmpty)};
    return cats.toList();
  }

  ProductListingState copyWith({
    List<ProductListingItem>? allProducts,
    List<ProductListingItem>? recentScans,
    String? searchQuery,
    String? selectedCategory,
    int? currentPage,
    int? itemsPerPage,
    bool? isTorchOn,
    bool? isScanning,
    ProductListingItem? lastScannedItem,
    bool? isLoading,
    String? error,
    bool clearError = false,
    ProductMetricsDto? metrics,
  }) {
    return ProductListingState(
      allProducts: allProducts ?? this.allProducts,
      recentScans: recentScans ?? this.recentScans,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      isTorchOn: isTorchOn ?? this.isTorchOn,
      isScanning: isScanning ?? this.isScanning,
      lastScannedItem: lastScannedItem ?? this.lastScannedItem,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      metrics: metrics ?? this.metrics,
    );
  }
}

class ProductListingNotifier extends StateNotifier<ProductListingState> {
  final ProductApiService? _apiService;
  final Ref? _ref;

  ProductListingNotifier([this._apiService, this._ref])
      : super(
          const ProductListingState(
            allProducts: [],
            recentScans: [],
            isLoading: true,
          ),
        ) {
    if (_apiService != null) {
      loadProducts();
    } else {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Load products from backend REST API (no mock fallback)
  Future<void> loadProducts({bool refresh = false}) async {
    final api = _apiService;
    if (api == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final res = await api.getProducts(
        search: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        category: state.selectedCategory == 'All' ? null : state.selectedCategory,
        limit: 100,
      );

      ProductMetricsDto? metrics;
      try {
        metrics = await api.getProductMetrics();
      } catch (_) {}

      final items = res.products.map((dto) => dto.toListingItem()).toList();

      state = state.copyWith(
        allProducts: items,
        metrics: metrics,
        isLoading: false,
        clearError: true,
      );

      final ref = _ref;
      if (ref != null) {
        try {
          final billingProducts =
              res.products.map((dto) => dto.toBillingProduct()).toList();
          ref.read(billingRepositoryProvider.notifier).setProducts(billingProducts);
        } catch (_) {}
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception:', '').trim(),
        allProducts: [],
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category, currentPage: 1);
  }

  void setPage(int page) {
    if (page >= 1 && page <= state.totalPages) {
      state = state.copyWith(currentPage: page);
    }
  }

  void toggleTorch() {
    state = state.copyWith(isTorchOn: !state.isTorchOn);
  }

  /// Barcode handler for camera & keyboard scanner (catalogue directory).
  /// Does not invent fake prices — unknown barcodes return null so UI can prompt for details.
  ProductListingItem? handleScannedBarcode(String rawCode) {
    final validation = BarcodeValidator.validate(rawCode);
    if (!validation.isValid) {
      return null;
    }

    final cleanCode = validation.cleanBarcode!;

    final existingIndex = state.allProducts.indexWhere(
      (p) =>
          p.barcode.trim() == cleanCode ||
          (p.sku.trim().isNotEmpty &&
              p.sku.trim().toLowerCase() == cleanCode.toLowerCase()),
    );

    if (existingIndex == -1) {
      return null;
    }

    final existing = state.allProducts[existingIndex];
    final scannedItem = existing.copyWith(lastScannedAt: DateTime.now());

    final updatedAll = List<ProductListingItem>.from(state.allProducts);
    updatedAll.removeAt(existingIndex);
    updatedAll.insert(0, scannedItem);

    final updatedScans = [
      scannedItem,
      ...state.recentScans.where((p) => p.barcode != scannedItem.barcode),
    ].take(6).toList();

    state = state.copyWith(
      allProducts: updatedAll,
      recentScans: updatedScans,
      lastScannedItem: scannedItem,
      currentPage: 1,
    );

    return scannedItem;
  }

  void updateProduct(ProductListingItem updatedItem) {
    final updatedAll = state.allProducts.map((p) {
      if (p.id == updatedItem.id || p.barcode == updatedItem.barcode) {
        return updatedItem;
      }
      return p;
    }).toList();

    final updatedScans = state.recentScans.map((p) {
      if (p.id == updatedItem.id || p.barcode == updatedItem.barcode) {
        return updatedItem;
      }
      return p;
    }).toList();

    state = state.copyWith(
      allProducts: updatedAll,
      recentScans: updatedScans,
      lastScannedItem: updatedItem,
    );
  }

  Future<void> deleteProduct(String productId) async {
    final api = _apiService;
    if (api != null) {
      try {
        await api.deleteProduct(productId);
      } catch (_) {}
    }

    final updatedAll =
        state.allProducts.where((p) => p.id != productId).toList();
    final updatedScans =
        state.recentScans.where((p) => p.id != productId).toList();

    state = state.copyWith(
      allProducts: updatedAll,
      recentScans: updatedScans,
      metrics: state.metrics != null
          ? ProductMetricsDto(
              totalProducts: state.metrics!.totalProducts > 0
                  ? state.metrics!.totalProducts - 1
                  : 0,
              activeProducts: state.metrics!.activeProducts > 0
                  ? state.metrics!.activeProducts - 1
                  : 0,
              inactiveProducts: state.metrics!.inactiveProducts,
              lowStockCount: state.metrics!.lowStockCount,
              totalStockValue: state.metrics!.totalStockValue,
              totalCategories: state.metrics!.totalCategories,
              categories: state.metrics!.categories,
            )
          : null,
    );

    final ref = _ref;
    if (ref != null) {
      try {
        ref.read(billingRepositoryProvider.notifier).deleteProduct(productId);
      } catch (_) {}
    }
  }

  void addScannedItem(ProductListingItem scannedItem) {
    handleScannedBarcode(scannedItem.barcode);
  }

  Future<ProductListingItem?> simulateScan() async {
    if (state.allProducts.isEmpty) return null;
    state = state.copyWith(isScanning: true);
    await Future.delayed(const Duration(milliseconds: 600));

    final itemToScan =
        state.allProducts[DateTime.now().second % state.allProducts.length];
    final result = handleScannedBarcode(itemToScan.barcode);
    state = state.copyWith(isScanning: false);
    return result ?? itemToScan;
  }
}

final productListingProvider =
    StateNotifierProvider<ProductListingNotifier, ProductListingState>((ref) {
  final apiService = ref.watch(productApiServiceProvider);
  return ProductListingNotifier(apiService, ref);
});
