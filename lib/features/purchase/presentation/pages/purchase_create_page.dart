import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/services/gst_calculation_service.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class PurchaseCreatePage extends ConsumerStatefulWidget {
  const PurchaseCreatePage({super.key});

  @override
  ConsumerState<PurchaseCreatePage> createState() => _PurchaseCreatePageState();
}

class _PurchaseCreatePageState extends ConsumerState<PurchaseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _purchaseNumberController = TextEditingController();
  final _supplierInvoiceNumberController = TextEditingController();
  final _freightChargesController = TextEditingController(text: '0.0');
  final _otherChargesController = TextEditingController(text: '0.0');
  final _notesController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  Supplier? _selectedSupplier;
  final List<PurchaseItem> _items = [];
  String _paymentMode = 'Bank';
  bool _isDebitNote = false;
  String _originalPurchaseId = '';

  // For item addition
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _rateController = TextEditingController(text: '0.0');
  final _discountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initPurchaseNo());
  }

  void _initPurchaseNo() {
    final billingState = ref.read(billingRepositoryProvider);
    final count = billingState.purchases.length + 1;
    _purchaseNumberController.text =
        'TB/26-27/${count.toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    _purchaseNumberController.dispose();
    _supplierInvoiceNumberController.dispose();
    _freightChargesController.dispose();
    _otherChargesController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _onSupplierSelected(Supplier? s) {
    if (s == null) return;
    setState(() {
      _selectedSupplier = s;
    });
  }

  void _addItem() {
    if (_selectedProduct == null) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please select a product first!',
        isError: true,
      );
      return;
    }

    final double qty = double.tryParse(_quantityController.text) ?? 1.0;
    final double rate = double.tryParse(_rateController.text) ?? 0.0;
    final double disc = double.tryParse(_discountController.text) ?? 0.0;

    final double grossAmount = qty * rate;
    final double discAmt = grossAmount * (disc / 100.0);

    final businessStateCode =
        ref.read(businessProvider).activeBusiness?.stateCode ?? '27';
    final supplierStateCode = _selectedSupplier?.stateCode ?? '27';
    final gstRate = _selectedProduct!.gstRate;

    final taxRes = GstCalculationService.calculate(
      quantity: qty,
      rate: rate,
      discountPercentage: disc,
      gstRate: gstRate,
      businessStateCode: businessStateCode,
      placeOfSupplyStateCode: supplierStateCode,
      customerGstType:
          'Regular', // Assumed standard B2B registered treatment for supplier purchases
    );

    final item = PurchaseItem(
      id: 'pur_item_${DateTime.now().millisecondsSinceEpoch}',
      productId: _selectedProduct!.id,
      name: _selectedProduct!.name,
      hsnCode: _selectedProduct!.hsnCode,
      quantity: qty,
      unit: _selectedProduct!.primaryUnit,
      rate: rate,
      discountPercentage: disc,
      discountAmount: discAmt,
      taxableValue: taxRes.taxableValue,
      gstRate: gstRate,
      cgst: taxRes.cgstAmount,
      sgst: taxRes.sgstAmount,
      igst: taxRes.igstAmount,
      cess: taxRes.cessAmount,
    );

    setState(() {
      _items.add(item);
      _selectedProduct = null;
      _quantityController.text = '1';
      _rateController.text = '0.0';
      _discountController.text = '0';
    });
  }

  void _savePurchase(PurchaseStatus status) async {
    if (_selectedSupplier == null) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please select a supplier!',
        isError: true,
      );
      return;
    }

    if (_items.isEmpty) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please add at least one item!',
        isError: true,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final double subTotal = _items.fold(
        0,
        (sum, item) => sum + item.taxableValue,
      );
      final double cgst = _items.fold(0, (sum, item) => sum + item.cgst);
      final double sgst = _items.fold(0, (sum, item) => sum + item.sgst);
      final double igst = _items.fold(0, (sum, item) => sum + item.igst);
      final double cess = _items.fold(0, (sum, item) => sum + item.cess);

      final double freight =
          double.tryParse(_freightChargesController.text) ?? 0.0;
      final double other = double.tryParse(_otherChargesController.text) ?? 0.0;

      final double totalTax = cgst + sgst + igst + cess;
      final double grossGrand = subTotal + totalTax + freight + other;
      final double roundedGrand = grossGrand.roundToDouble();
      final double roundOff = double.parse(
        (roundedGrand - grossGrand).toStringAsFixed(2),
      );

      final purchase = Purchase(
        id: 'pur_${DateTime.now().millisecondsSinceEpoch}',
        purchaseNumber: _purchaseNumberController.text,
        supplierInvoiceNumber: _supplierInvoiceNumberController.text.isNotEmpty
            ? _supplierInvoiceNumberController.text
            : 'N/A',
        purchaseDate: _purchaseDate,
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        items: _items,
        taxableAmount: double.parse(subTotal.toStringAsFixed(2)),
        cgst: double.parse(cgst.toStringAsFixed(2)),
        sgst: double.parse(sgst.toStringAsFixed(2)),
        igst: double.parse(igst.toStringAsFixed(2)),
        cess: double.parse(cess.toStringAsFixed(2)),
        freightCharges: freight,
        otherCharges: other,
        roundOff: roundOff,
        grandTotal: roundedGrand,
        balanceAmount: roundedGrand,
        paymentMode: _paymentMode,
        status: status,
        notes: _notesController.text,
        originalPurchaseId: _isDebitNote ? _originalPurchaseId : '',
      );

      await ref.read(billingRepositoryProvider.notifier).addPurchase(purchase);

      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Purchase bill recorded successfully!',
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);

    final double subTotal = _items.fold(
      0,
      (sum, item) => sum + item.taxableValue,
    );
    final double cgst = _items.fold(0, (sum, item) => sum + item.cgst);
    final double sgst = _items.fold(0, (sum, item) => sum + item.sgst);
    final double igst = _items.fold(0, (sum, item) => sum + item.igst);
    final double cess = _items.fold(0, (sum, item) => sum + item.cess);

    final double freight =
        double.tryParse(_freightChargesController.text) ?? 0.0;
    final double other = double.tryParse(_otherChargesController.text) ?? 0.0;

    final double totalTax = cgst + sgst + igst + cess;
    final double grossGrand = subTotal + totalTax + freight + other;
    final double roundedGrand = grossGrand.roundToDouble();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isDebitNote ? 'Record Debit Note' : 'Record Purchase Bill',
        ),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: _isDebitNote
                    ? 'New Debit Note (Purchase Return)'
                    : 'New Purchase Bill',
                description:
                    'Record incoming merchant invoices, automatically increasing inventory stocks and payables.',
                breadcrumbs: [
                  'Dashboard',
                  'Purchase',
                  _isDebitNote ? 'Debit Note' : 'New Bill',
                ],
              ),
              const SizedBox(height: 12),

              // Transaction Type Segmented Toggle Box
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDebitNote = false;
                            _originalPurchaseId = '';
                            _initPurchaseNo();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isDebitNote
                                ? (isDark
                                      ? const Color(0xFF2E2E2E)
                                      : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isDebitNote
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Purchase Bill',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: !_isDebitNote
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isDebitNote = true;
                            _initPurchaseNo();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isDebitNote
                                ? (isDark
                                      ? const Color(0xFF2E2E2E)
                                      : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isDebitNote
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Debit Note (Purchase Return)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isDebitNote
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              ResponsiveRow(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Supplier select & items
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Supplier Parameters Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Supplier Parameters',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppDropdownField<Supplier>(
                                      label: 'Select Supplier *',
                                      value: _selectedSupplier,
                                      items: billingState.suppliers.map((s) {
                                        return DropdownMenuItem(
                                          value: s,
                                          child: Text(s.name),
                                        );
                                      }).toList(),
                                      onChanged: _onSupplierSelected,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Supplier Invoice Number *',
                                      controller:
                                          _supplierInvoiceNumberController,
                                      validator: (val) =>
                                          val == null || val.isEmpty
                                          ? 'Supplier invoice reference is required'
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              if (_isDebitNote) ...[
                                const SizedBox(height: AppSpacing.md),
                                AppDropdownField<String>(
                                  label: 'Select Original Purchase Bill *',
                                  value: _originalPurchaseId.isEmpty
                                      ? null
                                      : _originalPurchaseId,
                                  items: billingState.purchases
                                      .where(
                                        (p) =>
                                            p.supplierId ==
                                                _selectedSupplier?.id &&
                                            p.status !=
                                                PurchaseStatus.cancelled &&
                                            !p.isDebitNote,
                                      )
                                      .map((p) {
                                        return DropdownMenuItem(
                                          value: p.id,
                                          child: Text(
                                            '${p.purchaseNumber} (₹${p.grandTotal})',
                                          ),
                                        );
                                      })
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _originalPurchaseId = val ?? '';
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Add Product Item Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.add_shopping_cart,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add Product Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              AppDropdownField<Product>(
                                label: 'Select Product *',
                                value: _selectedProduct,
                                items: billingState.products.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text('${p.name} (Code: ${p.code})'),
                                  );
                                }).toList(),
                                onChanged: (prod) {
                                  setState(() {
                                    _selectedProduct = prod;
                                    if (prod != null) {
                                      _rateController.text = prod.purchasePrice
                                          .toString();
                                      _quantityController.text = '1';
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Quantity',
                                      controller: _quantityController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Purchase Rate (₹)',
                                      controller: _rateController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Discount (%)',
                                      controller: _discountController,
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Add Item'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2E7D32,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      onPressed: _addItem,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Added Items Table Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Added Products List',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              AppTable<PurchaseItem>(
                                items: _items,
                                emptyMessage:
                                    'No products added to this purchase bill yet.',
                                mobileCardBuilder: (item) {
                                  return AppCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 18,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  _items.removeWhere(
                                                    (it) => it.id == item.id,
                                                  );
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${item.quantity} ${item.unit} @ ₹${item.rate.toStringAsFixed(2)}',
                                            ),
                                            if (item.discountPercentage > 0)
                                              Text(
                                                'Disc: ${item.discountPercentage.toStringAsFixed(0)}%',
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Taxable: ₹${item.taxableValue.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11,
                                              ),
                                            ),
                                            Text(
                                              'GST: ${item.gstRate.toStringAsFixed(0)}% (₹${(item.cgst + item.sgst + item.igst).toStringAsFixed(2)})',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Item Amount:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '₹${(item.taxableValue + item.cgst + item.sgst + item.igst).toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                columns: [
                                  TableColumnSpec<PurchaseItem>(
                                    label: 'Product Name',
                                    flex: 2,
                                    cellBuilder: (item) => Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TableColumnSpec<PurchaseItem>(
                                    label: 'Qty',
                                    isNumeric: true,
                                    cellBuilder: (item) =>
                                        Text('${item.quantity} ${item.unit}'),
                                  ),
                                  TableColumnSpec<PurchaseItem>(
                                    label: 'Rate (₹)',
                                    isNumeric: true,
                                    cellBuilder: (item) =>
                                        Text(item.rate.toStringAsFixed(2)),
                                  ),
                                  TableColumnSpec<PurchaseItem>(
                                    label: 'Disc%',
                                    isNumeric: true,
                                    cellBuilder: (item) => Text(
                                      '${item.discountPercentage.toStringAsFixed(0)}%',
                                    ),
                                  ),
                                  TableColumnSpec<PurchaseItem>(
                                    label: 'Taxable (₹)',
                                    isNumeric: true,
                                    cellBuilder: (item) => Text(
                                      item.taxableValue.toStringAsFixed(2),
                                    ),
                                  ),
                                  TableColumnSpec<PurchaseItem>(
                                    label: 'GST',
                                    cellBuilder: (item) => Text(
                                      '${item.gstRate.toStringAsFixed(0)}%',
                                    ),
                                  ),
                                  TableColumnSpec<PurchaseItem>(
                                    label: 'Total GST (₹)',
                                    isNumeric: true,
                                    cellBuilder: (item) => Text(
                                      (item.cgst + item.sgst + item.igst)
                                          .toStringAsFixed(2),
                                    ),
                                  ),
                                  TableColumnSpec<PurchaseItem>(
                                    label: 'Actions',
                                    cellBuilder: (item) => IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _items.removeWhere(
                                            (it) => it.id == item.id,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right Column: Summary & Save
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Document Parameters Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.feed_outlined,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Document Parameters',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              AppTextField(
                                label: 'Purchase Ref Code *',
                                controller: _purchaseNumberController,
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Bill reference number is required'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Purchase Date: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      '${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}',
                                    ),
                                    onPressed: () async {
                                      final selected = await showDatePicker(
                                        context: context,
                                        initialDate: _purchaseDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (selected != null) {
                                        setState(() {
                                          _purchaseDate = selected;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Bill Breakdown Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: const [
                                  Icon(
                                    Icons.analytics_outlined,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Bill Breakdown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildSummaryRow(
                                'Total Taxable Value:',
                                '₹${subTotal.toStringAsFixed(2)}',
                              ),
                              if (cgst > 0)
                                _buildSummaryRow(
                                  'CGST Amount:',
                                  '₹${cgst.toStringAsFixed(2)}',
                                ),
                              if (sgst > 0)
                                _buildSummaryRow(
                                  'SGST Amount:',
                                  '₹${sgst.toStringAsFixed(2)}',
                                ),
                              if (igst > 0)
                                _buildSummaryRow(
                                  'IGST Amount:',
                                  '₹${igst.toStringAsFixed(2)}',
                                ),
                              if (cess > 0)
                                _buildSummaryRow(
                                  'Cess Amount:',
                                  '₹${cess.toStringAsFixed(2)}',
                                ),
                              _buildSummaryRow(
                                'Total GST Tax:',
                                '₹${totalTax.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              AppTextField(
                                label: 'Freight Charges (₹)',
                                controller: _freightChargesController,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {}),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AppTextField(
                                label: 'Other Charges (₹)',
                                controller: _otherChargesController,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {}),
                              ),
                              const Divider(height: 20),
                              // Highlighted Grand Total Segment
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE8F5E9),
                                      Color(0xFFC8E6C9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Grand Total:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                    Text(
                                      '₹${roundedGrand.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Internal Notes Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: AppTextField(
                            label: 'Internal Notes / Audit Details',
                            controller: _notesController,
                            maxLines: 3,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side: const BorderSide(color: Colors.grey),
                                ),
                                onPressed: () =>
                                    _savePurchase(PurchaseStatus.draft),
                                child: const Text(
                                  'Save Draft',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Confirm & Add Stock'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: () =>
                                    _savePurchase(PurchaseStatus.confirmed),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style ?? const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: style ?? const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
