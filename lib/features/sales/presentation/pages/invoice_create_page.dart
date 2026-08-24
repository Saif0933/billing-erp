import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/services/gst_calculation_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class InvoiceCreatePage extends ConsumerStatefulWidget {
  const InvoiceCreatePage({super.key});

  @override
  ConsumerState<InvoiceCreatePage> createState() => _InvoiceCreatePageState();
}

class _InvoiceCreatePageState extends ConsumerState<InvoiceCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceNumberController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _placeOfSupplyController = TextEditingController(text: 'Maharashtra');
  final _termsController = TextEditingController(
      text:
          '1. Interest @18% will be charged if not paid within due date.\n2. Goods once sold will not be taken back.');
  final _notesController = TextEditingController();

  DateTime _invoiceDate = DateTime.now();
  Customer? _selectedCustomer;
  final List<InvoiceItem> _items = [];
  String _paymentMode = 'Bank';
  bool _isCreditNote = false;
  String _originalInvoiceId = '';

  // For adding a single item
  Product? _selectedProduct;
  Service? _selectedService;
  final _quantityController = TextEditingController(text: '1');
  final _rateController = TextEditingController(text: '0.0');
  final _discountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initInvoiceNo());
  }

  void _initInvoiceNo() {
    final billingState = ref.read(billingRepositoryProvider);
    final count = billingState.invoices.length + 1;
    _invoiceNumberController.text =
        'TB/26-27/${count.toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    _placeOfSupplyController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _onCustomerSelected(Customer? customer) {
    if (customer == null) return;
    setState(() {
      _selectedCustomer = customer;
      _billingAddressController.text = customer.billingAddress;
      _shippingAddressController.text = customer.shippingAddress;
      _placeOfSupplyController.text = customer.state;
    });
  }

  void _addItem() {
    if (_selectedProduct == null && _selectedService == null) {
      AppFeedback.showSnackbar(context,
          message: 'Please select an item first!', isError: true);
      return;
    }

    final double qty = double.tryParse(_quantityController.text) ?? 1.0;
    final double rate = double.tryParse(_rateController.text) ?? 0.0;
    final double disc = double.tryParse(_discountController.text) ?? 0.0;

    final double grossAmount = qty * rate;
    final double discAmt = grossAmount * (disc / 100.0);
    final double taxable = grossAmount - discAmt;

    final businessStateCode =
        ref.read(businessProvider).activeBusiness?.stateCode ?? '27';
    final customerStateCode = _selectedCustomer?.stateCode ?? '27';
    final custGstType =
        _selectedCustomer?.isRegistered == true ? 'Regular' : 'Unregistered';
    final gstRate = _selectedProduct != null
        ? _selectedProduct!.gstRate
        : _selectedService!.gstRate;

    final taxRes = GstCalculationService.calculate(
      quantity: qty,
      rate: rate,
      discountPercentage: disc,
      gstRate: gstRate,
      businessStateCode: businessStateCode,
      placeOfSupplyStateCode: customerStateCode,
      customerGstType: custGstType,
    );

    final item = InvoiceItem(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      productId: _selectedProduct?.id ?? '',
      serviceId: _selectedService?.id ?? '',
      name: _selectedProduct?.name ?? _selectedService!.name,
      hsnSac: _selectedProduct?.hsnCode ?? _selectedService!.sacCode,
      quantity: qty,
      unit: _selectedProduct?.primaryUnit ?? _selectedService!.unit,
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
      _selectedService = null;
      _quantityController.text = '1';
      _rateController.text = '0.0';
      _discountController.text = '0';
    });
  }

  void _saveInvoice(InvoiceStatus status) async {
    if (_selectedCustomer == null) {
      AppFeedback.showSnackbar(context,
          message: 'Please select a customer!', isError: true);
      return;
    }

    if (_items.isEmpty) {
      AppFeedback.showSnackbar(context,
          message: 'Please add at least one item!', isError: true);
      return;
    }

    if (_formKey.currentState!.validate()) {
      final double subTotal =
          _items.fold(0, (sum, item) => sum + item.taxableValue);
      final double cgst = _items.fold(0, (sum, item) => sum + item.cgst);
      final double sgst = _items.fold(0, (sum, item) => sum + item.sgst);
      final double igst = _items.fold(0, (sum, item) => sum + item.igst);
      final double cess = _items.fold(0, (sum, item) => sum + item.cess);

      final double totalTax = cgst + sgst + igst + cess;
      final double grossGrand = subTotal + totalTax;
      final double roundedGrand = grossGrand.roundToDouble();
      final double roundOff =
          double.parse((roundedGrand - grossGrand).toStringAsFixed(2));

      final invoice = Invoice(
        id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: _invoiceNumberController.text,
        invoiceDate: _invoiceDate,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        billingAddress: _billingAddressController.text,
        shippingAddress: _shippingAddressController.text,
        placeOfSupply: _placeOfSupplyController.text,
        items: _items,
        taxableAmount: double.parse(subTotal.toStringAsFixed(2)),
        cgst: double.parse(cgst.toStringAsFixed(2)),
        sgst: double.parse(sgst.toStringAsFixed(2)),
        igst: double.parse(igst.toStringAsFixed(2)),
        cess: double.parse(cess.toStringAsFixed(2)),
        roundOff: roundOff,
        grandTotal: roundedGrand,
        balanceAmount:
            roundedGrand, // Outstanding balance starts as full grandTotal
        paymentMode: _paymentMode,
        status: status,
        notes: _notesController.text,
        termsConditions: _termsController.text,
        originalInvoiceId: _isCreditNote ? _originalInvoiceId : '',
      );

      await ref.read(billingRepositoryProvider.notifier).addInvoice(invoice);

      if (mounted) {
        AppFeedback.showSnackbar(context,
            message: 'Invoice saved successfully!');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final activeBiz = ref.watch(businessProvider).activeBusiness;

    final double subTotal =
        _items.fold(0, (sum, item) => sum + item.taxableValue);
    final double cgst = _items.fold(0, (sum, item) => sum + item.cgst);
    final double sgst = _items.fold(0, (sum, item) => sum + item.sgst);
    final double igst = _items.fold(0, (sum, item) => sum + item.igst);
    final double cess = _items.fold(0, (sum, item) => sum + item.cess);
    final double totalTax = cgst + sgst + igst + cess;
    final double grossGrand = subTotal + totalTax;
    final double roundedGrand = grossGrand.roundToDouble();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreditNote ? 'Create Credit Note' : 'Create Sales Invoice'),
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
                title: _isCreditNote
                    ? 'New Credit Note (Sales Return)'
                    : 'New Sales Invoice',
                description:
                    'Record sales trade operations, automatically generating inventory and ledger entries.',
                breadcrumbs: [
                  'Dashboard',
                  'Sales',
                  _isCreditNote ? 'Credit Note' : 'Invoice'
                ],
              ),
              const SizedBox(height: 12),

              // Transaction Type Segmented Toggle Box
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCreditNote = false;
                            _originalInvoiceId = '';
                            _initInvoiceNo();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isCreditNote
                                ? (isDark ? const Color(0xFF2E2E2E) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !_isCreditNote
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Sales Invoice',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: !_isCreditNote
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
                            _isCreditNote = true;
                            _initInvoiceNo();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isCreditNote
                                ? (isDark ? const Color(0xFF2E2E2E) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _isCreditNote
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Credit Note (Sales Return)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _isCreditNote
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
                  // Left Side Column (Customer Info & Items)
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Customer Parameters Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.person_outline,
                                      color: Color(0xFF2E7D32), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Customer Parameters',
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
                                    child: AppDropdownField<Customer>(
                                      label: 'Select Customer *',
                                      value: _selectedCustomer,
                                      items: billingState.customers.map((c) {
                                        return DropdownMenuItem(
                                            value: c,
                                            child: Text('${c.name} (${c.type})'));
                                      }).toList(),
                                      onChanged: _onCustomerSelected,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Place of Supply (State) *',
                                      controller: _placeOfSupplyController,
                                    ),
                                  ),
                                ],
                              ),
                              if (_isCreditNote) ...[
                                const SizedBox(height: AppSpacing.md),
                                AppDropdownField<String>(
                                  label: 'Select Original Sales Invoice *',
                                  value: _originalInvoiceId.isEmpty
                                      ? null
                                      : _originalInvoiceId,
                                  items: billingState.invoices
                                      .where((inv) =>
                                          inv.customerId ==
                                              _selectedCustomer?.id &&
                                          inv.status !=
                                              InvoiceStatus.cancelled &&
                                          !inv.isCreditNote)
                                      .map((inv) {
                                    return DropdownMenuItem(
                                        value: inv.id,
                                        child: Text(
                                            '${inv.invoiceNumber} (₹${inv.grandTotal})'));
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _originalInvoiceId = val ?? '';
                                    });
                                  },
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Billing Address',
                                      controller: _billingAddressController,
                                      maxLines: 2,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Shipping Address',
                                      controller: _shippingAddressController,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Add Product / Service Item Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.add_shopping_cart,
                                      color: Color(0xFF2E7D32), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add Product or Service Item',
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
                                    child: AppDropdownField<Product>(
                                      label: 'Select Product',
                                      value: _selectedProduct,
                                      items: billingState.products
                                          .where((p) => p.isActive)
                                          .map((p) {
                                        return DropdownMenuItem(
                                            value: p,
                                            child: Text(
                                                '${p.name} (Stock: ${p.currentStock})'));
                                      }).toList(),
                                      onChanged: (prod) {
                                        setState(() {
                                          _selectedProduct = prod;
                                          _selectedService = null;
                                          if (prod != null) {
                                            _rateController.text =
                                                prod.sellingPrice.toString();
                                            _quantityController.text = '1';
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: AppDropdownField<Service>(
                                      label: 'Select Service',
                                      value: _selectedService,
                                      items: billingState.services
                                          .where((s) => s.isActive)
                                          .map((s) {
                                        return DropdownMenuItem(
                                            value: s, child: Text(s.name));
                                      }).toList(),
                                      onChanged: (serv) {
                                        setState(() {
                                          _selectedService = serv;
                                          _selectedProduct = null;
                                          if (serv != null) {
                                            _rateController.text =
                                                serv.rate.toString();
                                            _quantityController.text = '1';
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
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
                                      label: 'Rate / Price (₹)',
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
                                        backgroundColor: const Color(0xFF2E7D32),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
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

                        // List of Added Items Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Added Items List',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 12),
                              AppTable<InvoiceItem>(
                                items: _items,
                                emptyMessage:
                                    'No items added to this invoice yet.',
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
                                                    fontSize: 14),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red,
                                                  size: 18),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () {
                                                setState(() {
                                                  _items.removeWhere(
                                                      (it) => it.id == item.id);
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
                                                '${item.quantity} ${item.unit} @ ₹${item.rate.toStringAsFixed(2)}'),
                                            if (item.discountPercentage > 0)
                                              Text(
                                                  'Disc: ${item.discountPercentage.toStringAsFixed(0)}%'),
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
                                                    fontSize: 11)),
                                            Text(
                                                'GST: ${item.gstRate.toStringAsFixed(0)}% (₹${(item.cgst + item.sgst + item.igst).toStringAsFixed(2)})',
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text('Total Item Amount:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize: 13)),
                                            Text(
                                                '₹${(item.taxableValue + item.cgst + item.sgst + item.igst).toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Color(0xFF2E7D32))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                columns: [
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Item Details',
                                    flex: 2,
                                    cellBuilder: (item) => Text(item.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Qty',
                                    isNumeric: true,
                                    cellBuilder: (item) =>
                                        Text('${item.quantity} ${item.unit}'),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Rate (₹)',
                                    isNumeric: true,
                                    cellBuilder: (item) =>
                                        Text(item.rate.toStringAsFixed(2)),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Disc%',
                                    isNumeric: true,
                                    cellBuilder: (item) => Text(
                                        '${item.discountPercentage.toStringAsFixed(0)}%'),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Taxable (₹)',
                                    isNumeric: true,
                                    cellBuilder: (item) => Text(
                                        item.taxableValue.toStringAsFixed(2)),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'GST',
                                    cellBuilder: (item) => Text(
                                        '${item.gstRate.toStringAsFixed(0)}%'),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Total GST (₹)',
                                    isNumeric: true,
                                    cellBuilder: (item) => Text(
                                        (item.cgst + item.sgst + item.igst)
                                            .toStringAsFixed(2)),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Actions',
                                    cellBuilder: (item) => IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _items.removeWhere(
                                              (it) => it.id == item.id);
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

                  // Right Side Column (Grand Totals & Confirm Actions)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Document Settings Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.feed_outlined,
                                      color: Color(0xFF2E7D32), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Document Settings',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              AppTextField(
                                label: 'Invoice Reference Number *',
                                controller: _invoiceNumberController,
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Invoice number is required'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Invoice Date: ',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  TextButton.icon(
                                    icon: const Icon(
                                        Icons.calendar_month_outlined,
                                        size: 18),
                                    label: Text(
                                        '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}'),
                                    onPressed: () async {
                                      final selected = await showDatePicker(
                                        context: context,
                                        initialDate: _invoiceDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (selected != null) {
                                        setState(() {
                                          _invoiceDate = selected;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppDropdownField<String>(
                                label: 'Primary Payment Mode',
                                value: _paymentMode,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Cash', child: Text('Cash Payment')),
                                  DropdownMenuItem(
                                      value: 'Bank', child: Text('Bank Transfer')),
                                  DropdownMenuItem(
                                      value: 'UPI', child: Text('UPI / QR')),
                                  DropdownMenuItem(
                                      value: 'Card',
                                      child: Text('Credit/Debit Card')),
                                ],
                                onChanged: (val) =>
                                    setState(() => _paymentMode = val ?? 'Bank'),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Invoice Totals Card (Highlighted)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.analytics_outlined,
                                      color: Color(0xFF2E7D32), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Invoice Totals',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildTotalRow('Total Taxable Value:',
                                  '₹${subTotal.toStringAsFixed(2)}'),
                              if (cgst > 0)
                                _buildTotalRow('CGST Amount:',
                                    '₹${cgst.toStringAsFixed(2)}'),
                              if (sgst > 0)
                                _buildTotalRow('SGST Amount:',
                                    '₹${sgst.toStringAsFixed(2)}'),
                              if (igst > 0)
                                _buildTotalRow('IGST Amount:',
                                    '₹${igst.toStringAsFixed(2)}'),
                              if (cess > 0)
                                _buildTotalRow('Cess Amount:',
                                    '₹${cess.toStringAsFixed(2)}'),
                              _buildTotalRow(
                                  'Tax Payable:', '₹${totalTax.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const Divider(height: 20),
                              // Highlighted Grand Total Segment
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFE8F5E9),
                                      Color(0xFFC8E6C9)
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
                              )
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Terms & Internal Notes Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                label: 'Terms & Conditions',
                                controller: _termsController,
                                maxLines: 3,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AppTextField(
                                label: 'Internal Notes',
                                controller: _notesController,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  side:
                                      const BorderSide(color: Colors.grey),
                                ),
                                onPressed: () =>
                                    _saveInvoice(InvoiceStatus.draft),
                                child: const Text('Save Draft',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Confirm & Finalize'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: () =>
                                    _saveInvoice(InvoiceStatus.confirmed),
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

  Widget _buildTotalRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style ?? const TextStyle(color: Colors.grey)),
          Text(value,
              style: style ?? const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
