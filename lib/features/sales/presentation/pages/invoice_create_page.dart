import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/services/gst_calculation_service.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../customer/presentation/providers/customer_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../product-listing/domain/utils/listed_catalog.dart';
import '../../../product-listing/presentation/providers/product_listing_provider.dart';
import '../../../purchase/presentation/providers/purchase_provider.dart';
import '../providers/sales_invoice_provider.dart';

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
        '1. Interest @18% will be charged if not paid within due date.\n2. Goods once sold will not be taken back.',
  );
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initInvoiceNo();
      ref.read(customerProvider.notifier).loadCustomers();
      ref.read(purchaseProvider.notifier).loadProducts();
      ref.read(productListingProvider.notifier).loadProducts();
    });
  }

  Future<void> _initInvoiceNo() async {
    final billingState = ref.read(billingRepositoryProvider);
    final count = billingState.invoices.length + 1;
    _invoiceNumberController.text =
        'TB/26-27/${count.toString().padLeft(4, '0')}';
    try {
      final backendNumber =
          await ref.read(salesInvoiceNotifierProvider.notifier).fetchNextNumber();
      if (mounted && backendNumber.isNotEmpty) {
        _invoiceNumberController.text = backendNumber;
      }
    } catch (_) {}
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

  List<T> _uniqueById<T>(Iterable<T> items, String Function(T item) idOf) {
    final map = <String, T>{};
    for (final item in items) {
      final id = idOf(item);
      if (id.isNotEmpty) map[id] = item;
    }
    return map.values.toList();
  }

  InvoiceItem _withTax(InvoiceItem item) {
    final businessStateCode =
        ref.read(businessProvider).activeBusiness?.stateCode ?? '27';
    final customerStateCode = _selectedCustomer?.stateCode ?? '27';
    final custGstType = _selectedCustomer?.isRegistered == true
        ? 'Regular'
        : 'Unregistered';
    final taxRes = GstCalculationService.calculate(
      quantity: item.quantity,
      rate: item.rate,
      discountPercentage: item.discountPercentage,
      gstRate: item.gstRate,
      businessStateCode: businessStateCode,
      placeOfSupplyStateCode: customerStateCode,
      customerGstType: custGstType,
    );
    final discAmt = item.quantity * item.rate * (item.discountPercentage / 100.0);
    return item.copyWith(
      discountAmount: discAmt,
      taxableValue: taxRes.taxableValue,
      cgst: taxRes.cgstAmount,
      sgst: taxRes.sgstAmount,
      igst: taxRes.igstAmount,
      cess: taxRes.cessAmount,
    );
  }

  void _repriceAllItems() {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _withTax(_items[i]);
    }
  }

  void _onCustomerSelected(Customer? customer) {
    if (customer == null) return;
    setState(() {
      _selectedCustomer = customer;
      _billingAddressController.text = customer.billingAddress;
      _shippingAddressController.text = customer.shippingAddress;
      _placeOfSupplyController.text = customer.state;
      if (_originalInvoiceId.isNotEmpty) {
        final stillValid = ref.read(billingRepositoryProvider).invoices.any(
          (inv) =>
              inv.id == _originalInvoiceId &&
              inv.customerId == customer.id &&
              !inv.isCreditNote,
        );
        if (!stillValid) _originalInvoiceId = '';
      }
      _repriceAllItems();
    });
  }

  void _patchItem(
    String id, {
    double? quantity,
    double? rate,
    double? discountPercentage,
  }) {
    final index = _items.indexWhere((it) => it.id == id);
    if (index < 0) return;
    final current = _items[index];
    setState(() {
      _items[index] = _withTax(
        current.copyWith(
          quantity: quantity,
          rate: rate,
          discountPercentage: discountPercentage,
        ),
      );
    });
  }

  void _addItem() {
    if (_selectedProduct == null && _selectedService == null) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please select an item first!',
        isError: true,
      );
      return;
    }

    if (_selectedProduct != null &&
        !isListedSellableProduct(_selectedProduct!)) {
      AppFeedback.showSnackbar(
        context,
        message: kProductNotListedSaleMessage,
        isError: true,
      );
      return;
    }

    final double qty = double.tryParse(_quantityController.text) ?? 1.0;
    final double rate = double.tryParse(_rateController.text) ?? 0.0;
    final double disc = double.tryParse(_discountController.text) ?? 0.0;

    if (qty <= 0) {
      AppFeedback.showSnackbar(
        context,
        message: 'Quantity must be greater than 0!',
        isError: true,
      );
      return;
    }

    final gstRate = _selectedProduct != null
        ? _selectedProduct!.gstRate
        : _selectedService!.gstRate;

    final item = _withTax(
      InvoiceItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        productId: _selectedProduct?.id ?? '',
        serviceId: _selectedService?.id ?? '',
        name: _selectedProduct?.name ?? _selectedService!.name,
        hsnSac: _selectedProduct?.hsnCode ?? _selectedService!.sacCode,
        quantity: qty,
        unit: _selectedProduct?.primaryUnit ?? _selectedService!.unit,
        rate: rate,
        discountPercentage: disc,
        discountAmount: 0,
        taxableValue: 0,
        gstRate: gstRate,
        cgst: 0,
        sgst: 0,
        igst: 0,
        cess: 0,
      ),
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
      AppFeedback.showSnackbar(
        context,
        message: 'Please select a customer!',
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

      final double totalTax = cgst + sgst + igst + cess;
      final double grossGrand = subTotal + totalTax;
      final double roundedGrand = grossGrand.roundToDouble();
      final double roundOff = double.parse(
        (roundedGrand - grossGrand).toStringAsFixed(2),
      );

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

      try {
        final backendPayload = <String, dynamic>{
          'invoiceNumber': invoice.invoiceNumber,
          'invoiceDate': invoice.invoiceDate.toIso8601String(),
          'customerId': invoice.customerId,
          'customerName': invoice.customerName,
          'customerPhone': _selectedCustomer?.mobile,
          'billingAddress': invoice.billingAddress,
          'shippingAddress': invoice.shippingAddress,
          'placeOfSupply': invoice.placeOfSupply,
          'supplyType': _selectedCustomer?.isRegistered == true ? 'B2B' : 'B2C',
          'taxableValue': invoice.taxableAmount,
          'subtotal': invoice.taxableAmount,
          'cgstAmount': invoice.cgst,
          'sgstAmount': invoice.sgst,
          'igstAmount': invoice.igst,
          'cessAmount': invoice.cess,
          'roundOff': invoice.roundOff,
          'grandTotal': invoice.grandTotal,
          'balanceAmount': invoice.balanceAmount,
          'paymentMode': invoice.paymentMode,
          'paymentStatus': 'UNPAID',
          'status': status == InvoiceStatus.confirmed ? 'SAVED' : 'DRAFT',
          'notes': invoice.notes,
          'termsAndConditions': invoice.termsConditions,
          'items': _items
              .map(
                (it) => {
                  if (it.productId.isNotEmpty) 'productId': it.productId,
                  if (it.serviceId.isNotEmpty) 'serviceId': it.serviceId,
                  'productName': it.name,
                  'hsnOrSacCode': it.hsnSac,
                  'quantity': it.quantity,
                  'unit': it.unit,
                  'rate': it.rate,
                  'discountPercent': it.discountPercentage,
                  'discountAmount': it.discountAmount,
                  'taxableValue': it.taxableValue,
                  'gstRatePercent': it.gstRate,
                  'cgstAmount': it.cgst,
                  'sgstAmount': it.sgst,
                  'igstAmount': it.igst,
                  'cessAmount': it.cess,
                  'lineTotal':
                      it.taxableValue + it.cgst + it.sgst + it.igst + it.cess,
                },
              )
              .toList(),
        };
        await ref
            .read(salesInvoiceNotifierProvider.notifier)
            .createInvoice(backendPayload);
      } catch (_) {}

      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Invoice saved successfully!',
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final customerState = ref.watch(customerProvider);
    final purchaseState = ref.watch(purchaseProvider);
    ref.watch(productListingProvider);

    final availableCustomers = _uniqueById<Customer>(
      [...customerState.customers, ...billingState.customers],
      (c) => c.id,
    )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final availableProducts = _uniqueById<Product>(
      [
        ...purchaseState.products,
        ...billingState.products,
      ],
      (p) => p.id,
    ).where(isListedSellableProduct).toList();

    final availableServices = _uniqueById<Service>(
      billingState.services,
      (s) => s.id,
    ).where((s) => s.isActive).toList();

    final eligibleOriginalInvoices = _uniqueById<Invoice>(
      billingState.invoices.where(
        (inv) =>
            inv.customerId == _selectedCustomer?.id &&
            inv.status != InvoiceStatus.cancelled &&
            !inv.isCreditNote,
      ),
      (inv) => inv.id,
    );

    final selectedCustomerId =
        (_selectedCustomer != null &&
            availableCustomers.any((c) => c.id == _selectedCustomer!.id))
        ? _selectedCustomer!.id
        : null;
    final selectedProductId =
        (_selectedProduct != null &&
            availableProducts.any((p) => p.id == _selectedProduct!.id))
        ? _selectedProduct!.id
        : null;
    final selectedServiceId =
        (_selectedService != null &&
            availableServices.any((s) => s.id == _selectedService!.id))
        ? _selectedService!.id
        : null;
    final selectedOriginalInvoiceId =
        eligibleOriginalInvoices.any((inv) => inv.id == _originalInvoiceId)
        ? _originalInvoiceId
        : null;

    final double subTotal = _items.fold(
      0,
      (sum, item) => sum + item.taxableValue,
    );
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
        title: Text(
          _isCreditNote ? 'Create Credit Note' : 'Create Sales Invoice',
        ),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context),
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
                  _isCreditNote ? 'Credit Note' : 'Invoice',
                ],
              ),
              const SizedBox(height: 12),

              // Transaction Type Segmented Toggle Box
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildDocTypeToggle(
                          isDark: isDark,
                          selected: !_isCreditNote,
                          title: 'Sales Invoice',
                          onTap: () {
                            setState(() {
                              _isCreditNote = false;
                              _originalInvoiceId = '';
                              _initInvoiceNo();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _buildDocTypeToggle(
                          isDark: isDark,
                          selected: _isCreditNote,
                          title: 'Credit Note',
                          subtitle: '(Sales Return)',
                          onTap: () {
                            setState(() {
                              _isCreditNote = true;
                              _initInvoiceNo();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
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
                                    Icons.person_outline,
                                    color: Color(0xFF2E7D32),
                                    size: 20,
                                  ),
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
                                    child: customerState.isLoading &&
                                            availableCustomers.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 18,
                                            ),
                                            child: LinearProgressIndicator(),
                                          )
                                        : availableCustomers.isEmpty
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFFCBD5E1),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.people_outline,
                                                  size: 18,
                                                  color: Color(0xFF64748B),
                                                ),
                                                const SizedBox(width: 8),
                                                const Expanded(
                                                  child: Text(
                                                    'No customers in database.',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF475569),
                                                    ),
                                                  ),
                                                ),
                                                TextButton.icon(
                                                  style: TextButton.styleFrom(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                  icon: const Icon(
                                                    Icons.person_add_alt_1_outlined,
                                                    size: 14,
                                                  ),
                                                  label: const Text(
                                                    'Add Customer',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                  onPressed: () => context.push(
                                                    '/customers/new',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : AppDropdownField<String>(
                                            label: 'Select Customer *',
                                            value: selectedCustomerId,
                                            items: availableCustomers.map((c) {
                                              return DropdownMenuItem(
                                                value: c.id,
                                                child: Text(
                                                  '${c.name} (${c.type})',
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (id) {
                                              if (id == null) return;
                                              final customer =
                                                  availableCustomers.firstWhere(
                                                (c) => c.id == id,
                                              );
                                              _onCustomerSelected(customer);
                                            },
                                          ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Place of Supply (State) *',
                                      controller: _placeOfSupplyController,
                                      onChanged: (_) {
                                        setState(_repriceAllItems);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (_isCreditNote) ...[
                                const SizedBox(height: AppSpacing.md),
                                AppDropdownField<String>(
                                  label: 'Select Original Sales Invoice *',
                                  value: selectedOriginalInvoiceId,
                                  items: eligibleOriginalInvoices.map((inv) {
                                    return DropdownMenuItem(
                                      value: inv.id,
                                      child: Text(
                                        '${inv.invoiceNumber} (₹${inv.grandTotal})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _originalInvoiceId = val ?? '';
                                      if (val == null) return;
                                      final invoice = eligibleOriginalInvoices
                                          .firstWhere((inv) => inv.id == val);
                                      _items
                                        ..clear()
                                        ..addAll(
                                          invoice.items.asMap().entries.map(
                                            (entry) => _withTax(
                                              entry.value.copyWith(
                                                id: 'item_${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
                                              ),
                                            ),
                                          ),
                                        );
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
                                    child: AppDropdownField<String?>(
                                      label: 'Select Product',
                                      value: selectedProductId,
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text('None (choose service)'),
                                        ),
                                        ...availableProducts.map((p) {
                                          return DropdownMenuItem<String?>(
                                            value: p.id,
                                            child: Text(
                                              '${p.name} (Stock: ${p.currentStock})',
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (id) {
                                        setState(() {
                                          _selectedProduct = id == null
                                              ? null
                                              : availableProducts.firstWhere(
                                                  (p) => p.id == id,
                                                );
                                          if (_selectedProduct != null) {
                                            _selectedService = null;
                                            _rateController.text =
                                                _selectedProduct!.sellingPrice
                                                    .toString();
                                            _quantityController.text = '1';
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: AppDropdownField<String?>(
                                      label: 'Select Service',
                                      value: selectedServiceId,
                                      items: [
                                        const DropdownMenuItem<String?>(
                                          value: null,
                                          child: Text('None'),
                                        ),
                                        ...availableServices.map((s) {
                                          return DropdownMenuItem<String?>(
                                            value: s.id,
                                            child: Text(
                                              s.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }),
                                      ],
                                      onChanged: (id) {
                                        setState(() {
                                          _selectedService = id == null
                                              ? null
                                              : availableServices.firstWhere(
                                                  (s) => s.id == id,
                                                );
                                          if (_selectedService != null) {
                                            _selectedProduct = null;
                                            _rateController.text =
                                                _selectedService!.rate
                                                    .toString();
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
                                  Expanded(
                                    child: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: SizedBox(
                                      height: 48,
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
                                'Added Items List',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
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
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Item Details',
                                    flex: 2,
                                    cellBuilder: (item) => Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Qty',
                                    isNumeric: true,
                                    cellBuilder: (item) => SizedBox(
                                      width: 72,
                                      child: TextFormField(
                                        key: ValueKey('${item.id}_qty'),
                                        initialValue: item.quantity.toString(),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 8,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          final q = double.tryParse(val);
                                          if (q == null || q <= 0) return;
                                          _patchItem(item.id, quantity: q);
                                        },
                                      ),
                                    ),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Rate (₹)',
                                    isNumeric: true,
                                    cellBuilder: (item) => SizedBox(
                                      width: 88,
                                      child: TextFormField(
                                        key: ValueKey('${item.id}_rate'),
                                        initialValue: item.rate.toString(),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 8,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          final r = double.tryParse(val);
                                          if (r == null || r < 0) return;
                                          _patchItem(item.id, rate: r);
                                        },
                                      ),
                                    ),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Disc%',
                                    isNumeric: true,
                                    cellBuilder: (item) => SizedBox(
                                      width: 64,
                                      child: TextFormField(
                                        key: ValueKey('${item.id}_disc'),
                                        initialValue: item.discountPercentage
                                            .toString(),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.right,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 8,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          final d = double.tryParse(val);
                                          if (d == null || d < 0) return;
                                          _patchItem(
                                            item.id,
                                            discountPercentage: d,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Taxable (₹)',
                                    isNumeric: true,
                                    cellBuilder: (item) => Text(
                                      item.taxableValue.toStringAsFixed(2),
                                    ),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'GST',
                                    cellBuilder: (item) => Text(
                                      '${item.gstRate.toStringAsFixed(0)}%',
                                    ),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
                                    label: 'Total GST (₹)',
                                    isNumeric: true,
                                    cellBuilder: (item) => Text(
                                      (item.cgst + item.sgst + item.igst)
                                          .toStringAsFixed(2),
                                    ),
                                  ),
                                  TableColumnSpec<InvoiceItem>(
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

                  // Right Side Column (Grand Totals & Confirm Actions)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Document Settings Card
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
                                  const Text(
                                    'Invoice Date: ',
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
                                      '${_invoiceDate.day}/${_invoiceDate.month}/${_invoiceDate.year}',
                                    ),
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
                                    value: 'Cash',
                                    child: Text('Cash Payment'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Bank',
                                    child: Text('Bank Transfer'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'UPI',
                                    child: Text('UPI / QR'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Card',
                                    child: Text('Credit/Debit Card'),
                                  ),
                                ],
                                onChanged: (val) => setState(
                                  () => _paymentMode = val ?? 'Bank',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Invoice Totals Card (Highlighted)
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
                                    'Invoice Totals',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _buildTotalRow(
                                'Total Taxable Value:',
                                '₹${subTotal.toStringAsFixed(2)}',
                              ),
                              if (cgst > 0)
                                _buildTotalRow(
                                  'CGST Amount:',
                                  '₹${cgst.toStringAsFixed(2)}',
                                ),
                              if (sgst > 0)
                                _buildTotalRow(
                                  'SGST Amount:',
                                  '₹${sgst.toStringAsFixed(2)}',
                                ),
                              if (igst > 0)
                                _buildTotalRow(
                                  'IGST Amount:',
                                  '₹${igst.toStringAsFixed(2)}',
                                ),
                              if (cess > 0)
                                _buildTotalRow(
                                  'Cess Amount:',
                                  '₹${cess.toStringAsFixed(2)}',
                                ),
                              _buildTotalRow(
                                'Tax Payable:',
                                '₹${totalTax.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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

                        // Terms & Internal Notes Card
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
                        ResponsiveRow(
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
                                    _saveInvoice(InvoiceStatus.draft),
                                child: const Text(
                                  'Save Draft',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('Confirm & Finalize'),
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

  Widget _buildDocTypeToggle({
    required bool isDark,
    required bool selected,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final selectedColor = AppColors.accent;
    final unselectedColor = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textLightSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? AppColors.backgroundDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.3 : 0.06,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? selectedColor : unselectedColor,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 14,
                child: subtitle == null
                    ? null
                    : Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? selectedColor.withValues(alpha: 0.9)
                              : unselectedColor,
                        ),
                      ),
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
          Text(
            value,
            style: style ?? const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
