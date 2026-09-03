import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/product_listing_models.dart';
import '../../domain/utils/barcode_validator.dart';

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
  });

  List<ProductListingItem> get filteredProducts {
    return allProducts.where((p) {
      final matchesCategory = selectedCategory == 'All' ||
          p.category.toLowerCase() == selectedCategory.toLowerCase() ||
          (selectedCategory == 'Groceries' && (p.category == 'Dairy' || p.category == 'Biscuits' || p.category == 'Home Care'));

      final q = searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  int get totalPages => (filteredProducts.length / itemsPerPage).ceil().clamp(1, 999);

  List<ProductListingItem> get paginatedProducts {
    final filtered = filteredProducts;
    final startIndex = (currentPage - 1) * itemsPerPage;
    if (startIndex >= filtered.length) {
      return [];
    }
    final endIndex = (startIndex + itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  int get totalProductsCount => 256; // Mock catalogue total display

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
    );
  }
}

class ProductListingNotifier extends StateNotifier<ProductListingState> {
  ProductListingNotifier()
      : super(
          ProductListingState(
            allProducts: _mockProducts,
            recentScans: _mockRecentScans,
          ),
        );

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
    // Extra items for pages 2-5
    ProductListingItem(
      id: 'prod_09',
      name: 'Tata Salt 1kg',
      barcode: '8901058852271',
      sku: 'TAT-SLT-1KG',
      category: 'Groceries',
      mrp: 28.00,
      sellingPrice: 25.00,
      stock: 200,
      categoryBadgeBg: const Color(0xFFE0F2FE),
      categoryBadgeText: const Color(0xFF0284C7),
      placeholderIcon: Icons.grain_outlined,
      iconColor: const Color(0xFF0284C7),
    ),
    ProductListingItem(
      id: 'prod_10',
      name: 'Aashirvaad Atta 5kg',
      barcode: '8901030894512',
      sku: 'ASH-ATT-5KG',
      category: 'Groceries',
      mrp: 245.00,
      sellingPrice: 215.00,
      stock: 50,
      categoryBadgeBg: const Color(0xFFE0F2FE),
      categoryBadgeText: const Color(0xFF0284C7),
      placeholderIcon: Icons.shopping_bag_outlined,
      iconColor: const Color(0xFF0284C7),
    ),
    ProductListingItem(
      id: 'prod_11',
      name: 'Red Bull Energy Drink 250ml',
      barcode: '9002490205987',
      sku: 'RDB-250ML',
      category: 'Beverages',
      mrp: 125.00,
      sellingPrice: 115.00,
      stock: 80,
      categoryBadgeBg: const Color(0xFFDCFCE7),
      categoryBadgeText: const Color(0xFF16A34A),
      placeholderIcon: Icons.bolt_outlined,
      iconColor: const Color(0xFF16A34A),
    ),
    ProductListingItem(
      id: 'prod_12',
      name: 'Colgate MaxFresh 150g',
      barcode: '8901314010342',
      sku: 'CLG-MXF-150G',
      category: 'Personal Care',
      mrp: 110.00,
      sellingPrice: 92.00,
      stock: 65,
      categoryBadgeBg: const Color(0xFFFCE7F3),
      categoryBadgeText: const Color(0xFFDB2777),
      placeholderIcon: Icons.sanitizer_outlined,
      iconColor: const Color(0xFFDB2777),
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
    ProductListingItem(
      id: 'scan_04',
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
      lastScannedAt: DateTime.now().subtract(const Duration(minutes: 12)),
    ),
  ];

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

  ProductListingItem? handleScannedBarcode(String rawCode) {
    final validation = BarcodeValidator.validate(rawCode);
    if (!validation.isValid) {
      return null;
    }

    final cleanCode = validation.cleanBarcode!;

    // 1. EXACT match by barcode or SKU only:
    final existingIndex = state.allProducts.indexWhere(
      (p) => p.barcode.trim() == cleanCode || (p.sku.trim().isNotEmpty && p.sku.trim().toLowerCase() == cleanCode.toLowerCase()),
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
        currentPage: 1, // Jump to page 1 so it's immediately visible
      );
    } else {
      // 2. Newly scanned unique barcode - dynamically create a distinct product for THIS barcode!
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
        currentPage: 1, // Jump to page 1 so it is displayed right at row 1 in the table!
      );
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

  void addScannedItem(ProductListingItem scannedItem) {
    handleScannedBarcode(scannedItem.barcode);
  }

  Future<ProductListingItem> simulateScan() async {
    state = state.copyWith(isScanning: true);
    await Future.delayed(const Duration(milliseconds: 600));

    // Cycle or pick random from list
    final itemToScan = state.allProducts[DateTime.now().second % state.allProducts.length];
    final result = handleScannedBarcode(itemToScan.barcode);
    return result ?? itemToScan;
  }
}

final productListingProvider =
    StateNotifierProvider<ProductListingNotifier, ProductListingState>((ref) {
  return ProductListingNotifier();
});
