import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/billing_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../data/models/pos_dto.dart';
import '../../data/services/pos_api_service.dart';

/// Provider for PosApiService
final posApiServiceProvider = Provider<PosApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PosApiService(apiClient);
});

/// FutureProvider to check active session from backend
final posActiveSessionProvider = FutureProvider<POSSession?>((ref) async {
  final api = ref.watch(posApiServiceProvider);
  return api.getActiveSession();
});

/// FutureProvider for held transactions
final posHeldCartsProvider = FutureProvider<List<Invoice>>((ref) async {
  final api = ref.watch(posApiServiceProvider);
  return api.getHeldCarts();
});

/// FutureProvider for POS terminal daily summary
final posDashboardSummaryProvider = FutureProvider<PosDashboardSummaryDto>((ref) async {
  final api = ref.watch(posApiServiceProvider);
  return api.getDashboardSummary();
});

/// State of POS Terminal screen
class PosTerminalState {
  final List<Product> products;
  final List<Customer> customers;
  final POSSession? activeSession;
  final List<InvoiceItem> cartItems;
  final Customer? selectedCustomer;
  final double cartDiscountPercent;
  final String selectedWarehouseId;
  final bool isLoading;
  final String? error;
  final PosDashboardSummaryDto? summary;
  final PosThermalReceiptDto? lastReceipt;

  const PosTerminalState({
    this.products = const [],
    this.customers = const [],
    this.activeSession,
    this.cartItems = const [],
    this.selectedCustomer,
    this.cartDiscountPercent = 0.0,
    this.selectedWarehouseId = 'main',
    this.isLoading = false,
    this.error,
    this.summary,
    this.lastReceipt,
  });

  double get subtotal =>
      cartItems.fold(0.0, (sum, item) => sum + item.taxableValue);
  double get tax =>
      cartItems.fold(0.0, (sum, item) => sum + item.cgst + item.sgst + item.igst);
  double get discountValue => (subtotal * cartDiscountPercent) / 100.0;
  double get grandTotal => (subtotal + tax) - discountValue;

  PosTerminalState copyWith({
    List<Product>? products,
    List<Customer>? customers,
    POSSession? Function()? activeSession,
    List<InvoiceItem>? cartItems,
    Customer? Function()? selectedCustomer,
    double? cartDiscountPercent,
    String? selectedWarehouseId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    PosDashboardSummaryDto? summary,
    PosThermalReceiptDto? lastReceipt,
  }) {
    return PosTerminalState(
      products: products ?? this.products,
      customers: customers ?? this.customers,
      activeSession:
          activeSession != null ? activeSession() : this.activeSession,
      cartItems: cartItems ?? this.cartItems,
      selectedCustomer:
          selectedCustomer != null ? selectedCustomer() : this.selectedCustomer,
      cartDiscountPercent: cartDiscountPercent ?? this.cartDiscountPercent,
      selectedWarehouseId: selectedWarehouseId ?? this.selectedWarehouseId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      summary: summary ?? this.summary,
      lastReceipt: lastReceipt ?? this.lastReceipt,
    );
  }
}

/// POS State Notifier for orchestrating real backend interactions
class PosNotifier extends StateNotifier<PosTerminalState> {
  final PosApiService _apiService;
  final Ref _ref;

  PosNotifier(this._apiService, this._ref) : super(const PosTerminalState()) {
    refreshCatalog();
    checkActiveSession();
  }

  /// 1. Sync catalog & customers with backend
  Future<void> refreshCatalog({String? search, String? category}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final productsFuture = _apiService.getProducts(
        search: search,
        category: category,
      );
      final customersFuture = _apiService.getCustomers();

      final results = await Future.wait([productsFuture, customersFuture]);
      final products = results[0] as List<Product>;
      final customers = results[1] as List<Customer>;

      state = state.copyWith(
        products: products,
        customers: customers,
        isLoading: false,
      );
    } catch (e) {
      // Graceful fallback to repository state if offline
      final billingState = _ref.read(billingRepositoryProvider);
      state = state.copyWith(
        products: billingState.products,
        customers: billingState.customers,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 2. Check active cashier register session
  Future<void> checkActiveSession() async {
    try {
      final session = await _apiService.getActiveSession();
      state = state.copyWith(activeSession: () => session);
    } catch (_) {}
  }

  /// 3. Open session on backend
  Future<POSSession> openSession(double openingCash, {String? notes}) async {
    state = state.copyWith(isLoading: true);
    try {
      final session = await _apiService.openSession(
        openingCash: openingCash,
        notes: notes,
      );
      state = state.copyWith(
        activeSession: () => session,
        isLoading: false,
      );
      // Also update billingRepositoryProvider so whole app knows
      await _ref.read(billingRepositoryProvider.notifier).openPOSSession(openingCash);
      return session;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 4. Close session on backend
  Future<Map<String, dynamic>> closeSession(double closingCash, {String? notes}) async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _apiService.closeSession(
        closingCash: closingCash,
        notes: notes,
      );
      state = state.copyWith(
        activeSession: () => null,
        isLoading: false,
      );
      await _ref.read(billingRepositoryProvider.notifier).closePOSSession(closingCash);
      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 5. Barcode scan add to cart
  Future<bool> scanBarcodeAndAdd(String barcode) async {
    try {
      final product = await _apiService.scanBarcode(barcode);
      if (product != null) {
        addProductToCart(product);
        return true;
      }
    } catch (_) {}

    // Fallback search in local list
    final localMatch = state.products.where((p) => p.barcode == barcode).toList();
    if (localMatch.isNotEmpty) {
      addProductToCart(localMatch.first);
      return true;
    }
    return false;
  }

  /// 6. Cart item modifications
  void addProductToCart(Product p) {
    final existingIdx = state.cartItems.indexWhere((item) => item.productId == p.id);
    if (existingIdx != -1) {
      final existingItem = state.cartItems[existingIdx];
      updateCartItemQty(existingIdx, existingItem.quantity + 1);
    } else {
      final item = InvoiceItem(
        id: 'pos_item_${DateTime.now().millisecondsSinceEpoch}',
        productId: p.id,
        serviceId: '',
        name: p.name,
        hsnSac: p.hsnCode,
        quantity: 1.0,
        unit: p.primaryUnit,
        rate: p.sellingPrice,
        discountPercentage: 0.0,
        discountAmount: 0.0,
        taxableValue: p.sellingPrice,
        gstRate: p.gstRate,
        cgst: p.sellingPrice * (p.gstRate / 200.0),
        sgst: p.sellingPrice * (p.gstRate / 200.0),
        igst: 0.0,
        cess: 0.0,
      );
      state = state.copyWith(cartItems: [...state.cartItems, item]);
    }
  }

  void updateCartItemQty(int index, double newQty) {
    if (newQty <= 0) {
      final items = List<InvoiceItem>.from(state.cartItems)..removeAt(index);
      state = state.copyWith(cartItems: items);
      return;
    }
    final item = state.cartItems[index];
    final taxable = newQty * item.rate;
    final cgst = taxable * (item.gstRate / 200.0);
    final sgst = taxable * (item.gstRate / 200.0);

    final updatedItem = InvoiceItem(
      id: item.id,
      productId: item.productId,
      serviceId: item.serviceId,
      name: item.name,
      hsnSac: item.hsnSac,
      quantity: newQty,
      unit: item.unit,
      rate: item.rate,
      discountPercentage: item.discountPercentage,
      discountAmount: item.discountAmount,
      taxableValue: taxable,
      gstRate: item.gstRate,
      cgst: cgst,
      sgst: sgst,
      igst: 0.0,
      cess: 0.0,
    );

    final items = List<InvoiceItem>.from(state.cartItems)..[index] = updatedItem;
    state = state.copyWith(cartItems: items);
  }

  void selectCustomer(Customer? c) {
    state = state.copyWith(selectedCustomer: () => c);
  }

  void setDiscount(double discount) {
    state = state.copyWith(cartDiscountPercent: discount);
  }

  void clearCart() {
    state = state.copyWith(
      cartItems: const [],
      selectedCustomer: () => null,
      cartDiscountPercent: 0.0,
    );
  }

  /// 7. Perform Fast POS Checkout with backend persistence
  Future<PosCheckoutResponse> checkout({
    required String paymentMode,
    double tenderedCash = 0.0,
    double changeDue = 0.0,
  }) async {
    if (state.cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final payload = {
      'customerId': state.selectedCustomer?.id,
      'customerName': state.selectedCustomer?.name ?? 'Walk-in Customer',
      'warehouseId': state.selectedWarehouseId,
      'cartDiscountPercent': state.cartDiscountPercent,
      'cartDiscountAmount': state.discountValue,
      'subtotal': state.subtotal,
      'tax': state.tax,
      'roundOff': 0.0,
      'grandTotal': state.grandTotal,
      'paymentMode': paymentMode,
      'tenderedCash': tenderedCash,
      'changeDue': changeDue,
      'notes': 'POS Fast Billing Sale',
      'termsConditions': 'Goods once sold are not returnable.',
      'items': state.cartItems.map((item) {
        return {
          'productId': item.productId,
          'serviceId': item.serviceId.isNotEmpty ? item.serviceId : null,
          'name': item.name,
          'hsnSac': item.hsnSac,
          'quantity': item.quantity,
          'unit': item.unit,
          'rate': item.rate,
          'discountPercentage': item.discountPercentage,
          'discountAmount': item.discountAmount,
          'taxableValue': item.taxableValue,
          'gstRate': item.gstRate,
          'cgst': item.cgst,
          'sgst': item.sgst,
          'igst': item.igst,
          'cess': item.cess,
          'warehouseId': state.selectedWarehouseId,
        };
      }).toList(),
    };

    try {
      final res = await _apiService.checkout(payload);

      // Save to local billingRepository for offline/cache sync
      await _ref.read(billingRepositoryProvider.notifier).addInvoice(res.invoice);

      state = state.copyWith(
        cartItems: const [],
        selectedCustomer: () => null,
        cartDiscountPercent: 0.0,
        isLoading: false,
        lastReceipt: res.thermalReceipt,
      );

      return res;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 8. Park / Hold Cart
  Future<Invoice> holdCurrentCart() async {
    if (state.cartItems.isEmpty) throw Exception('Cart is empty');
    if (state.selectedCustomer == null) {
      throw Exception('Please select a customer to hold cart');
    }

    final payload = {
      'customerId': state.selectedCustomer!.id,
      'customerName': state.selectedCustomer!.name,
      'billingAddress': state.selectedCustomer!.billingAddress,
      'shippingAddress': state.selectedCustomer!.shippingAddress,
      'placeOfSupply': state.selectedCustomer!.state,
      'warehouseId': state.selectedWarehouseId,
      'taxableAmount': state.subtotal,
      'cgst': state.cartItems.fold(0.0, (sum, i) => sum + i.cgst),
      'sgst': state.cartItems.fold(0.0, (sum, i) => sum + i.sgst),
      'igst': 0.0,
      'cess': 0.0,
      'roundOff': 0.0,
      'grandTotal': state.grandTotal,
      'balanceAmount': state.grandTotal,
      'paymentMode': 'Hold',
      'items': state.cartItems.map((item) {
        return {
          'productId': item.productId,
          'name': item.name,
          'hsnSac': item.hsnSac,
          'quantity': item.quantity,
          'unit': item.unit,
          'rate': item.rate,
          'taxableValue': item.taxableValue,
          'gstRate': item.gstRate,
          'cgst': item.cgst,
          'sgst': item.sgst,
          'igst': item.igst,
          'cess': item.cess,
        };
      }).toList(),
    };

    try {
      final heldInvoice = await _apiService.holdCart(payload);
      await _ref.read(billingRepositoryProvider.notifier).holdPOSCart(heldInvoice);
      clearCart();
      return heldInvoice;
    } catch (e) {
      // Fallback local hold
      final localInvoice = Invoice(
        id: 'held_cart_${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: 'HELD-${DateTime.now().millisecondsSinceEpoch}',
        invoiceDate: DateTime.now(),
        customerId: state.selectedCustomer!.id,
        customerName: state.selectedCustomer!.name,
        billingAddress: state.selectedCustomer!.billingAddress,
        shippingAddress: state.selectedCustomer!.shippingAddress,
        placeOfSupply: state.selectedCustomer!.state,
        items: state.cartItems,
        taxableAmount: state.subtotal,
        cgst: state.cartItems.fold(0.0, (sum, i) => sum + i.cgst),
        sgst: state.cartItems.fold(0.0, (sum, i) => sum + i.sgst),
        igst: 0.0,
        cess: 0.0,
        roundOff: 0.0,
        grandTotal: state.grandTotal,
        balanceAmount: state.grandTotal,
        paymentMode: 'Hold',
        status: InvoiceStatus.draft,
        notes: 'Held Cart',
        termsConditions: '',
        warehouseId: state.selectedWarehouseId,
      );
      await _ref.read(billingRepositoryProvider.notifier).holdPOSCart(localInvoice);
      clearCart();
      return localInvoice;
    }
  }

  /// 9. Resume Held Cart
  void resumeCart(Invoice cart) {
    Customer? matchedCustomer;
    final matches = state.customers.where((c) => c.id == cart.customerId).toList();
    if (matches.isNotEmpty) {
      matchedCustomer = matches.first;
    }

    state = state.copyWith(
      cartItems: cart.items,
      selectedCustomer: () => matchedCustomer,
    );
  }
}

/// Primary StateNotifierProvider for POS
final posNotifierProvider = StateNotifierProvider<PosNotifier, PosTerminalState>((ref) {
  final api = ref.watch(posApiServiceProvider);
  return PosNotifier(api, ref);
});
