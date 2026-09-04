import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../data/repositories/mock_product_repository.dart';

/// Provider for the ProductRepository instance
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return MockProductRepository();
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
      message: '✓ ${product.name} added (Qty: $quantity)',
    );
  }

  factory BarcodeScanResult.notFound(String barcode) {
    return BarcodeScanResult._(
      isSuccess: false,
      notFoundBarcode: barcode,
      message: 'Product not found for barcode: $barcode',
    );
  }

  factory BarcodeScanResult.invalid(String error) {
    return BarcodeScanResult._(
      isSuccess: false,
      message: error,
    );
  }
}

/// State representation for the Active Billing POS & Scanned Cart
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
  });

  /// Total count of unique products in cart
  int get itemCount => items.length;

  /// Total units / sum of quantities of all items
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Gross subtotal before discount and tax
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.grossTotal);

  /// Total line-item discounts
  double get itemDiscounts => items.fold(0.0, (sum, item) => sum + item.discountAmount);

  /// Total discount applied
  double get totalDiscount => itemDiscounts + discountAmount;

  /// Total GST tax component
  double get gstAmount => items.fold(0.0, (sum, item) => sum + item.gstAmount);

  /// Taxable base amount excluding GST
  double get taxableAmount => items.fold(0.0, (sum, item) => sum + item.taxableAmount);

  /// Final Grand Total payable amount
  double get grandTotal {
    final net = items.fold(0.0, (sum, item) => sum + item.totalAmount) - discountAmount;
    return net < 0 ? 0.0 : net;
  }

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
    );
  }
}

/// StateNotifier handling barcode scanner HID intake, duplicate incrementing,
/// cart math, and catalogue interactions.
class BillingCartNotifier extends StateNotifier<BillingCartState> {
  final ProductRepository _repo;
  DateTime? _lastScanTime;
  String? _lastScanBarcode;

  BillingCartNotifier(this._repo)
      : super(
          BillingCartState(
            invoiceNumber: '#INV-${DateTime.now().year}-${(1000 + DateTime.now().millisecond).toString()}',
            invoiceDate: DateTime.now(),
            items: [],
            recentScans: [],
          ),
        );

  /// Unified barcode processor for USB HID, Bluetooth HID, and manual keyboard input.
  Future<BarcodeScanResult> processBarcode(String rawBarcode) async {
    // 1. Sanitize & clean raw input
    final cleanBarcode = rawBarcode.replaceAll(RegExp(r'[\r\n\t]'), '').trim();

    if (cleanBarcode.isEmpty) {
      return BarcodeScanResult.invalid('Please scan or enter a valid barcode');
    }

    // 2. Prevent rapid duplicate hardware bounces (< 200ms identical scan)
    final now = DateTime.now();
    if (_lastScanBarcode == cleanBarcode &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 250) {
      // Debounced scanner jitter
      return BarcodeScanResult.invalid('Duplicate scanner jitter ignored');
    }

    _lastScanBarcode = cleanBarcode;
    _lastScanTime = now;

    state = state.copyWith(isProcessing: true);

    try {
      // 3. Search product in repository
      final product = await _repo.findProductByBarcode(cleanBarcode);

      if (product == null) {
        state = state.copyWith(
          isProcessing: false,
          lastMessage: 'Product not found for barcode: $cleanBarcode',
          isLastMessageError: true,
        );
        return BarcodeScanResult.notFound(cleanBarcode);
      }

      // 4. Check if product already exists in cart -> Increment quantity
      final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);

      List<CartItem> updatedItems;
      int currentQty;

      if (existingIndex >= 0) {
        currentQty = state.items[existingIndex].quantity + 1;
        updatedItems = List<CartItem>.from(state.items);
        updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
          quantity: currentQty,
          addedAt: DateTime.now(),
        );
      } else {
        currentQty = 1;
        updatedItems = [
          CartItem(product: product, quantity: 1),
          ...state.items,
        ];
      }

      // 5. Update Recent Scans history list
      final updatedRecentScans = [
        product,
        ...state.recentScans.where((p) => p.id != product.id),
      ].take(10).toList();

      state = state.copyWith(
        items: updatedItems,
        recentScans: updatedRecentScans,
        lastScannedProduct: product,
        isProcessing: false,
        lastMessage: '✓ ${product.name} (Qty: $currentQty)',
        isLastMessageError: false,
      );

      return BarcodeScanResult.success(product, currentQty);
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        lastMessage: 'Error processing barcode: $e',
        isLastMessageError: true,
      );
      return BarcodeScanResult.invalid('Error processing barcode: $e');
    }
  }

  /// Increment quantity of an item in cart
  void incrementQuantity(String productId) {
    final index = state.items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      final updated = List<CartItem>.from(state.items);
      final newQty = updated[index].quantity + 1;
      updated[index] = updated[index].copyWith(quantity: newQty);
      state = state.copyWith(items: updated);
    }
  }

  /// Decrement quantity or remove if quantity reaches 0
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

  /// Set exact quantity
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

  /// Remove item from cart
  void removeItem(String productId) {
    final updated = state.items.where((i) => i.product.id != productId).toList();
    state = state.copyWith(
      items: updated,
      lastMessage: 'Item removed from bill',
      isLastMessageError: false,
    );
  }

  /// Add newly registered product from "Product Not Found" modal to catalog & cart
  Future<void> addCustomProductAndAddToCart(Product product) async {
    await _repo.addProduct(product);
    await processBarcode(product.barcode);
  }

  /// Apply overall bill discount
  void setBillDiscount(double discount) {
    state = state.copyWith(discountAmount: discount < 0 ? 0.0 : discount);
  }

  /// Update customer details
  void setCustomerDetails({String? name, String? phone}) {
    state = state.copyWith(
      customerName: name ?? state.customerName,
      customerPhone: phone ?? state.customerPhone,
    );
  }

  /// Clear entire cart / start new sale invoice
  void startNewInvoice() {
    state = BillingCartState(
      invoiceNumber: '#INV-${DateTime.now().year}-${(1000 + DateTime.now().millisecond).toString()}',
      invoiceDate: DateTime.now(),
      items: [],
      recentScans: state.recentScans,
      discountAmount: 0.0,
      customerName: 'Walk-in Customer',
      customerPhone: '',
      lastMessage: 'Started new invoice session',
      isLastMessageError: false,
    );
  }

  /// Toggle scanner hardware status flag
  void setScannerReady(bool ready) {
    state = state.copyWith(isScannerReady: ready);
  }

  /// Clear temporary status banner message
  void clearMessage() {
    state = state.copyWith(lastMessage: null);
  }
}

/// Main StateNotifierProvider for the active billing POS cart
final billingCartProvider = StateNotifierProvider<BillingCartNotifier, BillingCartState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return BillingCartNotifier(repo);
});
