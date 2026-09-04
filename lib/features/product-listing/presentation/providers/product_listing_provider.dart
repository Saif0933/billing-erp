import 'package:flutter/material.dart';
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

  /// Dynamic list of categories discovered from all loaded products
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
          ProductListingState(
            allProducts: _mockProducts,
            recentScans: _mockRecentScans,
          ),
        ) {
    if (_apiService != null) {
      loadProducts();
    }
  }

  static final List<ProductListingItem> _mockProducts = [
    ProductListingItem(
      id: 'prod_01',
      name: 'Amul Gold Milk 1L',
      barcode: '8901262000012',
      sku: 'AML-GLD-1L',
      category: 'Dairy',
      mrp: 70.00,
      sellingPrice: 62.00,
      stock: 48,
      categoryBadgeBg: const Color(0xFFE0F2FE),
      categoryBadgeText: const Color(0xFF0284C7),
      placeholderIcon: Icons.local_drink_outlined,
      iconColor: const Color(0xFF0284C7),
    ),
    ProductListingItem(
      id: 'prod_02',
      name: 'Maggi Noodles 70g',
      barcode: '8901000100712',
      sku: 'MAG-NDL-70G',
      category: 'Snacks',
      mrp: 20.00,
      sellingPrice: 15.00,
      stock: 120,
      categoryBadgeBg: const Color(0xFFFFEDD5),
      categoryBadgeText: const Color(0xFFEA580C),
      placeholderIcon: Icons.ramen_dining_outlined,
      iconColor: const Color(0xFFEA580C),
    ),
    ProductListingItem(
      id: 'prod_03',
      name: 'Parle-G Biscuit 200g',
      barcode: '8901719570017',
      sku: 'PRL-G-200G',
      category: 'Biscuits',
      mrp: 35.00,
      sellingPrice: 28.00,
      stock: 85,
      categoryBadgeBg: const Color(0xFFF3E8FF),
      categoryBadgeText: const Color(0xFF9333EA),
      placeholderIcon: Icons.cookie_outlined,
      iconColor: const Color(0xFF9333EA),
    ),
    ProductListingItem(
      id: 'prod_04',
      name: 'Coca Cola 500ml',
      barcode: '5449000200427',
      sku: 'CC-500ML',
      category: 'Beverages',
      mrp: 50.00,
      sellingPrice: 40.00,
      stock: 60,
      categoryBadgeBg: const Color(0xFFDCFCE7),
      categoryBadgeText: const Color(0xFF16A34A),
      placeholderIcon: Icons.water_drop_outlined,
      iconColor: const Color(0xFF16A34A),
    ),
    ProductListingItem(
      id: 'prod_05',
      name: 'Maaza 1L',
      barcode: '8901088020018',
      sku: 'MZA-1L',
      category: 'Beverages',
      mrp: 60.00,
      sellingPrice: 52.00,
      stock: 72,
      categoryBadgeBg: const Color(0xFFDCFCE7),
      categoryBadgeText: const Color(0xFF16A34A),
      placeholderIcon: Icons.local_bar_outlined,
      iconColor: const Color(0xFF16A34A),
    ),
    ProductListingItem(
      id: 'prod_06',
      name: 'Surf Excel 1kg',
      barcode: '8901030061108',
      sku: 'SRF-XCL-1KG',
      category: 'Home Care',
      mrp: 160.00,
      sellingPrice: 135.00,
      stock: 34,
      categoryBadgeBg: const Color(0xFFCCFBF1),
      categoryBadgeText: const Color(0xFF0D9488),
      placeholderIcon: Icons.cleaning_services_outlined,
      iconColor: const Color(0xFF0D9488),
    ),
    ProductListingItem(
      id: 'prod_07',
      name: 'Dove Soap 100g',
      barcode: '8901030859152',
      sku: 'DOV-SOP-100G',
      category: 'Personal Care',
      mrp: 45.00,
      sellingPrice: 38.00,
      stock: 95,
      categoryBadgeBg: const Color(0xFFFCE7F3),
      categoryBadgeText: const Color(0xFFDB2777),
      placeholderIcon: Icons.soap_outlined,
      iconColor: const Color(0xFFDB2777),
    ),
    ProductListingItem(
      id: 'prod_08',
      name: 'Lays Classic 52g',
      barcode: '8901493000123',
      sku: 'LAY-CLS-52G',
      category: 'Snacks',
      mrp: 30.00,
      sellingPrice: 25.00,
      stock: 110,
      categoryBadgeBg: const Color(0xFFFFEDD5),
      categoryBadgeText: const Color(0xFFEA580C),
      placeholderIcon: Icons.fastfood_outlined,
      iconColor: const Color(0xFFEA580C),
    ),
  ];

  static final List<ProductListingItem> _mockRecentScans = [
    ProductListingItem(
      id: 'scan_01',
      name: 'Amul Gold Milk 1L',
      barcode: '8901262000012',
      sku: 'AML-GLD-1L',
      category: 'Dairy',
      mrp: 70.00,
      sellingPrice: 62.00,
      stock: 48,
      categoryBadgeBg: const Color(0xFFE0F2FE),
      categoryBadgeText: const Color(0xFF0284C7),
      placeholderIcon: Icons.local_drink_outlined,
      iconColor: const Color(0xFF0284C7),
      lastScannedAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    ProductListingItem(
      id: 'scan_02',
      name: 'Maggi Noodles 70g',
      barcode: '8901000100712',
      sku: 'MAG-NDL-70G',
      category: 'Snacks',
      mrp: 20.00,
      sellingPrice: 15.00,
      stock: 120,
      categoryBadgeBg: const Color(0xFFFFEDD5),
      categoryBadgeText: const Color(0xFFEA580C),
      placeholderIcon: Icons.ramen_dining_outlined,
      iconColor: const Color(0xFFEA580C),
      lastScannedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ProductListingItem(
      id: 'scan_03',
      name: 'Parle-G Biscuit 200g',
      barcode: '8901719570017',
      sku: 'PRL-G-200G',
      category: 'Biscuits',
      mrp: 35.00,
      sellingPrice: 28.00,
      stock: 85,
      categoryBadgeBg: const Color(0xFFF3E8FF),
      categoryBadgeText: const Color(0xFF9333EA),
      placeholderIcon: Icons.cookie_outlined,
      iconColor: const Color(0xFF9333EA),
      lastScannedAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
  ];

  /// Load products from backend REST API
  Future<void> loadProducts({bool refresh = false}) async {
    final api = _apiService;
    if (api == null) return;
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
      final finalItems = items.isNotEmpty ? items : _mockProducts;

      state = state.copyWith(
        allProducts: finalItems,
        metrics: metrics,
        isLoading: false,
        clearError: true,
      );

      // Synchronize with billing repository
      final ref = _ref;
      if (ref != null && items.isNotEmpty) {
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

  /// Synchronous barcode handler for camera & keyboard scanner
  ProductListingItem? handleScannedBarcode(String rawCode) {
    final validation = BarcodeValidator.validate(rawCode);
    if (!validation.isValid) {
      return null;
    }

    final cleanCode = validation.cleanBarcode!;

    // 1. EXACT match by barcode or SKU
    final existingIndex = state.allProducts.indexWhere(
      (p) =>
          p.barcode.trim() == cleanCode ||
          (p.sku.trim().isNotEmpty &&
              p.sku.trim().toLowerCase() == cleanCode.toLowerCase()),
    );

    ProductListingItem scannedItem;

    if (existingIndex != -1) {
      final existing = state.allProducts[existingIndex];
      scannedItem = existing.copyWith(lastScannedAt: DateTime.now());

      // Move to top of the list
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
    } else {
      // 2. Newly scanned unique barcode - dynamically create a distinct product for THIS barcode
      scannedItem = ProductListingItem(
        id: 'prod_scan_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Product ($cleanCode)',
        barcode: cleanCode,
        sku: 'SKU-${cleanCode.length > 6 ? cleanCode.substring(cleanCode.length - 6) : cleanCode}',
        category: 'Scanned Items',
        mrp: 60.00,
        sellingPrice: 50.00,
        stock: 50,
        categoryBadgeBg: const Color(0xFFDCFCE7),
        categoryBadgeText: const Color(0xFF16A34A),
        placeholderIcon: Icons.qr_code_2,
        iconColor: const Color(0xFF16A34A),
        lastScannedAt: DateTime.now(),
      );

      final updatedAll = [scannedItem, ...state.allProducts];
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

      // Async background server check to enrich product details if known
      final api = _apiService;
      if (api != null) {
        api.findProductByBarcode(cleanCode).then((dto) {
          updateProduct(dto.toListingItem().copyWith(lastScannedAt: DateTime.now()));
        }).catchError((_) {});
      }
    }

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

  /// Delete product from server and local memory
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

  Future<ProductListingItem> simulateScan() async {
    state = state.copyWith(isScanning: true);
    await Future.delayed(const Duration(milliseconds: 600));

    final itemToScan =
        state.allProducts[DateTime.now().second % state.allProducts.length];
    final result = handleScannedBarcode(itemToScan.barcode);
    return result ?? itemToScan;
  }
}

final productListingProvider =
    StateNotifierProvider<ProductListingNotifier, ProductListingState>((ref) {
  final apiService = ref.watch(productApiServiceProvider);
  return ProductListingNotifier(apiService, ref);
});
