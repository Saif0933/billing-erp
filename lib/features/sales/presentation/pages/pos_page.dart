import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../customer/presentation/providers/customer_provider.dart';
import '../models/sales_ui_models.dart';
import '../providers/pos_provider.dart';
import '../widgets/sales_category_bar.dart';
import '../widgets/sales_current_bill_panel.dart';
import '../widgets/sales_dialogs.dart';
import '../widgets/sales_product_card.dart';
import '../widgets/sales_top_header.dart';
import '../providers/sales_invoice_provider.dart';

class POSPage extends ConsumerStatefulWidget {
  final List<SalesProductItem>? initialProducts;
  final List<SalesCartItem>? initialCartItems;

  const POSPage({
    super.key,
    this.initialProducts,
    this.initialCartItems,
  });

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

  // Cart items in current bill
  late List<SalesCartItem> _cartItems;

  // Catalog products (fetched from database or empty)
  late List<SalesProductItem> _products;
  bool _isLoadingProducts = false;

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
      _syncSalesBackend();
    });
  }

  Future<void> _syncSalesBackend() async {
    // 1. Fetch next bill number
    try {
      final nextNum = await ref.read(salesInvoiceNotifierProvider.notifier).fetchNextNumber();
      if (mounted && nextNum.isNotEmpty && nextNum != _billNumber) {
        setState(() {
          _billNumber = nextNum;
        });
      }
    } catch (_) {}

    // 2. Fetch live products from database
    if (widget.initialProducts == null) {
      if (mounted) setState(() => _isLoadingProducts = true);
      try {
        final dbProducts = await ref.read(posApiServiceProvider).getProducts(limit: 100);
        if (mounted) {
          setState(() {
            _products = dbProducts.map((p) => _mapToSalesProductItem(p)).toList();
            _isLoadingProducts = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _products = [];
            _isLoadingProducts = false;
          });
        }
      }
    }

    // 3. Held invoices sync
    try {
      await ref.read(salesInvoiceNotifierProvider.notifier).refreshHeldInvoices();
      final backendHeld = ref.read(salesInvoiceNotifierProvider).heldInvoices;
      if (mounted && backendHeld.isNotEmpty) {
        for (final bh in backendHeld) {
          final alreadyExists = _heldBills.any((hb) => hb['billNumber'] == bh.invoiceNumber);
          if (!alreadyExists) {
            _heldBills.add({
              'id': bh.id,
              'billNumber': bh.invoiceNumber,
              'customer': bh.customerName,
              'items': bh.items.map((it) => SalesCartItem(
                product: SalesProductItem(
                  id: it.productId ?? it.id,
                  name: it.productName,
                  weight: it.unit,
                  category: 'others',
                  price: it.rate,
                  mrp: it.mrp,
                  stock: 100,
                  barcode: '',
                  sku: '',
                ),
                quantity: it.quantity.toInt(),
                rate: it.rate,
              )).toList(),
              'amount': bh.grandTotal,
              'time': '${bh.invoiceDate.hour.toString().padLeft(2, '0')}:${bh.invoiceDate.minute.toString().padLeft(2, '0')}',
            });
          }
        }
        setState(() {});
      }
    } catch (_) {}
  }

  void _initCatalogAndCart() {
    _products = widget.initialProducts != null
        ? List.from(widget.initialProducts!)
        : [];

    _cartItems = widget.initialCartItems != null
        ? List.from(widget.initialCartItems!)
        : [];
  }

  SalesProductItem _mapToSalesProductItem(Product p) {
    return SalesProductItem(
      id: p.id,
      name: p.name,
      weight: p.primaryUnit.isNotEmpty ? p.primaryUnit : '1 unit',
      category: p.category.isNotEmpty ? p.category.toLowerCase() : 'others',
      price: p.sellingPrice,
      mrp: p.mrp > 0 ? p.mrp : p.sellingPrice,
      stock: p.currentStock.toInt(),
      isLowStock: p.currentStock <= 5,
      barcode: p.barcode,
      sku: p.sku,
      imageUrl: p.imageUrl,
      placeholderIcon: _getIconForCategory(p.category),
      themeColor: _getColorForCategory(p.category),
    );
  }

  IconData _getIconForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('beverag') || cat.contains('drink') || cat.contains('soda')) {
      return Icons.local_drink_outlined;
    }
    if (cat.contains('snack') || cat.contains('biscuit') || cat.contains('chip')) {
      return Icons.cookie_outlined;
    }
    if (cat.contains('dairy') || cat.contains('milk') || cat.contains('cheese')) {
      return Icons.water_drop_outlined;
    }
    if (cat.contains('grocer') || cat.contains('food') || cat.contains('staple')) {
      return Icons.shopping_bag_outlined;
    }
    if (cat.contains('personal') || cat.contains('care') || cat.contains('beauty')) {
      return Icons.spa_outlined;
    }
    if (cat.contains('clean') || cat.contains('house') || cat.contains('wash')) {
      return Icons.cleaning_services_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  Color _getColorForCategory(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('beverag') || cat.contains('drink')) return const Color(0xFFDC2626);
    if (cat.contains('snack') || cat.contains('biscuit')) return const Color(0xFFD97706);
    if (cat.contains('dairy') || cat.contains('milk')) return const Color(0xFF2563EB);
    if (cat.contains('grocer')) return const Color(0xFF059669);
    if (cat.contains('personal') || cat.contains('care')) return const Color(0xFF9333EA);
    return const Color(0xFF10B981);
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

  Future<void> _handleBarcodeDetected(String barcode) async {
    final trimmed = barcode.trim();
    if (trimmed.isEmpty) return;

    // Search in current in-memory products
    SalesProductItem? match;
    for (final p in _products) {
      if (p.barcode == trimmed || p.sku.toLowerCase() == trimmed.toLowerCase()) {
        match = p;
        break;
      }
    }

    if (match == null) {
      for (final p in _products) {
        if (p.name.toLowerCase().contains(trimmed.toLowerCase())) {
          match = p;
          break;
        }
      }
    }

    // Try backend live lookup if not found locally
    if (match == null) {
      try {
        final product = await ref.read(posApiServiceProvider).scanBarcode(trimmed);
        if (product != null) {
          match = _mapToSalesProductItem(product);
          if (!_products.any((p) => p.id == match!.id)) {
            _products.add(match);
          }
        }
      } catch (_) {}
    }

    if (match != null) {
      _addProductToCart(match);
      _searchController.clear();
      setState(() {});
      AppFeedback.showSnackbar(
        context,
        message: 'Scanned & added: ${match.name}',
      );
    } else {
      AppFeedback.showSnackbar(
        context,
        message: 'No product found for "$trimmed"',
      );
    }
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

    final currentCartCopy = List<SalesCartItem>.from(_cartItems);
    final customer = _selectedCustomer;
    final note = _transactionNote;

    setState(() {
      _heldBills.add({
        'customer': customer,
        'items': currentCartCopy,
        'amount': total,
        'time': '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      _cartItems.clear();
      _transactionNote = null;
      final nextNum = int.tryParse(_billNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 123;
      _billNumber = 'TB/25-26/000${nextNum + 1}';
    });

    AppFeedback.showSnackbar(context, message: 'Current bill held successfully! (F6)');

    // Async sync to backend hold endpoint
    try {
      final itemsPayload = currentCartCopy.map((it) {
        return {
          'productId': it.product.id.startsWith('sp_') ? null : it.product.id,
          'productName': it.product.displayNameWithWeight,
          'quantity': it.quantity,
          'unit': it.product.weight.isNotEmpty ? it.product.weight : 'PCS',
          'rate': it.rate,
          'mrp': it.product.mrp,
          'taxableValue': it.amount,
          'gstRatePercent': 5.0,
          'lineTotal': it.amount * 1.05,
        };
      }).toList();

      ref.read(salesInvoiceNotifierProvider.notifier).holdBill({
        'customerName': customer,
        'notes': note,
        'discountPercent': _discountPercent,
        'discountAmount': _discountAmount,
        'items': itemsPayload,
      }).then((_) {}, onError: (e) {
        debugPrint('[POSPage] holdBill error: $e');
      });
    } catch (_) {}
  }

  void _showHeldBillsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SalesHoldBillsDialog(
        heldBills: _heldBills,
        onResume: (index) {
          final bill = _heldBills.removeAt(index);
          final billId = bill['id'] as String?;
          if (billId != null) {
            ref.read(salesInvoiceNotifierProvider.notifier).resumeHeldBill(billId).then((_) {}, onError: (_) {});
          }
          setState(() {
            _cartItems = List<SalesCartItem>.from(bill['items'] as List<SalesCartItem>);
            _selectedCustomer = bill['customer'] as String;
          });
          AppFeedback.showSnackbar(context, message: 'Held bill resumed!');
        },
        onDelete: (index) {
          final bill = _heldBills.removeAt(index);
          final billId = bill['id'] as String?;
          if (billId != null) {
            ref.read(salesInvoiceApiServiceProvider).deleteInvoice(billId).catchError((_) => true);
          }
          setState(() {});
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

  Future<void> _saveInvoiceToBackend({
    required String status,
    required double subtotal,
    required double cgst,
    required double sgst,
    required double grandTotal,
  }) async {
    try {
      final itemsPayload = _cartItems.map((it) {
        final lineTaxable = it.amount;
        final lineCgst = ((lineTaxable * 0.025 * 100).round()) / 100.0;
        final lineSgst = ((lineTaxable * 0.025 * 100).round()) / 100.0;
        return {
          'productId': it.product.id.startsWith('sp_') ? null : it.product.id,
          'productName': it.product.displayNameWithWeight,
          'quantity': it.quantity,
          'unit': it.product.weight.isNotEmpty ? it.product.weight : 'PCS',
          'rate': it.rate,
          'mrp': it.product.mrp,
          'taxableValue': lineTaxable,
          'gstRatePercent': 5.0,
          'cgstAmount': lineCgst,
          'sgstAmount': lineSgst,
          'lineTotal': lineTaxable + lineCgst + lineSgst,
        };
      }).toList();

      final payload = {
        'invoiceNumber': _billNumber,
        'customerName': _selectedCustomer,
        'subtotal': subtotal,
        'discountPercent': _discountPercent,
        'discountAmount': _discountAmount,
        'taxableValue': subtotal - _discountAmount,
        'cgstAmount': cgst,
        'sgstAmount': sgst,
        'grandTotal': grandTotal,
        'paidAmount': grandTotal,
        'paymentMode': 'CASH',
        'status': status,
        'notes': _transactionNote,
        'items': itemsPayload,
      };

      await ref.read(salesInvoiceNotifierProvider.notifier).createInvoice(payload);
    } catch (e) {
      debugPrint('[POSPage] Invoice backend sync notice: $e');
    }
  }

  void _saveAsDraft() {
    if (_cartItems.isEmpty) return;

    final subtotal = _cartItems.fold(0.0, (s, it) => s + it.amount);
    final cgst = ((subtotal * 0.025 * 100).round()) / 100.0;
    final sgst = ((subtotal * 0.025 * 100).round()) / 100.0;
    final grandTotal = subtotal + cgst + sgst;

    _saveInvoiceToBackend(
      status: 'DRAFT',
      subtotal: subtotal,
      cgst: cgst,
      sgst: sgst,
      grandTotal: grandTotal,
    );

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

    _saveInvoiceToBackend(
      status: 'PRINTED',
      subtotal: subtotal,
      cgst: cgst,
      sgst: sgst,
      grandTotal: grandTotal,
    );

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

    ref.read(salesInvoiceNotifierProvider.notifier).fetchNextNumber().then((newNum) {
      if (mounted && newNum.isNotEmpty && newNum != _billNumber) {
        setState(() {
          _billNumber = newNum;
        });
      }
    }, onError: (_) {});
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
    if (_isLoadingProducts) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF10B981)),
            SizedBox(height: 12),
            Text(
              'Loading products...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    final isFiltered = _searchController.text.trim().isNotEmpty || _selectedCategoryId != 'all';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFiltered ? Icons.search_off_outlined : Icons.inventory_2_outlined,
            size: 52,
            color: const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            isFiltered ? 'No matching products found' : 'No products in catalog',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isFiltered
                ? 'Try searching for another keyword or change category'
                : 'Products added to the database will appear here',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          if (isFiltered) ...[
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
        ],
      ),
    );
  }
}
