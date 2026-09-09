import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/product_dto.dart';
import '../../data/repositories/api_product_repository.dart';
import '../../data/services/product_api_service.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import 'product_listing_provider.dart';

/// Provider for ProductApiService
final productApiServiceProvider = Provider<ProductApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductApiService(apiClient);
});

/// Provider for the ProductRepository instance
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final apiService = ref.watch(productApiServiceProvider);
  return ApiProductRepository(apiService);
});

/// Result type of a barcode processing action
class BarcodeScanResult {
  final bool isSuccess;
  final Product? product;
  final int? quantity;
  final String? notFoundBarcode;
  final String message;

  const BarcodeScanResult._({
    required this.isSuccess,
    this.product,
    this.quantity,
    this.notFoundBarcode,
    required this.message,
  });

  factory BarcodeScanResult.success(Product product, int quantity) {
    return BarcodeScanResult._(
      isSuccess: true,
      product: product,
      quantity: quantity,
      message: '✓ ${product.name} added to listing',
    );
  }

  factory BarcodeScanResult.notFound(String barcode) {
    return BarcodeScanResult._(
      isSuccess: false,
      notFoundBarcode: barcode,
      message: 'Product not listed for barcode: $barcode',
    );
  }

  factory BarcodeScanResult.invalid(String error) {
    return BarcodeScanResult._(
      isSuccess: false,
      message: error,
    );
  }
}

/// State for the Product Listing draft (scan → edit price/GST → save to DB).
/// This is NOT a sale cart — products are listed here so they can be sold later.
class BillingCartState {
  final String invoiceNumber;
  final DateTime invoiceDate;
  final List<CartItem> items;
  final List<Product> recentScans;
  final double discountAmount;
  final String customerName;
  final String customerPhone;
  final bool isScannerReady;
  final String? lastMessage;
  final bool isLastMessageError;
  final Product? lastScannedProduct;
  final bool isProcessing;
  final bool isSaving;
  /// Product IDs already persisted to the database in this session
  final Set<String> savedProductIds;

  const BillingCartState({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.items,
    required this.recentScans,
    this.discountAmount = 0.0,
    this.customerName = 'Walk-in Customer',
    this.customerPhone = '',
    this.isScannerReady = true,
    this.lastMessage,
    this.isLastMessageError = false,
    this.lastScannedProduct,
    this.isProcessing = false,
    this.isSaving = false,
    this.savedProductIds = const {},
  });

  int get itemCount => items.length;

  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.grossTotal);

  double get itemDiscounts => items.fold(0.0, (sum, item) => sum + item.discountAmount);

  double get totalDiscount => itemDiscounts + discountAmount;

  double get gstAmount => items.fold(0.0, (sum, item) => sum + item.gstAmount);

  double get taxableAmount => items.fold(0.0, (sum, item) => sum + item.taxableAmount);

  double get grandTotal {
    final net = items.fold(0.0, (sum, item) => sum + item.totalAmount) - discountAmount;
    return net < 0 ? 0.0 : net;
  }

  int get unsavedCount =>
      items.where((i) => !savedProductIds.contains(i.product.id)).length;

  BillingCartState copyWith({
    String? invoiceNumber,
    DateTime? invoiceDate,
    List<CartItem>? items,
    List<Product>? recentScans,
    double? discountAmount,
    String? customerName,
    String? customerPhone,
    bool? isScannerReady,
    String? lastMessage,
    bool? isLastMessageError,
    Product? lastScannedProduct,
    bool? isProcessing,
    bool? isSaving,
    Set<String>? savedProductIds,
  }) {
    return BillingCartState(
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      items: items ?? this.items,
      recentScans: recentScans ?? this.recentScans,
      discountAmount: discountAmount ?? this.discountAmount,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      isScannerReady: isScannerReady ?? this.isScannerReady,
      lastMessage: lastMessage ?? this.lastMessage,
      isLastMessageError: isLastMessageError ?? this.isLastMessageError,
      lastScannedProduct: lastScannedProduct ?? this.lastScannedProduct,
      isProcessing: isProcessing ?? this.isProcessing,
      isSaving: isSaving ?? this.isSaving,
      savedProductIds: savedProductIds ?? this.savedProductIds,
    );
  }
}

/// Handles barcode scan → product listing draft (not sale).
class BillingCartNotifier extends StateNotifier<BillingCartState> {
  final ProductRepository _repo;
  final Ref? _ref;
  DateTime? _lastScanTime;
  String? _lastScanBarcode;

  BillingCartNotifier(this._repo, [this._ref])
      : super(
          BillingCartState(
            invoiceNumber: '#LIST-${DateTime.now().year}-${(1000 + DateTime.now().millisecond).toString()}',
            invoiceDate: DateTime.now(),
            items: [],
            recentScans: [],
          ),
        );

  /// Resolve barcode against DB / catalogues. Does NOT auto-create with fake prices.
  Future<BarcodeScanResult> processBarcode(String rawBarcode) async {
    final cleanBarcode = rawBarcode.replaceAll(RegExp(r'[\r\n\t]'), '').trim();

    if (cleanBarcode.isEmpty) {
      return BarcodeScanResult.invalid('Please scan or enter a valid barcode');
    }

    final now = DateTime.now();
    if (_lastScanBarcode == cleanBarcode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 250) {
      return BarcodeScanResult.invalid('Duplicate scanner jitter ignored');
    }

    _lastScanBarcode = cleanBarcode;
    _lastScanTime = now;

    state = state.copyWith(isProcessing: true);

    try {
      Product? product;
      try {
        product = await _repo.findProductByBarcode(cleanBarcode);
      } catch (_) {}

      if (product == null && _ref != null) {
        final cleanUpper = cleanBarcode.toUpperCase();
        try {
          final billingProducts = _ref.read(billingRepositoryProvider).products;
          for (final bp in billingProducts) {
            if (bp.barcode.trim().toUpperCase() == cleanUpper ||
                bp.sku.trim().toUpperCase() == cleanUpper ||
                bp.code.trim().toUpperCase() == cleanUpper ||
                bp.id.trim().toUpperCase() == cleanUpper) {
              product = Product(
                id: bp.id,
                name: bp.name,
                barcode: bp.barcode.isNotEmpty ? bp.barcode : cleanBarcode,
                sku: bp.sku.isNotEmpty ? bp.sku : bp.code,
                category: bp.category.isNotEmpty ? bp.category : 'General',
                sellingPrice: bp.sellingPrice,
                purchasePrice: bp.purchasePrice,
                mrp: bp.mrp > 0 ? bp.mrp : bp.sellingPrice,
                gstRate: bp.gstRate,
                stock: bp.currentStock.toInt(),
                unit: bp.primaryUnit.isNotEmpty ? bp.primaryUnit : 'pcs',
              );
              break;
            }
          }
        } catch (_) {}
      }

      if (product == null && _ref != null) {
        final cleanUpper = cleanBarcode.toUpperCase();
        try {
          final listingProducts = _ref.read(productListingProvider).allProducts;
          for (final lp in listingProducts) {
            if (lp.barcode.trim().toUpperCase() == cleanUpper ||
                lp.sku.trim().toUpperCase() == cleanUpper ||
                lp.id.trim().toUpperCase() == cleanUpper) {
              product = Product(
                id: lp.id,
                name: lp.name,
                barcode: lp.barcode,
                sku: lp.sku,
                category: lp.category,
                sellingPrice: lp.sellingPrice,
                purchasePrice: lp.sellingPrice * 0.8,
                mrp: lp.mrp,
                gstRate: lp.gstRate,
                stock: lp.stock,
                unit: lp.unit,
              );
              break;
            }
          }
        } catch (_) {}
      }

      // New EAN — require manual name, unit price & GST via dialog (no fake prices)
      if (product == null) {
        state = state.copyWith(
          isProcessing: false,
          lastMessage: 'New barcode scanned. Enter unit price & GST to list this product.',
          isLastMessageError: false,
        );
        return BarcodeScanResult.notFound(cleanBarcode);
      }

      return _addProductToListing(product);
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        lastMessage: 'Error processing barcode: $e',
        isLastMessageError: true,
      );
      return BarcodeScanResult.invalid('Error processing barcode: $e');
    }
  }

  BarcodeScanResult _addProductToListing(Product product, {bool markSaved = true}) {
    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id || item.product.barcode == product.barcode,
    );

    List<CartItem> updatedItems;
    if (existingIndex >= 0) {
      updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        product: product,
        addedAt: DateTime.now(),
      );
    } else {
      updatedItems = [
        CartItem(product: product, quantity: 1),
        ...state.items,
      ];
    }

    final updatedRecentScans = [
      product,
      ...state.recentScans.where((p) => p.id != product.id && p.barcode != product.barcode),
    ].take(10).toList();

    final savedIds = Set<String>.from(state.savedProductIds);
    if (markSaved && !product.id.startsWith('prod_scan_') && !product.id.startsWith('prod_custom_')) {
      savedIds.add(product.id);
    } else {
      savedIds.remove(product.id);
    }

    state = state.copyWith(
      items: updatedItems,
      recentScans: updatedRecentScans,
      lastScannedProduct: product,
      isProcessing: false,
      lastMessage: '✓ ${product.name} (${product.barcode})',
      isLastMessageError: false,
      savedProductIds: savedIds,
    );

    return BarcodeScanResult.success(product, 1);
  }

  /// Manually update unit price for a listed product
  void updateUnitPrice(String productId, double price) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;
    final updated = List<CartItem>.from(state.items);
    final item = updated[index];
    updated[index] = item.copyWith(
      product: item.product.copyWith(sellingPrice: price < 0 ? 0 : price),
    );
    final savedIds = Set<String>.from(state.savedProductIds)..remove(productId);
    state = state.copyWith(items: updated, savedProductIds: savedIds);
  }

  /// Manually update GST rate for a listed product
  void updateGstRate(String productId, double gstRate) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;
    final updated = List<CartItem>.from(state.items);
    final item = updated[index];
    updated[index] = item.copyWith(
      product: item.product.copyWith(gstRate: gstRate < 0 ? 0 : gstRate),
    );
    final savedIds = Set<String>.from(state.savedProductIds)..remove(productId);
    state = state.copyWith(items: updated, savedProductIds: savedIds);
  }

  /// Manually update product name
  void updateProductName(String productId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;
    final updated = List<CartItem>.from(state.items);
    final item = updated[index];
    updated[index] = item.copyWith(product: item.product.copyWith(name: trimmed));
    final savedIds = Set<String>.from(state.savedProductIds)..remove(productId);
    state = state.copyWith(items: updated, savedProductIds: savedIds);
  }

  void incrementQuantity(String productId) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[index] = updated[index].copyWith(quantity: updated[index].quantity + 1);
      state = state.copyWith(items: updated);
    }
  }

  void decrementQuantity(String productId) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      final currentQty = state.items[index].quantity;
      if (currentQty > 1) {
        final updated = List<CartItem>.from(state.items);
        updated[index] = updated[index].copyWith(quantity: currentQty - 1);
        state = state.copyWith(items: updated);
      } else {
        removeItem(productId);
      }
    }
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[index] = updated[index].copyWith(quantity: quantity);
      state = state.copyWith(items: updated);
    }
  }

  void removeItem(String productId) {
    final updated = state.items.where((i) => i.product.id != productId).toList();
    final savedIds = Set<String>.from(state.savedProductIds)..remove(productId);
    state = state.copyWith(
      items: updated,
      savedProductIds: savedIds,
      lastMessage: 'Product removed from listing',
      isLastMessageError: false,
    );
  }

  /// Add newly registered product from dialog into listing draft (local).
  /// Call [saveAllToDatabase] to persist EAN + full details to DB.
  Future<void> addCustomProductAndAddToCart(Product product) async {
    _addProductToListing(product, markSaved: false);
  }

  /// Persist all listed products (EAN + name + unit price + GST + full info) to database.
  Future<bool> saveAllToDatabase() async {
    if (state.items.isEmpty) {
      state = state.copyWith(
        lastMessage: 'Scan at least one product to save.',
        isLastMessageError: true,
      );
      return false;
    }

    // Validate unit price entered for every product
    for (final item in state.items) {
      if (item.product.sellingPrice <= 0) {
        state = state.copyWith(
          lastMessage: 'Enter unit price for "${item.product.name}" before saving.',
          isLastMessageError: true,
        );
        return false;
      }
      if (item.product.name.trim().isEmpty ||
          item.product.name.startsWith('Item #') ||
          item.product.name.startsWith('Product (')) {
        state = state.copyWith(
          lastMessage: 'Enter a proper name for barcode ${item.product.barcode}.',
          isLastMessageError: true,
        );
        return false;
      }
    }

    state = state.copyWith(isSaving: true, lastMessage: null);

    final api = _ref?.read(productApiServiceProvider);
    if (api == null) {
      state = state.copyWith(
        isSaving: false,
        lastMessage: 'API service unavailable. Cannot save products.',
        isLastMessageError: true,
      );
      return false;
    }

    final savedIds = Set<String>.from(state.savedProductIds);
    final updatedItems = List<CartItem>.from(state.items);
    int successCount = 0;
    final errors = <String>[];

    for (var i = 0; i < updatedItems.length; i++) {
      final item = updatedItems[i];
      final p = item.product;
      final dto = ProductDto(
        id: p.id,
        name: p.name.trim(),
        barcode: p.barcode.trim(),
        sku: p.sku.trim().isNotEmpty
            ? p.sku.trim()
            : 'SKU-${p.barcode.length > 6 ? p.barcode.substring(p.barcode.length - 6) : p.barcode}',
        code: p.sku,
        itemCode: p.sku,
        category: p.category.isNotEmpty ? p.category : 'General',
        sellingPrice: p.sellingPrice,
        purchasePrice: p.purchasePrice > 0 ? p.purchasePrice : p.sellingPrice,
        mrp: p.mrp > 0 ? p.mrp : p.sellingPrice,
        gstRate: p.gstRate,
        gstRatePercent: p.gstRate,
        openingStock: p.stock.toDouble(),
        currentStock: p.stock.toDouble(),
        stock: p.stock,
        unit: p.unit,
        primaryUnit: p.unit.toUpperCase(),
        isActive: true,
      );

      try {
        final isTempId =
            p.id.startsWith('prod_scan_') || p.id.startsWith('prod_custom_') || p.id.isEmpty;
        ProductDto saved;
        if (isTempId || !savedIds.contains(p.id)) {
          // Try create; if barcode already exists, update that record
          try {
            saved = await api.createProduct(dto);
          } catch (_) {
            try {
              final existing = await api.findProductByBarcode(p.barcode);
              saved = await api.updateProduct(ProductDto(
                id: existing.id,
                name: dto.name,
                barcode: dto.barcode,
                sku: dto.sku,
                code: dto.code,
                itemCode: dto.itemCode,
                category: dto.category,
                sellingPrice: dto.sellingPrice,
                purchasePrice: dto.purchasePrice,
                mrp: dto.mrp,
                gstRate: dto.gstRate,
                gstRatePercent: dto.gstRate,
                openingStock: dto.openingStock,
                currentStock: dto.currentStock,
                stock: dto.stock,
                unit: dto.unit,
                primaryUnit: dto.primaryUnit,
                isActive: true,
              ));
            } catch (e2) {
              errors.add('${p.barcode}: $e2');
              continue;
            }
          }
        } else {
          saved = await api.updateProduct(dto);
        }

        final domainSaved = saved.toDomainProduct();
        updatedItems[i] = item.copyWith(product: domainSaved);
        savedIds.add(domainSaved.id);
        successCount++;
      } catch (e) {
        errors.add('${p.barcode}: $e');
      }
    }

    state = state.copyWith(
      items: updatedItems,
      savedProductIds: savedIds,
      isSaving: false,
      lastMessage: errors.isEmpty
          ? '✓ Saved $successCount product(s) to database with EAN, price & GST.'
          : 'Saved $successCount. Failed: ${errors.take(2).join('; ')}',
      isLastMessageError: errors.isNotEmpty && successCount == 0,
    );

    // Refresh catalogue directory
    try {
      await _ref?.read(productListingProvider.notifier).loadProducts(refresh: true);
    } catch (_) {}

    return successCount > 0;
  }

  void setBillDiscount(double discount) {
    state = state.copyWith(discountAmount: discount < 0 ? 0.0 : discount);
  }

  void setCustomerDetails({String? name, String? phone}) {
    state = state.copyWith(
      customerName: name ?? state.customerName,
      customerPhone: phone ?? state.customerPhone,
    );
  }

  void startNewInvoice() {
    state = BillingCartState(
      invoiceNumber: '#LIST-${DateTime.now().year}-${(1000 + DateTime.now().millisecond).toString()}',
      invoiceDate: DateTime.now(),
      items: [],
      recentScans: state.recentScans,
      discountAmount: 0.0,
      lastMessage: 'Cleared listing. Scan products to list again.',
      isLastMessageError: false,
    );
  }

  void setScannerReady(bool ready) {
    state = state.copyWith(isScannerReady: ready);
  }

  void clearMessage() {
    state = state.copyWith(lastMessage: null);
  }
}

final billingCartProvider = StateNotifierProvider<BillingCartNotifier, BillingCartState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return BillingCartNotifier(repo, ref);
});
