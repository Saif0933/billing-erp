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
import '../../../../shared/widgets/feedback.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../customer/presentation/providers/customer_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../inventory/presentation/providers/goods_warehouse_provider.dart';
import '../../../product-listing/domain/utils/listed_catalog.dart';
import '../../../product-listing/presentation/providers/product_listing_provider.dart';
import '../../../purchase/presentation/providers/purchase_provider.dart';
import '../../../service/presentation/providers/service_provider.dart';
import '../../data/models/sales_return_dto.dart';
import '../../data/services/sales_invoice_api_service.dart';
import '../providers/sales_invoice_provider.dart';
import '../providers/sales_return_provider.dart';

class ReturnItemEntry {
  final String id;
  final String productId;
  final String serviceId;
  final String name;
  final String hsnSac;
  double quantity;
  final double maxQuantity;
  final String unit;
  double rate;
  double discountPercentage;
  double discountAmount;
  double gstRate;
  String reason;

  ReturnItemEntry({
    required this.id,
    required this.productId,
    required this.serviceId,
    required this.name,
    required this.hsnSac,
    required this.quantity,
    this.maxQuantity = double.infinity,
    required this.unit,
    required this.rate,
    this.discountPercentage = 0.0,
    this.discountAmount = 0.0,
    required this.gstRate,
    this.reason = 'Damaged / Defective',
  });

  bool get isProduct => productId.isNotEmpty;
  bool get isService => serviceId.isNotEmpty;
}

class SaleReturnCreatePage extends ConsumerStatefulWidget {
  final String originalInvoiceId;
  const SaleReturnCreatePage({super.key, this.originalInvoiceId = ''});

  @override
  ConsumerState<SaleReturnCreatePage> createState() =>
      _SaleReturnCreatePageState();
}

class _SaleReturnCreatePageState extends ConsumerState<SaleReturnCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _creditNoteNumberController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _placeOfSupplyController = TextEditingController();
  final _termsController = TextEditingController(
    text:
        '1. Credit note issued for returned goods.\n2. Amount will be credited to customer balance or refunded.',
  );
  final _notesController = TextEditingController();

  DateTime _returnDate = DateTime.now();
  Customer? _selectedCustomer;
  Invoice? _selectedInvoice;
  String _selectedWarehouseId = '';
  String _refundMode = 'Credit Note (Store Credit)';
  String _overallReason = 'Defective / Damaged Goods';

  final List<ReturnItemEntry> _items = [];

  // For adding a custom item
  Product? _manualProduct;
  Service? _manualService;
  final _manualQuantityController = TextEditingController(text: '1');
  final _manualRateController = TextEditingController(text: '0.0');
  String _manualReason = 'Customer Changed Mind';

  final List<String> _returnReasons = const [
    'Defective / Damaged Goods',
    'Expired Product',
    'Wrong Item Delivered',
    'Quality Not Satisfactory',
    'Customer Changed Mind',
    'Order Cancelled After Dispatch',
    'Price Discrepancy',
    'Other Reason',
  ];

  final List<String> _refundModes = const [
    'Credit Note (Store Credit)',
    'Cash Refund',
    'Bank Transfer / NEFT',
    'UPI Refund',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initForm());
  }

  void _initForm() async {
    ref.read(customerProvider.notifier).loadCustomers();
    ref.read(purchaseProvider.notifier).loadProducts();
    ref.read(productListingProvider.notifier).loadProducts();
    ref.read(serviceProvider.notifier).loadServices();
    ref.read(goodsWarehouseProvider.notifier).loadData();
    await ref.read(salesInvoiceNotifierProvider.notifier).refreshInvoices();

    final biz = ref.read(businessProvider).activeBusiness;
    if (mounted && biz != null && _placeOfSupplyController.text.isEmpty) {
      _placeOfSupplyController.text = biz.state;
    }

    try {
      final backendNumber =
          await ref.read(salesReturnNotifierProvider.notifier).fetchNextNumber();
      if (mounted && backendNumber.isNotEmpty) {
        _creditNoteNumberController.text = backendNumber;
      }
    } catch (_) {}

    if (!mounted) return;
    final warehouses = ref.read(goodsWarehouseProvider).warehouses;
    if (_selectedWarehouseId.isEmpty && warehouses.isNotEmpty) {
      final preferred = warehouses.where((w) => w.isDefault && w.isActive);
      setState(() {
        _selectedWarehouseId = preferred.isNotEmpty
            ? preferred.first.id
            : warehouses.first.id;
      });
    }

    if (widget.originalInvoiceId.isNotEmpty) {
      await _loadOriginalInvoice(widget.originalInvoiceId);
    }
  }

  Future<void> _loadOriginalInvoice(String invoiceId) async {
    Invoice? invoice;
    final local = ref.read(billingRepositoryProvider).invoices.cast<Invoice?>().firstWhere(
      (inv) =>
          inv != null &&
          !inv.isCreditNote &&
          (inv.id == invoiceId ||
              inv.invoiceNumber.toLowerCase() == invoiceId.toLowerCase()),
      orElse: () => null,
    );
    invoice = local;

    if (invoice == null || invoice.items.isEmpty) {
      try {
        final dto = await ref
            .read(salesInvoiceApiServiceProvider)
            .getInvoiceById(invoiceId);
        invoice = dto.toInvoice();
      } catch (_) {
        final listed = ref.read(salesInvoiceNotifierProvider).invoices;
        final match = listed.where(
          (d) =>
              d.id == invoiceId ||
              d.invoiceNumber.toLowerCase() == invoiceId.toLowerCase(),
        );
        if (match.isNotEmpty) invoice = match.first.toInvoice();
      }
    }

    if (invoice != null && mounted) {
      _onInvoiceSelected(invoice);
    }
  }

  @override
  void dispose() {
    _creditNoteNumberController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    _placeOfSupplyController.dispose();
    _termsController.dispose();
    _notesController.dispose();
    _manualQuantityController.dispose();
    _manualRateController.dispose();
    super.dispose();
  }

  void _onCustomerSelected(Customer? customer) {
    if (customer == null) return;
    setState(() {
      _selectedCustomer = customer;
      _selectedInvoice = null;
      _billingAddressController.text = customer.billingAddress;
      _shippingAddressController.text = customer.shippingAddress;
      _placeOfSupplyController.text = customer.state;
      _items.clear();
    });
  }

  void _onInvoiceSelected(Invoice? invoice) {
    if (invoice == null) {
      setState(() {
        _selectedInvoice = null;
        _items.clear();
      });
      return;
    }

    final customers = [
      ...ref.read(customerProvider).customers,
      ...ref.read(billingRepositoryProvider).customers,
    ];
    final customer = customers.cast<Customer?>().firstWhere(
      (c) => c != null && c.id == invoice.customerId,
      orElse: () => Customer(
        id: invoice.customerId,
        name: invoice.customerName,
        type: 'Retail',
        gstin: '',
        pan: '',
        mobile: '',
        email: '',
        billingAddress: invoice.billingAddress,
        shippingAddress: invoice.shippingAddress,
        state: invoice.placeOfSupply,
        stateCode: '27',
        creditLimit: 0,
        creditPeriod: 0,
        openingBalance: 0,
        currentBalance: 0,
        customerGroup: '',
        notes: '',
        isRegistered: false,
      ),
    );

    setState(() {
      _selectedInvoice = invoice;
      _selectedCustomer = customer;
      _billingAddressController.text = invoice.billingAddress;
      _shippingAddressController.text = invoice.shippingAddress;
      _placeOfSupplyController.text = invoice.placeOfSupply;
      _selectedWarehouseId = invoice.warehouseId.isNotEmpty
          ? invoice.warehouseId
          : _selectedWarehouseId;

      _items.clear();
      for (var item in invoice.items) {
        _items.add(
          ReturnItemEntry(
            id: 'ret_item_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
            productId: item.productId,
            serviceId: item.serviceId,
            name: item.name,
            hsnSac: item.hsnSac,
            quantity: item.quantity,
            maxQuantity: item.quantity,
            unit: item.unit,
            rate: item.rate,
            discountPercentage: item.discountPercentage,
            discountAmount: item.discountAmount,
            gstRate: item.gstRate,
            reason: _overallReason,
          ),
        );
      }
    });
  }

  void _addManualItem() {
    if (_manualProduct == null && _manualService == null) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please select a product or service!',
        isError: true,
      );
      return;
    }

    if (_manualProduct != null && !isListedSellableProduct(_manualProduct!)) {
      AppFeedback.showSnackbar(
        context,
        message: kProductNotListedSaleMessage,
        isError: true,
      );
      return;
    }

    final double qty = double.tryParse(_manualQuantityController.text) ?? 1.0;
    final double rate = double.tryParse(_manualRateController.text) ?? 0.0;

    if (qty <= 0) {
      AppFeedback.showSnackbar(
        context,
        message: 'Return quantity must be greater than 0!',
        isError: true,
      );
      return;
    }

    final item = ReturnItemEntry(
      id: 'ret_item_${DateTime.now().millisecondsSinceEpoch}',
      productId: _manualProduct?.id ?? '',
      serviceId: _manualService?.id ?? '',
      name: _manualProduct?.name ?? _manualService!.name,
      hsnSac: _manualProduct?.hsnCode ?? _manualService!.sacCode,
      quantity: qty,
      unit: _manualProduct?.primaryUnit ?? _manualService!.unit,
      rate: rate,
      gstRate: _manualProduct != null
          ? _manualProduct!.gstRate
          : _manualService!.gstRate,
      reason: _manualReason,
    );

    setState(() {
      _items.add(item);
      _manualProduct = null;
      _manualService = null;
      _manualQuantityController.text = '1';
      _manualRateController.text = '0.0';
    });
  }

  List<T> _uniqueById<T>(
    Iterable<T> items,
    String Function(T item) idOf,
  ) {
    final map = <String, T>{};
    for (final item in items) {
      final id = idOf(item);
      if (id.isNotEmpty) map[id] = item;
    }
    return map.values.toList();
  }

  void _saveReturn(InvoiceStatus status) async {
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
        message: 'Please add at least one returned item!',
        isError: true,
      );
      return;
    }

    for (var item in _items) {
      if (item.quantity <= 0) {
        AppFeedback.showSnackbar(
          context,
          message: 'Return quantity for ${item.name} must be greater than 0!',
          isError: true,
        );
        return;
      }
      if (item.quantity > item.maxQuantity) {
        AppFeedback.showSnackbar(
          context,
          message:
              'Return quantity for ${item.name} cannot exceed original invoiced quantity (${item.maxQuantity})!',
          isError: true,
        );
        return;
      }
    }

    if (_formKey.currentState!.validate()) {
      final warehouses = [
        ...ref.read(goodsWarehouseProvider).domainWarehouses,
        ...ref.read(billingRepositoryProvider).warehouses,
      ];
      if (warehouses.isNotEmpty &&
          !warehouses.any((w) => w.id == _selectedWarehouseId)) {
        _selectedWarehouseId = warehouses.first.id;
      }

      final businessStateCode =
          ref.read(businessProvider).activeBusiness?.stateCode ?? '27';
      final customerStateCode = _selectedCustomer?.stateCode ?? '27';
      final custGstType = _selectedCustomer?.isRegistered == true
          ? 'Regular'
          : 'Unregistered';

      final List<InvoiceItem> invoiceItems = [];
      double subTotal = 0;
      double totalCgst = 0;
      double totalSgst = 0;
      double totalIgst = 0;
      double totalCess = 0;

      for (var entry in _items) {
        final taxRes = GstCalculationService.calculate(
          quantity: entry.quantity,
          rate: entry.rate,
          discountPercentage: entry.discountPercentage,
          gstRate: entry.gstRate,
          businessStateCode: businessStateCode,
          placeOfSupplyStateCode: customerStateCode,
          customerGstType: custGstType,
        );

        subTotal += taxRes.taxableValue;
        totalCgst += taxRes.cgstAmount;
        totalSgst += taxRes.sgstAmount;
        totalIgst += taxRes.igstAmount;
        totalCess += taxRes.cessAmount;

        invoiceItems.add(
          InvoiceItem(
            id: entry.id,
            productId: entry.productId,
            serviceId: entry.serviceId,
            name: entry.name,
            hsnSac: entry.hsnSac,
            quantity: entry.quantity,
            unit: entry.unit,
            rate: entry.rate,
            discountPercentage: entry.discountPercentage,
            discountAmount: entry.discountAmount,
            taxableValue: taxRes.taxableValue,
            gstRate: entry.gstRate,
            cgst: taxRes.cgstAmount,
            sgst: taxRes.sgstAmount,
            igst: taxRes.igstAmount,
            cess: taxRes.cessAmount,
          ),
        );
      }

      final double totalTax = totalCgst + totalSgst + totalIgst + totalCess;
      final double grossGrand = subTotal + totalTax;
      final double roundedGrand = grossGrand.roundToDouble();
      final double roundOff = double.parse(
        (roundedGrand - grossGrand).toStringAsFixed(2),
      );

      final returnInvoice = Invoice(
        id: 'ret_${DateTime.now().millisecondsSinceEpoch}',
        invoiceNumber: _creditNoteNumberController.text.trim(),
        invoiceDate: _returnDate,
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        billingAddress: _billingAddressController.text.trim(),
        shippingAddress: _shippingAddressController.text.trim(),
        placeOfSupply: _placeOfSupplyController.text.trim(),
        items: invoiceItems,
        taxableAmount: double.parse(subTotal.toStringAsFixed(2)),
        cgst: double.parse(totalCgst.toStringAsFixed(2)),
        sgst: double.parse(totalSgst.toStringAsFixed(2)),
        igst: double.parse(totalIgst.toStringAsFixed(2)),
        cess: double.parse(totalCess.toStringAsFixed(2)),
        roundOff: roundOff,
        grandTotal: roundedGrand,
        balanceAmount: 0.0,
        paymentMode: _refundMode,
        status: status,
        notes: _notesController.text.trim().isNotEmpty
            ? '${_notesController.text.trim()} (Reason: $_overallReason)'
            : 'Reason: $_overallReason',
        termsConditions: _termsController.text.trim(),
        originalInvoiceId: _selectedInvoice?.id ?? '',
        warehouseId: _selectedWarehouseId,
        isCreditNote: true,
      );

      SalesReturnDto? created;
      try {
        final backendPayload = <String, dynamic>{
          'returnNumber': returnInvoice.invoiceNumber,
          'returnDate': returnInvoice.invoiceDate.toIso8601String(),
          if (_selectedInvoice != null) 'invoiceId': _selectedInvoice!.id,
          if (_selectedCustomer != null) 'customerId': _selectedCustomer!.id,
          'customerName': returnInvoice.customerName,
          'customerPhone': _selectedCustomer?.mobile,
          'billingAddress': returnInvoice.billingAddress,
          'shippingAddress': returnInvoice.shippingAddress,
          'placeOfSupply': returnInvoice.placeOfSupply,
          'status': status == InvoiceStatus.confirmed ? 'CONFIRMED' : 'DRAFT',
          'reason': _overallReason,
          'refundMode': returnInvoice.paymentMode,
          if (_selectedWarehouseId.isNotEmpty)
            'warehouseId': _selectedWarehouseId,
          'subtotal': returnInvoice.taxableAmount,
          'taxableValue': returnInvoice.taxableAmount,
          'cgstAmount': returnInvoice.cgst,
          'sgstAmount': returnInvoice.sgst,
          'igstAmount': returnInvoice.igst,
          'cessAmount': returnInvoice.cess,
          'roundOff': returnInvoice.roundOff,
          'totalAmount': returnInvoice.grandTotal,
          'grandTotal': returnInvoice.grandTotal,
          'items': _items
              .map(
                (it) => {
                  if (it.productId.isNotEmpty) 'productId': it.productId,
                  if (it.serviceId.isNotEmpty) 'serviceId': it.serviceId,
                  'productName': it.name,
                  'hsnSac': it.hsnSac,
                  'quantity': it.quantity,
                  'unit': it.unit,
                  'rate': it.rate,
                  'discountPercentage': it.discountPercentage,
                  'discountAmount': it.discountAmount,
                  'gstRatePercent': it.gstRate,
                  'reason': it.reason,
                },
              )
              .toList(),
          'notes': returnInvoice.notes,
          'termsConditions': returnInvoice.termsConditions,
        };
        created = await ref
            .read(salesReturnNotifierProvider.notifier)
            .createReturn(backendPayload);
      } catch (e) {
        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: e.toString().replaceAll('Exception:', '').trim(),
            isError: true,
          );
        }
      }

      final savedInvoice = created?.toInvoice() ?? returnInvoice;
      await ref.read(billingRepositoryProvider.notifier).addInvoice(savedInvoice);

      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: status == InvoiceStatus.confirmed
              ? 'Sale return processed & inventory restocked successfully!'
              : 'Sale return draft saved successfully!',
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
    final serviceState = ref.watch(serviceProvider);
    final warehouseState = ref.watch(goodsWarehouseProvider);
    final invoiceState = ref.watch(salesInvoiceNotifierProvider);
    ref.watch(productListingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final availableCustomers = _uniqueById<Customer>(
      [...customerState.customers, ...billingState.customers],
      (c) => c.id,
    )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final availableProducts = _uniqueById<Product>(
      [...purchaseState.products, ...billingState.products],
      (p) => p.id,
    ).where(isListedSellableProduct).toList();
    final availableServices = _uniqueById<Service>(
      [...serviceState.services, ...billingState.services],
      (s) => s.id,
    );
    final availableWarehouses = _uniqueById(
      [
        ...warehouseState.domainWarehouses,
        ...billingState.warehouses,
      ],
      (w) => w.id,
    );

    final liveInvoices = invoiceState.invoices.map((d) => d.toInvoice());
    final eligibleInvoices = _uniqueById<Invoice>(
      [
        ...liveInvoices,
        ...billingState.invoices,
      ].where((inv) {
        if (inv.isCreditNote) return false;
        if (_selectedCustomer != null &&
            inv.customerId != _selectedCustomer!.id) {
          return false;
        }
        return inv.status != InvoiceStatus.cancelled;
      }),
      (inv) => inv.id,
    );

    final selectedCustomerId =
        (_selectedCustomer != null &&
            availableCustomers.any((c) => c.id == _selectedCustomer!.id))
        ? _selectedCustomer!.id
        : null;

    final selectedInvoiceId =
        (_selectedInvoice != null &&
            eligibleInvoices.any((inv) => inv.id == _selectedInvoice!.id))
        ? _selectedInvoice!.id
        : null;

    final selectedWarehouseId =
        availableWarehouses.any((w) => w.id == _selectedWarehouseId)
        ? _selectedWarehouseId
        : (availableWarehouses.isNotEmpty ? availableWarehouses.first.id : null);

    final selectedProductId =
        (_manualProduct != null &&
            availableProducts.any((p) => p.id == _manualProduct!.id))
        ? _manualProduct!.id
        : null;
    final selectedServiceId =
        (_manualService != null &&
            availableServices.any((s) => s.id == _manualService!.id))
        ? _manualService!.id
        : null;
    final selectedManualReason = _returnReasons.contains(_manualReason)
        ? _manualReason
        : _returnReasons.first;

    // Real-time calculations for preview
    final businessStateCode =
        ref.watch(businessProvider).activeBusiness?.stateCode ?? '27';
    final customerStateCode = _selectedCustomer?.stateCode ?? '27';
    final custGstType = _selectedCustomer?.isRegistered == true
        ? 'Regular'
        : 'Unregistered';

    double subTotal = 0;
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;
    double totalCess = 0;

    for (var entry in _items) {
      final taxRes = GstCalculationService.calculate(
        quantity: entry.quantity,
        rate: entry.rate,
        discountPercentage: entry.discountPercentage,
        gstRate: entry.gstRate,
        businessStateCode: businessStateCode,
        placeOfSupplyStateCode: customerStateCode,
        customerGstType: custGstType,
      );
      subTotal += taxRes.taxableValue;
      totalCgst += taxRes.cgstAmount;
      totalSgst += taxRes.sgstAmount;
      totalIgst += taxRes.igstAmount;
      totalCess += taxRes.cessAmount;
    }

    final double totalTax = totalCgst + totalSgst + totalIgst + totalCess;
    final double grossGrand = subTotal + totalTax;
    final double roundedGrand = grossGrand.roundToDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Sale Return (Credit Note)'),
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
                title: 'New Sale Return',
                description:
                    'Issue a Credit Note, restock returned inventory items, and adjust customer accounts.',
                breadcrumbs: const [
                  'Dashboard',
                  'Sales',
                  'Sale Returns',
                  'New Return',
                ],
              ),

              // Customer & Invoice Reference Card
              AppCard(
                title: '1. Return Reference & Customer Details',
                child: Column(
                  children: [
                    ResponsiveRow(
                      children: [
                        Expanded(
                          child: customerState.isLoading &&
                                  availableCustomers.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  child: LinearProgressIndicator(),
                                )
                              : availableCustomers.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceDark
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : const Color(0xFFCBD5E1),
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
                                          'No customers found. Add a customer to continue.',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        icon: const Icon(
                                          Icons.person_add_alt_1_outlined,
                                          size: 14,
                                        ),
                                        label: const Text(
                                          'Add Customer',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        onPressed: () =>
                                            context.push('/customers/new'),
                                      ),
                                    ],
                                  ),
                                )
                              : AppDropdownField<String>(
                                  label: 'Customer *',
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
                                    final customer = availableCustomers
                                        .firstWhere((c) => c.id == id);
                                    _onCustomerSelected(customer);
                                  },
                                ),
                        ),
                        Expanded(
                          child: AppDropdownField<String?>(
                            label: 'Link Original Invoice (Optional)',
                            value: selectedInvoiceId,
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'Direct Return (No Linked Invoice)',
                                ),
                              ),
                              ...eligibleInvoices.map((inv) {
                                return DropdownMenuItem<String?>(
                                  value: inv.id,
                                  child: Text(
                                    '${inv.invoiceNumber} • ₹${inv.grandTotal.toStringAsFixed(2)} (${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (id) {
                              if (id == null) {
                                _onInvoiceSelected(null);
                                return;
                              }
                              _loadOriginalInvoice(id);
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
                            label: 'Credit Note / Return Number *',
                            controller: _creditNoteNumberController,
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _returnDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) setState(() => _returnDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Return Date *',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(
                                '${_returnDate.day}/${_returnDate.month}/${_returnDate.year}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ResponsiveRow(
                      children: [
                        Expanded(
                          child: AppDropdownField<String>(
                            label: 'Primary Return Reason',
                            value: _overallReason,
                            items: _returnReasons
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (r) {
                              if (r != null) {
                                setState(() {
                                  _overallReason = r;
                                  for (var item in _items) {
                                    item.reason = r;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: AppDropdownField<String>(
                            label: 'Restock Godown / Warehouse *',
                            value: selectedWarehouseId,
                            items: availableWarehouses.map((w) {
                              return DropdownMenuItem(
                                value: w.id,
                                child: Text('${w.name} (${w.code})'),
                              );
                            }).toList(),
                            onChanged: (w) => setState(
                              () => _selectedWarehouseId =
                                  w ??
                                  (availableWarehouses.isNotEmpty
                                      ? availableWarehouses.first.id
                                      : ''),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                            label: 'Place of Supply State *',
                            controller: _placeOfSupplyController,
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Items to Return Card
              AppCard(
                title: '2. Returned Items & Quantity Breakdown',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFB2DFDB),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add return item',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                                    ...availableProducts.map(
                                      (p) => DropdownMenuItem<String?>(
                                        value: p.id,
                                        child: Text(
                                          '${p.name} (₹${p.sellingPrice})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (id) {
                                    setState(() {
                                      _manualProduct = id == null
                                          ? null
                                          : availableProducts.firstWhere(
                                              (p) => p.id == id,
                                            );
                                      if (_manualProduct != null) {
                                        _manualService = null;
                                        _manualRateController.text =
                                            _manualProduct!.sellingPrice
                                                .toString();
                                      }
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: AppDropdownField<String?>(
                                  label: 'Or Select Service',
                                  value: selectedServiceId,
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text('None'),
                                    ),
                                    ...availableServices.map(
                                      (s) => DropdownMenuItem<String?>(
                                        value: s.id,
                                        child: Text(
                                          '${s.name} (₹${s.rate})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (id) {
                                    setState(() {
                                      _manualService = id == null
                                          ? null
                                          : availableServices.firstWhere(
                                              (s) => s.id == id,
                                            );
                                      if (_manualService != null) {
                                        _manualProduct = null;
                                        _manualRateController.text =
                                            _manualService!.rate.toString();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ResponsiveRow(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Return Qty',
                                  controller: _manualQuantityController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              Expanded(
                                child: AppTextField(
                                  label: 'Rate / Unit (₹)',
                                  controller: _manualRateController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              Expanded(
                                child: AppDropdownField<String>(
                                  label: 'Item Return Reason',
                                  value: selectedManualReason,
                                  items: _returnReasons
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r,
                                          child: Text(r),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (r) => setState(
                                    () => _manualReason =
                                        r ?? _returnReasons.first,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00897B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Item'),
                                  onPressed: _addManualItem,
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
                    if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_return_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedInvoice != null
                                  ? 'No items found in selected invoice. Add items above.'
                                  : 'Select an invoice to auto-fill items, or add products/services above.',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 24),
                        itemBuilder: (ctx, index) {
                          final item = _items[index];
                          final itemReason =
                              _returnReasons.contains(item.reason)
                              ? item.reason
                              : _returnReasons.first;
                          final itemTotal =
                              (item.quantity * item.rate) *
                              (1 + (item.gstRate / 100));

                          return Container(
                            key: ValueKey(item.id),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'HSN/SAC: ${item.hsnSac} • GST: ${item.gstRate.toStringAsFixed(0)}% • Unit: ${item.unit}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (item.maxQuantity !=
                                              double.infinity)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 2,
                                              ),
                                              child: Text(
                                                'Invoiced Qty: ${item.maxQuantity} ${item.unit}',
                                                style: const TextStyle(
                                                  color: Color(0xFF00897B),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      tooltip: 'Remove Item',
                                      onPressed: () => setState(
                                        () => _items.removeAt(index),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ResponsiveRow(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              if (item.quantity > 1) {
                                                setState(
                                                  () => item.quantity -= 1,
                                                );
                                              }
                                            },
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              key: ValueKey('${item.id}_qty'),
                                              initialValue: item.quantity
                                                  .toString(),
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              decoration:
                                                  const InputDecoration(
                                                    labelText: 'Return Qty',
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 8,
                                                        ),
                                                  ),
                                              onChanged: (val) {
                                                final q =
                                                    double.tryParse(val) ??
                                                    1.0;
                                                setState(
                                                  () => item.quantity = q,
                                                );
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              if (item.quantity <
                                                  item.maxQuantity) {
                                                setState(
                                                  () => item.quantity += 1,
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        key: ValueKey('${item.id}_rate'),
                                        initialValue: item.rate.toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Rate / Unit (₹)',
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          final r =
                                              double.tryParse(val) ?? item.rate;
                                          setState(() => item.rate = r);
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: AppDropdownField<String>(
                                        label: 'Item Reason',
                                        value: itemReason,
                                        items: _returnReasons
                                            .map(
                                              (r) => DropdownMenuItem(
                                                value: r,
                                                child: Text(
                                                  r,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (r) => setState(
                                          () =>
                                              item.reason = r ?? item.reason,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      alignment: Alignment.centerRight,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Item Total',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '₹${itemTotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF00897B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Settlement & Summary Card
              ResponsiveRow(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: AppCard(
                      title: '3. Settlement Method & Notes',
                      child: Column(
                        children: [
                          AppDropdownField<String>(
                            label: 'Refund / Credit Settlement *',
                            value: _refundMode,
                            items: _refundModes
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                            onChanged: (m) => setState(
                              () => _refundMode = m ?? _refundModes.first,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Return Notes & Justification',
                            hintText:
                                'Additional details regarding condition of goods...',
                            controller: _notesController,
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Credit Note Terms & Conditions',
                            controller: _termsController,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 2,
                    child: AppCard(
                      title: 'Credit Summary',
                      child: Column(
                        children: [
                          _buildSummaryRow(
                            'Taxable Return Value',
                            '₹${subTotal.toStringAsFixed(2)}',
                          ),
                          if (totalCgst > 0)
                            _buildSummaryRow(
                              'CGST Amount',
                              '₹${totalCgst.toStringAsFixed(2)}',
                            ),
                          if (totalSgst > 0)
                            _buildSummaryRow(
                              'SGST Amount',
                              '₹${totalSgst.toStringAsFixed(2)}',
                            ),
                          if (totalIgst > 0)
                            _buildSummaryRow(
                              'IGST Amount',
                              '₹${totalIgst.toStringAsFixed(2)}',
                            ),
                          if (totalCess > 0)
                            _buildSummaryRow(
                              'Cess',
                              '₹${totalCess.toStringAsFixed(2)}',
                            ),
                          const Divider(height: 20),
                          _buildSummaryRow(
                            'Total Tax',
                            '₹${totalTax.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF00382E)
                                  : const Color(0xFFE0F2F1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Credit Note Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '₹${roundedGrand.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF00897B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ResponsiveRow(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _saveReturn(InvoiceStatus.draft),
                                  child: const Text('Save as Draft'),
                                ),
                              ),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00897B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _saveReturn(InvoiceStatus.confirmed),
                                  child: const Text('Confirm Return'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
