import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/feedback.dart';
import '../../../customer/presentation/providers/customer_provider.dart';
import '../models/sales_ui_models.dart';
import '../widgets/sales_category_bar.dart';
import '../widgets/sales_current_bill_panel.dart';
import '../widgets/sales_dialogs.dart';
import '../widgets/sales_product_card.dart';
import '../widgets/sales_top_header.dart';

class POSPage extends ConsumerStatefulWidget {
  const POSPage({super.key});

  @override
  ConsumerState<POSPage> createState() => _POSPageState();
}

class _POSPageState extends ConsumerState<POSPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _selectedCategoryId = 'all';
  String _selectedCustomer = 'Walk-in Customer';
  String _billNumber = 'TB/25-26/000123';
  String? _transactionNote;
  double _discountPercent = 0.0;
  double _discountAmount = 0.0;

  // Default preloaded cart matching reference image exactly
  late List<SalesCartItem> _cartItems;

  // Catalog products
  late List<SalesProductItem> _products;

  // Held bills storage
  final List<Map<String, dynamic>> _heldBills = [];

  // Hardware barcode scanner buffer
  final StringBuffer _hardwareScanBuffer = StringBuffer();
  DateTime _lastHardwareKeyTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initCatalogAndCart();
    HardwareKeyboard.instance.addHandler(_handleGlobalHardwareKey);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).loadCustomers();
    });
  }

  void _initCatalogAndCart() {
    _products = List.from(kDefaultSalesProducts);

    // Initial cart preloaded exactly as shown in screenshot:
    // 1. Parle-G Biscuit 200g, Qty: 2, Rate: 28.00, Amount: 56.00
    // 2. Amul Gold Milk 1L, Qty: 1, Rate: 62.00, Amount: 62.00
    // 3. Maggi Noodles 70g, Qty: 3, Rate: 15.00, Amount: 45.00
    // 4. Coca Cola 500ml, Qty: 1, Rate: 40.00, Amount: 40.00
    _cartItems = [
      SalesCartItem(
        product: _products.firstWhere((p) => p.id == 'sp_002'),
        quantity: 2,
        rate: 28.00,
      ),
      SalesCartItem(
        product: _products.firstWhere((p) => p.id == 'sp_003'),
        quantity: 1,
        rate: 62.00,
      ),
      SalesCartItem(
        product: _products.firstWhere((p) => p.id == 'sp_004'),
        quantity: 3,
        rate: 15.00,
      ),
      SalesCartItem(
        product: _products.firstWhere((p) => p.id == 'sp_001'),
        quantity: 1,
        rate: 40.00,
      ),
    ];
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalHardwareKey);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _handleGlobalHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    // F2: Scan Product / Search focus
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      _searchFocusNode.requestFocus();
      AppFeedback.showSnackbar(context, message: 'Ready to scan barcode or search (F2)');
      return true;
    }

    // F4: Select Customer
    if (event.logicalKey == LogicalKeyboardKey.f4) {
      _showCustomerSelectionDialog();
      return true;
    }

    // F6: Hold Bill
    if (event.logicalKey == LogicalKeyboardKey.f6) {
      _holdCurrentBill();
      return true;
    }

    // F8: Generate Bill
    if (event.logicalKey == LogicalKeyboardKey.f8) {
      if (_cartItems.isNotEmpty) {
        _generateBill();
      }
      return true;
    }

    // Ctrl + P: Print Bill
    if (HardwareKeyboard.instance.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyP) {
      if (_cartItems.isNotEmpty) {
        _generateBill();
      }
      return true;
    }

    // Hardware rapid barcode scanner buffer logic
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastHardwareKeyTime).inMilliseconds;
    _lastHardwareKeyTime = now;

    final isEnter = event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;

    if (isEnter) {
      final buffer = _hardwareScanBuffer.toString().trim();
      _hardwareScanBuffer.clear();
      final code = buffer.isNotEmpty ? buffer : _searchController.text.trim();
      if (code.isNotEmpty) {
        _handleBarcodeDetected(code);
        return true;
      }
      return false;
    }

    final char = event.character;
    if (char != null && char.isNotEmpty && RegExp(r'^[A-Za-z0-9\-_./]$').hasMatch(char)) {
      if (elapsedMs > 450) {
        _hardwareScanBuffer.clear();
      }
      _hardwareScanBuffer.write(char);
    }

    return false;
  }

  void _handleBarcodeDetected(String barcode) {
    final match = _products.firstWhere(
      (p) => p.barcode == barcode || p.sku.toLowerCase() == barcode.toLowerCase(),
      orElse: () => _products.firstWhere(
        (p) => p.name.toLowerCase().contains(barcode.toLowerCase()),
        orElse: () => _products.first,
      ),
    );

    _addProductToCart(match);
    _searchController.clear();
    setState(() {});
    AppFeedback.showSnackbar(
      context,
      message: 'Scanned & added: ${match.name}',
    );
  }

  void _addProductToCart(SalesProductItem product) {
    setState(() {
      final existingIndex = _cartItems.indexWhere((it) => it.product.id == product.id);
      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity += 1;
      } else {
        _cartItems.add(
          SalesCartItem(
            product: product,
            quantity: 1,
            rate: product.price,
          ),
        );
      }
    });
  }

  void _incrementQty(int index) {
    setState(() {
      _cartItems[index].quantity += 1;
    });
  }

  void _decrementQty(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity -= 1;
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _cartItems.removeAt(index);
    });
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Clear Current Cart?'),
        content: const Text('Are you sure you want to remove all items from the current bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _cartItems.clear();
                _transactionNote = null;
                _discountPercent = 0.0;
                _discountAmount = 0.0;
              });
              AppFeedback.showSnackbar(context, message: 'Cart cleared');
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _holdCurrentBill() {
    if (_cartItems.isEmpty) {
      AppFeedback.showSnackbar(context, message: 'Cannot hold an empty bill!', isError: true);
      return;
    }

    final subtotal = _cartItems.fold(0.0, (s, it) => s + it.amount);
    final total = subtotal + (subtotal * 0.05);

    setState(() {
      _heldBills.add({
        'customer': _selectedCustomer,
        'items': List<SalesCartItem>.from(_cartItems),
        'amount': total,
        'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      _cartItems.clear();
      _transactionNote = null;
      _billNumber = 'TB/25-26/000${124 + _heldBills.length}';
    });

    AppFeedback.showSnackbar(context, message: 'Current bill held successfully! (F6)');
  }

  void _showHeldBillsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SalesHoldBillsDialog(
        heldBills: _heldBills,
        onResume: (index) {
          final bill = _heldBills.removeAt(index);
          setState(() {
            _cartItems = List<SalesCartItem>.from(bill['items'] as List<SalesCartItem>);
            _selectedCustomer = bill['customer'] as String;
          });
          AppFeedback.showSnackbar(context, message: 'Held bill resumed!');
        },
        onDelete: (index) {
          setState(() {
            _heldBills.removeAt(index);
          });
          Navigator.pop(ctx);
          AppFeedback.showSnackbar(context, message: 'Held bill deleted.');
        },
      ),
    );
  }

  void _showCustomerSelectionDialog() {
    final customerState = ref.read(customerProvider);
    final customerList = {
      'Walk-in Customer',
      ...customerState.customers.map((c) => c.name),
      'Sharma Supermarket',
      'Patel General Store',
      'Amit Kumar (Loyalty)',
      'Pooja Verma',
    }.toList();

    showDialog(
      context: context,
      builder: (ctx) => SalesCustomerDialog(
        currentCustomer: _selectedCustomer,
        customers: customerList,
        onSelect: (selected) {
          setState(() => _selectedCustomer = selected);
          AppFeedback.showSnackbar(context, message: 'Customer set: $selected');
        },
      ),
    );
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SalesAddNoteDialog(
        initialNote: _transactionNote ?? '',
        onSave: (note) {
          setState(() => _transactionNote = note);
          AppFeedback.showSnackbar(context, message: 'Note saved.');
        },
      ),
    );
  }

  void _saveAsDraft() {
    if (_cartItems.isEmpty) return;
    AppFeedback.showSnackbar(
      context,
      message: 'Bill $_billNumber saved as draft!',
    );
  }

  void _generateBill() {
    if (_cartItems.isEmpty) return;

    final subtotal = _cartItems.fold(0.0, (s, it) => s + it.amount);
    final cgst = ((subtotal * 0.025 * 100).round()) / 100.0;
    final sgst = ((subtotal * 0.025 * 100).round()) / 100.0;
    final grandTotal = subtotal + cgst + sgst;

    showDialog(
      context: context,
      builder: (ctx) => SalesBillSuccessDialog(
        billNumber: _billNumber,
        customerName: _selectedCustomer,
        items: _cartItems,
        subtotal: subtotal,
        discount: _discountAmount,
        cgst: cgst,
        sgst: sgst,
        grandTotal: grandTotal,
        onPrint: () {
          AppFeedback.showSnackbar(
            context,
            message: 'Sending to Thermal Receipt Printer Queue (80mm)...',
          );
          _completeSaleAndReset();
        },
      ),
    );
  }

  void _completeSaleAndReset() {
    setState(() {
      _cartItems.clear();
      _selectedCustomer = 'Walk-in Customer';
      _transactionNote = null;
      _discountPercent = 0.0;
      _discountAmount = 0.0;
      final nextNum = int.tryParse(_billNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 123;
      _billNumber = 'TB/25-26/000${nextNum + 1}';
    });
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF059669)),
              title: const Text('Recent Invoices & Bills'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/sales');
              },
            ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline, color: Color(0xFF3B82F6)),
              title: const Text('View Held Bills'),
              trailing: Text(
                '${_heldBills.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showHeldBillsDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF6B7280)),
              title: const Text('Return to Dashboard'),
              onTap: () {
                Navigator.pop(ctx);
                context.go('/dashboard');
              },
            ),
          ],
        ),
      ),
    );
  }

  List<SalesProductItem> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products.where((p) {
      final matchesCategory = _selectedCategoryId == 'all' ||
          p.category.toLowerCase() == _selectedCategoryId.toLowerCase();

      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.barcode.contains(query) ||
          p.sku.toLowerCase().contains(query);

      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar matching reference image (Logo, Search with F2 Scanner, Customer F4, Hold Bill, Recent Bills, More, Bell, Profile)
            SalesTopHeader(
              searchController: _searchController,
              searchFocusNode: _searchFocusNode,
              onSearchChanged: (_) => setState(() {}),
              onBarcodeScan: () {
                _searchFocusNode.requestFocus();
                AppFeedback.showSnackbar(context, message: 'Scan barcode or enter SKU/Name');
              },
              onSelectCustomer: _showCustomerSelectionDialog,
              onHoldBill: _holdCurrentBill,
              onRecentBills: () => context.push('/sales'),
              onMoreOptions: _showMoreMenu,
              onNotificationTap: () => context.push('/notifications'),
              onBackTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/sales');
                }
              },
            ),

            // Main Content Area
            Expanded(
              child: isMobile
                  ? _buildMobileContent()
                  : _buildDesktopTabletContent(isTablet: isTablet),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isMobile && _cartItems.isNotEmpty
          ? _buildMobileFloatingCartBar()
          : null,
    );
  }

  Widget _buildDesktopTabletContent({required bool isTablet}) {
    final filtered = _filteredProducts;
    final screenWidth = MediaQuery.of(context).size.width;
    final gridCrossAxisCount = screenWidth >= 1150
        ? 4
        : (screenWidth >= 850 ? 3 : 2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Category Pills + Product Catalog Grid
          Expanded(
            flex: isTablet ? 58 : 65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Category Filter Pills
                SalesCategoryBar(
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (catId) {
                    setState(() => _selectedCategoryId = catId);
                  },
                ),
                const SizedBox(height: 10),

                // Product Catalog Grid
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyProductsView()
                      : GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridCrossAxisCount,
                            childAspectRatio: 190 / 208, // Exact aspect ratio matching reference image (190px width x 208px height)
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return SalesProductCard(
                              product: product,
                              onAdd: () => _addProductToCart(product),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right: Current Bill Panel
          Expanded(
            flex: isTablet ? 42 : 35,
            child: SalesCurrentBillPanel(
              billNumber: _billNumber,
              customerName: _selectedCustomer,
              cartItems: _cartItems,
              discountPercent: _discountPercent,
              discountAmount: _discountAmount,
              note: _transactionNote,
              onIncrementQty: _incrementQty,
              onDecrementQty: _decrementQty,
              onRemoveItem: _removeItem,
              onSelectCustomer: _showCustomerSelectionDialog,
              onAddCustomer: _showCustomerSelectionDialog,
              onAddNote: _showAddNoteDialog,
              onClearCart: _clearCart,
              onSaveDraft: _saveAsDraft,
              onGenerateBill: _generateBill,
              onSettingsTap: () {
                AppFeedback.showSnackbar(
                  context,
                  message: 'POS Terminal Settings: Tax Bunny Main Branch #01',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContent() {
    final filtered = _filteredProducts;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SalesCategoryBar(
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: (catId) {
              setState(() => _selectedCategoryId = catId);
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyProductsView()
                : GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 190 / 208,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return SalesProductCard(
                        product: product,
                        onAdd: () => _addProductToCart(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFloatingCartBar() {
    final totalItems = _cartItems.fold(0, (s, it) => s + it.quantity);
    final subtotal = _cartItems.fold(0.0, (s, it) => s + it.amount);
    final cgst = ((subtotal * 0.025 * 100).round()) / 100.0;
    final sgst = ((subtotal * 0.025 * 100).round()) / 100.0;
    final grandTotal = subtotal + cgst + sgst;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalItems Items in Bill',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                Text(
                  '₹ ${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text(
                'View Current Bill',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _showMobileBillSheet,
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileBillSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SalesCurrentBillPanel(
                    billNumber: _billNumber,
                    customerName: _selectedCustomer,
                    cartItems: _cartItems,
                    discountPercent: _discountPercent,
                    discountAmount: _discountAmount,
                    note: _transactionNote,
                    onIncrementQty: (idx) {
                      _incrementQty(idx);
                      setSheetState(() {});
                      setState(() {});
                    },
                    onDecrementQty: (idx) {
                      _decrementQty(idx);
                      setSheetState(() {});
                      setState(() {});
                    },
                    onRemoveItem: (idx) {
                      _removeItem(idx);
                      setSheetState(() {});
                      setState(() {});
                    },
                    onSelectCustomer: () {
                      Navigator.pop(ctx);
                      _showCustomerSelectionDialog();
                    },
                    onAddCustomer: () {
                      Navigator.pop(ctx);
                      _showCustomerSelectionDialog();
                    },
                    onAddNote: () {
                      Navigator.pop(ctx);
                      _showAddNoteDialog();
                    },
                    onClearCart: () {
                      Navigator.pop(ctx);
                      _clearCart();
                    },
                    onSaveDraft: () {
                      Navigator.pop(ctx);
                      _saveAsDraft();
                    },
                    onGenerateBill: () {
                      Navigator.pop(ctx);
                      _generateBill();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyProductsView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 48,
            color: Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          const Text(
            'No matching products found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try searching for another keyword or change category',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedCategoryId = 'all';
              });
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}
