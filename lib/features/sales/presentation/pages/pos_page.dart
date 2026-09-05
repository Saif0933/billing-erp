import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../subscription/domain/services/feature_access_service.dart';

class POSPage extends ConsumerStatefulWidget {
  const POSPage({super.key});

  @override
  ConsumerState<POSPage> createState() => _POSPageState();
}

class _POSPageState extends ConsumerState<POSPage> {
  final _searchController = TextEditingController();
  final _openingCashController = TextEditingController(text: '1000.00');
  final _closingCashController = TextEditingController(text: '0.00');
  final _discountController = TextEditingController(text: '0.0');

  Customer? _selectedCustomer;
  String _selectedWarehouseId = 'main';
  List<InvoiceItem> _cartItems = [];
  double _cartDiscountPercent = 0.0;
  bool _showCartOnMobile = false;

  @override
  void dispose() {
    _searchController.dispose();
    _openingCashController.dispose();
    _closingCashController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _showOpenSessionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Open POS Register'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the opening cash balance in the register to start the POS billing session.',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Opening Cash (₹) *',
                controller: _openingCashController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go('/dashboard');
              },
              child: const Text('Back to Dashboard'),
            ),
            AppButton(
              label: 'Open Session',
              onPressed: () async {
                final double amt =
                    double.tryParse(_openingCashController.text) ?? 0.0;
                await ref
                    .read(billingRepositoryProvider.notifier)
                    .openPOSSession(amt);
                if (mounted) {
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(
                    context,
                    message: 'POS Register session opened successfully!',
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showCloseSessionDialog(POSSession session, double totalSales) {
    _closingCashController.text = (session.openingCash + totalSales)
        .toStringAsFixed(2);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Close POS Register Session'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Opening Cash: ₹${session.openingCash.toStringAsFixed(2)}'),
              Text('Total POS Sales: ₹${totalSales.toStringAsFixed(2)}'),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Actual Closing Cash (₹) *',
                controller: _closingCashController,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Close Session',
              onPressed: () async {
                final double amt =
                    double.tryParse(_closingCashController.text) ?? 0.0;
                await ref
                    .read(billingRepositoryProvider.notifier)
                    .closePOSSession(amt);
                if (mounted) {
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(
                    context,
                    message: 'POS session closed. Register consolidated!',
                  );
                  context.go('/dashboard');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addProductToCart(Product p) {
    final existingIdx = _cartItems.indexWhere((item) => item.productId == p.id);
    if (existingIdx != -1) {
      final existingItem = _cartItems[existingIdx];
      _updateCartItemQty(existingIdx, existingItem.quantity + 1);
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
      setState(() {
        _cartItems = [..._cartItems, item];
      });
    }
  }

  void _updateCartItemQty(int index, double newQty) {
    if (newQty <= 0) {
      setState(() {
        _cartItems = List.from(_cartItems)..removeAt(index);
      });
      return;
    }
    final item = _cartItems[index];
    final taxable = newQty * item.rate;
    final cgst = taxable * (item.gstRate / 200.0);
    final sgst = taxable * (item.gstRate / 200.0);

    setState(() {
      _cartItems = List.from(_cartItems)
        ..[index] = InvoiceItem(
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
    });
  }

  double get _subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.taxableValue);
  double get _tax =>
      _cartItems.fold(0.0, (sum, item) => sum + item.cgst + item.sgst);
  double get _discountValue => (_subtotal * _cartDiscountPercent) / 100.0;
  double get _grandTotal => (_subtotal + _tax) - _discountValue;

  void _processPayment(String mode) async {
    if (_cartItems.isEmpty) {
      AppFeedback.showSnackbar(
        context,
        message: 'Cart is empty!',
        isError: true,
      );
      return;
    }
    if (_selectedCustomer == null) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please select a customer first!',
        isError: true,
      );
      return;
    }

    final now = DateTime.now();
    final invoice = Invoice(
      id: 'inv_pos_${now.millisecondsSinceEpoch}',
      invoiceNumber:
          'INV-POS-${now.year}-${now.month}-${now.day}-${DateTime.now().second}',
      invoiceDate: now,
      customerId: _selectedCustomer!.id,
      customerName: _selectedCustomer!.name,
      billingAddress: _selectedCustomer!.billingAddress,
      shippingAddress: _selectedCustomer!.shippingAddress,
      placeOfSupply: _selectedCustomer!.state,
      items: _cartItems,
      taxableAmount: _subtotal,
      cgst: _cartItems.fold(0.0, (sum, item) => sum + item.cgst),
      sgst: _cartItems.fold(0.0, (sum, item) => sum + item.sgst),
      igst: 0.0,
      cess: 0.0,
      roundOff: 0.0,
      grandTotal: _grandTotal,
      balanceAmount: mode == 'Credit' ? _grandTotal : 0.0,
      paymentMode: mode,
      status: InvoiceStatus.confirmed,
      notes: 'POS Fast Billing Sale',
      termsConditions: 'Goods once sold are not returnable.',
      warehouseId: _selectedWarehouseId,
    );

    // Save actual invoice to repository
    await ref.read(billingRepositoryProvider.notifier).addInvoice(invoice);

    if (mounted) {
      setState(() {
        _cartItems = [];
        _selectedCustomer = null;
        _cartDiscountPercent = 0.0;
      });
      _showReceiptDialog(invoice);
    }
  }

  void _showReceiptDialog(Invoice invoice) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle_outline, color: AppColors.success),
              SizedBox(width: 8),
              Text('Sale Completed!'),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Receipt Layout (80mm Thermal Printer preview):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Divider(),
                Text(
                  'TAX BUNNY BILLING RECEIPT',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Invoice: ${invoice.invoiceNumber}',
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Date: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                  textAlign: TextAlign.center,
                ),
                const Divider(),
                ...invoice.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.name} x${item.quantity.toInt()}'),
                        Text('₹${item.taxableValue.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:'),
                    Text('₹${invoice.taxableAmount.toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tax (GST):'),
                    Text(
                      '₹${(invoice.cgst + invoice.sgst).toStringAsFixed(2)}',
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${invoice.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  'Mode: ${invoice.paymentMode}',
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Thank you for shopping!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            AppButton(
              label: 'Print Thermal Receipt',
              icon: Icons.print,
              onPressed: () {
                Navigator.pop(ctx);
                AppFeedback.showSnackbar(
                  context,
                  message: 'Sent to thermal printer queue!',
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showHoldResumeCartsDialog(List<Invoice> heldCarts) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Held POS Transactions'),
          content: heldCarts.isEmpty
              ? const SizedBox(
                  height: 100,
                  child: Center(child: Text('No held carts available.')),
                )
              : SizedBox(
                  width: 400,
                  height: 300,
                  child: ListView.separated(
                    itemCount: heldCarts.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, idx) {
                      final cart = heldCarts[idx];
                      return ListTile(
                        title: Text(
                          '${cart.customerName} - Total: ₹${cart.grandTotal.toStringAsFixed(2)}',
                        ),
                        subtitle: Text(
                          'Items: ${cart.items.length} | Date: ${cart.invoiceDate.toLocal().toString().substring(11, 16)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                await ref
                                    .read(billingRepositoryProvider.notifier)
                                    .deleteHeldPOSCart(cart.id);
                                Navigator.pop(ctx);
                                AppFeedback.showSnackbar(
                                  context,
                                  message: 'Held cart removed.',
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.play_arrow_outlined,
                                color: Colors.green,
                              ),
                              onPressed: () async {
                                setState(() {
                                  _cartItems = cart.items;
                                  _selectedCustomer = ref
                                      .read(billingRepositoryProvider)
                                      .customers
                                      .firstWhere(
                                        (c) => c.id == cart.customerId,
                                      );
                                  _selectedWarehouseId = cart.warehouseId;
                                });
                                await ref
                                    .read(billingRepositoryProvider.notifier)
                                    .resumePOSCart(cart.id);
                                Navigator.pop(ctx);
                                AppFeedback.showSnackbar(
                                  context,
                                  message: 'POS Cart Resumed!',
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final featureAccess = ref.watch(featureAccessServiceProvider);

    // Gating check
    if (!featureAccess.canAccessPOS()) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 48, color: AppColors.warning),
                  const SizedBox(height: AppSpacing.md),
                  Text('POS Gated Feature', style: AppTypography.titleLarge),
                  const Text(
                    'Upgrade to Premium or Enterprise plan to access POS fast retail billing.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Upgrade Subscription Now',
                    onPressed: () => context.go('/subscription'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final activeSession = billingState.activePOSSession;

    // Trigger session open dialog if no active session
    if (activeSession == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _showOpenSessionDialog(),
      );
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isMobile = Responsive.isMobile(context);
    final searchQuery = _searchController.text.toLowerCase();
    final matchingProducts = billingState.products.where((p) {
      return p.name.toLowerCase().contains(searchQuery) ||
          p.code.toLowerCase().contains(searchQuery) ||
          p.barcode.contains(searchQuery);
    }).toList();

    final Widget productsPanel = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : Colors.grey.shade50,
      child: Column(
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Search Product / SKU / Barcode',
                  controller: _searchController,
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppDropdownField<String>(
                  label: 'Billing Warehouse',
                  value: _selectedWarehouseId,
                  items: billingState.warehouses.map((wh) {
                    return DropdownMenuItem(value: wh.id, child: Text(wh.name));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWarehouseId = val);
                  },
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Search Product / SKU / Barcode',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 200,
                  child: AppDropdownField<String>(
                    label: 'Billing Warehouse',
                    value: _selectedWarehouseId,
                    items: billingState.warehouses.map((wh) {
                      return DropdownMenuItem(
                        value: wh.id,
                        child: Text(wh.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null)
                        setState(() => _selectedWarehouseId = val);
                    },
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: matchingProducts.isEmpty
                ? const Center(child: Text('No products matched your search.'))
                : GridView.builder(
                    itemCount: matchingProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 2 : 3,
                      childAspectRatio: isMobile ? 1.4 : 1.3,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                    ),
                    itemBuilder: (context, index) {
                      final prod = matchingProducts[index];
                      final whStock =
                          prod.warehouseStocks[_selectedWarehouseId] ?? 0.0;
                      final isOutOfStock = whStock <= 0;

                      return Card(
                        color: isOutOfStock
                            ? Colors.grey.shade300
                            : AppColors.accent.withOpacity(0.08),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: AppColors.accent.withOpacity(0.2),
                          ),
                        ),
                        child: InkWell(
                          onTap: isOutOfStock
                              ? null
                              : () => _addProductToCart(prod),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  prod.name,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${prod.sellingPrice}',
                                      style: const TextStyle(
                                        color: AppColors.accentDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      isOutOfStock
                                          ? 'OUT OF STOCK'
                                          : 'Stock: ${whStock.toInt()}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isOutOfStock
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    final Widget cartPanel = Container(
      decoration: BoxDecoration(
        border: isMobile
            ? null
            : Border(left: BorderSide(color: Colors.grey.shade300, width: 1)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile) ...[
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _showCartOnMobile = false),
                ),
                Text(
                  'Current Transaction',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else ...[
            Text(
              'Current Transaction',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          // Customer Selector
          AppDropdownField<Customer>(
            label: 'Select Customer *',
            value: _selectedCustomer,
            items: billingState.customers.map((c) {
              return DropdownMenuItem(value: c, child: Text(c.name));
            }).toList(),
            onChanged: (c) => setState(() => _selectedCustomer = c),
          ),
          const SizedBox(height: AppSpacing.md),
          // Cart Item list
          Expanded(
            child: _cartItems.isEmpty
                ? const Center(child: Text('Cart is empty. Add products.'))
                : ListView.separated(
                    itemCount: _cartItems.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final item = _cartItems[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '₹${item.rate} x ${item.quantity.toInt()}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () =>
                                  _updateCartItemQty(idx, item.quantity - 1),
                            ),
                            Text(
                              '${item.quantity.toInt()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  _updateCartItemQty(idx, item.quantity + 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          // Subtotal & Discounts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:'),
              Text('₹${_subtotal.toStringAsFixed(2)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tax (GST):'),
              Text('₹${_tax.toStringAsFixed(2)}'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cart Discount (%):'),
              SizedBox(
                width: 80,
                height: 35,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _cartDiscountPercent = double.tryParse(val) ?? 0.0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GRAND TOTAL:',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${_grandTotal.toStringAsFixed(2)}',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Actions: Hold Cart & Payment triggers
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cartItems.isEmpty
                      ? null
                      : () async {
                          if (_selectedCustomer == null) {
                            AppFeedback.showSnackbar(
                              context,
                              message: 'Select customer first!',
                              isError: true,
                            );
                            return;
                          }
                          final holdInvoice = Invoice(
                            id: 'hold_${DateTime.now().millisecondsSinceEpoch}',
                            invoiceNumber: 'INV-HOLD-${DateTime.now().second}',
                            invoiceDate: DateTime.now(),
                            customerId: _selectedCustomer!.id,
                            customerName: _selectedCustomer!.name,
                            billingAddress: _selectedCustomer!.billingAddress,
                            shippingAddress: _selectedCustomer!.shippingAddress,
                            placeOfSupply: _selectedCustomer!.state,
                            items: _cartItems,
                            taxableAmount: _subtotal,
                            cgst: _cartItems.fold(
                              0.0,
                              (sum, item) => sum + item.cgst,
                            ),
                            sgst: _cartItems.fold(
                              0.0,
                              (sum, item) => sum + item.sgst,
                            ),
                            igst: 0.0,
                            cess: 0.0,
                            roundOff: 0.0,
                            grandTotal: _grandTotal,
                            balanceAmount: _grandTotal,
                            paymentMode: 'Hold',
                            status: InvoiceStatus.draft,
                            notes: 'POS Held Cart',
                            termsConditions: '',
                            warehouseId: _selectedWarehouseId,
                          );
                          await ref
                              .read(billingRepositoryProvider.notifier)
                              .holdPOSCart(holdInvoice);
                          setState(() {
                            _cartItems = [];
                            _selectedCustomer = null;
                          });
                          if (mounted) {
                            AppFeedback.showSnackbar(
                              context,
                              message: 'POS sale held successfully!',
                            );
                          }
                        },
                  child: const Text('Hold Bill'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: 'Checkout',
                  onPressed: () {
                    if (_cartItems.isEmpty || _selectedCustomer == null) {
                      AppFeedback.showSnackbar(
                        context,
                        message: 'Please select customer and add items!',
                        isError: true,
                      );
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ListTile(
                                title: Text(
                                  'Select Payment Mode',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.money,
                                  color: Colors.green,
                                ),
                                title: const Text('Cash Payment'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _processPayment('Cash');
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.qr_code,
                                  color: Colors.blue,
                                ),
                                title: const Text('UPI / QR Scan'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _processPayment('UPI');
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.credit_card,
                                  color: Colors.purple,
                                ),
                                title: const Text('Card Swipe'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _processPayment('Card');
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.person_outline,
                                  color: Colors.orange,
                                ),
                                title: const Text(
                                  'Credit Sale (Ledger Outstanding)',
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _processPayment('Credit');
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMobile && _showCartOnMobile
              ? 'POS Cart (${_cartItems.length})'
              : 'Retail POS Terminal',
        ),
        actions: [
          if (isMobile) ...[
            if (_showCartOnMobile)
              IconButton(
                icon: const Icon(Icons.grid_view),
                tooltip: 'Show Products',
                onPressed: () => setState(() => _showCartOnMobile = false),
              )
            else
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Show Cart',
                onPressed: () => setState(() => _showCartOnMobile = true),
              ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'history') {
                  _showHoldResumeCartsDialog(billingState.heldPOSCarts);
                } else if (val == 'close') {
                  final double sales = billingState.invoices
                      .where((inv) => inv.invoiceNumber.startsWith('INV-POS-'))
                      .fold(0.0, (sum, inv) => sum + inv.grandTotal);
                  _showCloseSessionDialog(activeSession, sales);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 18),
                      SizedBox(width: 8),
                      Text('Held Carts'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      Icon(
                        Icons.power_settings_new,
                        size: 18,
                        color: Colors.red,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Close Session',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Resume Held Cart',
              onPressed: () =>
                  _showHoldResumeCartsDialog(billingState.heldPOSCarts),
            ),
            IconButton(
              icon: const Icon(Icons.power_settings_new),
              tooltip: 'Close Session / Register',
              onPressed: () {
                final double sales = billingState.invoices
                    .where((inv) => inv.invoiceNumber.startsWith('INV-POS-'))
                    .fold(0.0, (sum, inv) => sum + inv.grandTotal);
                _showCloseSessionDialog(activeSession, sales);
              },
            ),
          ],
        ],
      ),
      body: isMobile
          ? (_showCartOnMobile ? cartPanel : productsPanel)
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: productsPanel),
                Expanded(flex: 4, child: cartPanel),
              ],
            ),
      bottomNavigationBar:
          isMobile && !_showCartOnMobile && _cartItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
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
                          '${_cartItems.length} Items | Total',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '₹${_grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentDark,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('View Cart'),
                      onPressed: () => setState(() => _showCartOnMobile = true),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
