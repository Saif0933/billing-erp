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
import '../../../supplier/presentation/providers/supplier_provider.dart';
import '../providers/purchase_provider.dart';

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
  bool _isSaving = false;
  bool _isAddingItem = false;

  // Manual entry fields for category / subcategory / product
  final _categoryController = TextEditingController();
  final _subCategoryController = TextEditingController();
  final _productNameController = TextEditingController();
  final _categoryFocusNode = FocusNode();
  final _subCategoryFocusNode = FocusNode();
  final _productFocusNode = FocusNode();

  // For item addition
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _rateController = TextEditingController(text: '0.0');
  final _discountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPurchaseNo();
      ref.read(supplierProvider.notifier).loadSuppliers();
      ref.read(purchaseProvider.notifier).loadProducts();
      ref.read(purchaseProvider.notifier).loadCategories();
      ref.read(purchaseProvider.notifier).loadPurchases();
    });
  }

  Future<void> _initPurchaseNo() async {
    final number =
        await ref.read(purchaseProvider.notifier).getNextPurchaseNumber();
    if (mounted) {
      _purchaseNumberController.text = number;
    }
  }

  @override
  void dispose() {
    _purchaseNumberController.dispose();
    _supplierInvoiceNumberController.dispose();
    _freightChargesController.dispose();
    _otherChargesController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
    _subCategoryController.dispose();
    _productNameController.dispose();
    _categoryFocusNode.dispose();
    _subCategoryFocusNode.dispose();
    _productFocusNode.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _onSupplierSelected(Supplier? s) {
    if (s == null) return;
    setState(() {
      _selectedSupplier = s;
      // Original bill list is supplier-scoped; clear stale selection
      _originalPurchaseId = '';
    });
  }

  /// Safely pick supplier instance that exists in the current dropdown items.
  Supplier? _resolveSelectedSupplier(List<Supplier> suppliers) {
    final selectedId = _selectedSupplier?.id;
    if (selectedId == null || selectedId.isEmpty) return null;
    for (final s in suppliers) {
      if (s.id == selectedId) return s;
    }
    return null;
  }

  /// Deduplicate suppliers by id to avoid Dropdown assertion failures.
  List<Supplier> _uniqueSuppliers(List<Supplier> suppliers) {
    final seen = <String>{};
    final result = <Supplier>[];
    for (final s in suppliers) {
      if (s.id.isEmpty || seen.contains(s.id)) continue;
      seen.add(s.id);
      result.add(s);
    }
    return result;
  }

  List<String> _categorySuggestions(PurchaseListState purchaseState) {
    return purchaseState.categories
        .map((c) => c.category)
        .where((c) => c.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _subCategorySuggestions(PurchaseListState purchaseState) {
    final category = _categoryController.text.trim();
    final Set<String> all = {};
    for (final node in purchaseState.categories) {
      if (category.isEmpty ||
          node.category.toLowerCase() == category.toLowerCase()) {
        all.addAll(node.subCategories.where((s) => s.trim().isNotEmpty));
      }
    }
    // Also pull from loaded products
    for (final p in purchaseState.products) {
      if (p.subCategory.trim().isEmpty) continue;
      if (category.isEmpty ||
          p.category.toLowerCase() == category.toLowerCase()) {
        all.add(p.subCategory.trim());
      }
    }
    return all.toList()..sort();
  }

  void _applySelectedProduct(Product prod) {
    setState(() {
      _selectedProduct = prod;
      _productNameController.text = prod.name;
      if (_categoryController.text.trim().isEmpty && prod.category.isNotEmpty) {
        _categoryController.text = prod.category;
      }
      if (_subCategoryController.text.trim().isEmpty &&
          prod.subCategory.isNotEmpty) {
        _subCategoryController.text = prod.subCategory;
      }
      _rateController.text = prod.purchasePrice.toString();
      _quantityController.text = '1';
    });
  }

  Future<void> _addItem() async {
    final productName = _productNameController.text.trim();
    if (productName.isEmpty && _selectedProduct == null) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please enter / select a product name!',
        isError: true,
      );
      return;
    }

    setState(() => _isAddingItem = true);
    try {
      Product? product = _selectedProduct;

      // Match typed name to an existing product if user typed manually
      if (product == null ||
          product.name.trim().toLowerCase() != productName.toLowerCase()) {
        final products = ref.read(purchaseProvider).products;
        Product? match;
        for (final p in products) {
          if (p.name.toLowerCase() == productName.toLowerCase() ||
              p.code.toLowerCase() == productName.toLowerCase()) {
            match = p;
            break;
          }
        }
        product = match;
      }

      // Create product on the fly when typed name is new
      if (product == null) {
        product = await ref.read(purchaseProvider.notifier).createProductFromPurchase(
              name: productName,
              category: _categoryController.text.trim().isEmpty
                  ? 'General'
                  : _categoryController.text.trim(),
              subCategory: _subCategoryController.text.trim().isEmpty
                  ? null
                  : _subCategoryController.text.trim(),
              purchasePrice: double.tryParse(_rateController.text) ?? 0,
              sellingPrice: double.tryParse(_rateController.text) ?? 0,
              primaryUnit: 'PCS',
            );
      }

      final double qty = double.tryParse(_quantityController.text) ?? 1.0;
      final double rate = double.tryParse(_rateController.text) ?? 0.0;
      final double disc = double.tryParse(_discountController.text) ?? 0.0;

      final double grossAmount = qty * rate;
      final double discAmt = grossAmount * (disc / 100.0);

      final businessStateCode =
          ref.read(businessProvider).activeBusiness?.stateCode ?? '27';
      final supplierStateCode = _selectedSupplier?.stateCode ?? '27';
      final gstRate = product.gstRate;

      final taxRes = GstCalculationService.calculate(
        quantity: qty,
        rate: rate,
        discountPercentage: disc,
        gstRate: gstRate,
        businessStateCode: businessStateCode,
        placeOfSupplyStateCode: supplierStateCode,
        customerGstType: 'Regular',
      );

      final item = PurchaseItem(
        id: 'pur_item_${DateTime.now().millisecondsSinceEpoch}',
        productId: product.id,
        name: product.name,
        hsnCode: product.hsnCode,
        quantity: qty,
        unit: product.primaryUnit,
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

      if (!mounted) return;
      setState(() {
        _items.add(item);
        _selectedProduct = null;
        _productNameController.clear();
        _quantityController.text = '1';
        _rateController.text = '0.0';
        _discountController.text = '0';
      });
    } catch (e) {
      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: e.toString().replaceAll('Exception:', '').trim(),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingItem = false);
    }
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

    if (_isDebitNote && _originalPurchaseId.isEmpty) {
      AppFeedback.showSnackbar(
        context,
        message: 'Please select the original purchase bill for debit note!',
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
        id: '',
        purchaseNumber: _purchaseNumberController.text.trim(),
        supplierInvoiceNumber: _supplierInvoiceNumberController.text.isNotEmpty
            ? _supplierInvoiceNumberController.text.trim()
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
        notes: _notesController.text.trim(),
        originalPurchaseId: _isDebitNote ? _originalPurchaseId : '',
      );

      setState(() => _isSaving = true);
      try {
        await ref.read(purchaseProvider.notifier).createPurchase(
              purchase,
              saveAs: status == PurchaseStatus.confirmed
                  ? PurchaseStatus.confirmed
                  : PurchaseStatus.draft,
            );

        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: status == PurchaseStatus.confirmed
                ? 'Purchase bill confirmed and stock updated!'
                : 'Purchase bill draft saved successfully!',
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: e.toString().replaceAll('Exception:', '').trim(),
            isError: true,
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseProvider);
    final supplierState = ref.watch(supplierProvider);
    final availableSuppliers = _uniqueSuppliers(supplierState.suppliers);
    final matchedSupplier = _resolveSelectedSupplier(availableSuppliers);
    // Keep local selection in sync with reloaded list instances
    if (_selectedSupplier != null && matchedSupplier == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedSupplier = null;
          _originalPurchaseId = '';
        });
      });
    } else if (matchedSupplier != null &&
        !identical(_selectedSupplier, matchedSupplier)) {
      _selectedSupplier = matchedSupplier;
    }

    final originalPurchaseOptions = purchaseState.purchases
        .where(
          (p) =>
              p.supplierId == matchedSupplier?.id &&
              p.status != PurchaseStatus.cancelled &&
              !p.isDebitNote,
        )
        .toList();
    final originalPurchaseIds =
        originalPurchaseOptions.map((p) => p.id).toSet();
    final safeOriginalPurchaseId =
        originalPurchaseIds.contains(_originalPurchaseId)
            ? _originalPurchaseId
            : null;
    if (_originalPurchaseId.isNotEmpty && safeOriginalPurchaseId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _originalPurchaseId = '');
      });
    }

    final categorySuggestions = _categorySuggestions(purchaseState);
    final subCategorySuggestions = _subCategorySuggestions(purchaseState);

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
        padding: Responsive.pagePadding(context),
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Expanded(
                                              child: supplierState.isLoading &&
                                                      availableSuppliers
                                                          .isEmpty
                                                  ? const Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        vertical: 18,
                                                      ),
                                                      child: Center(
                                                        child: SizedBox(
                                                          width: 22,
                                                          height: 22,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : availableSuppliers.isEmpty
                                                      ? Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 12,
                                                            vertical: 14,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                              0xFFF1F5F9,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                              8,
                                                            ),
                                                            border: Border.all(
                                                              color:
                                                                  const Color(
                                                                0xFFCBD5E1,
                                                              ),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'No suppliers yet. Tap + New Supplier to add one.',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Color(
                                                                0xFF475569,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : AppDropdownField<
                                                          Supplier>(
                                                          label:
                                                              'Select Supplier *',
                                                          value:
                                                              matchedSupplier,
                                                          items:
                                                              availableSuppliers
                                                                  .map((s) {
                                                            return DropdownMenuItem(
                                                              value: s,
                                                              child:
                                                                  Text(s.name),
                                                            );
                                                          }).toList(),
                                                          onChanged:
                                                              _onSupplierSelected,
                                                        ),
                                            ),
                                            const SizedBox(width: 8),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                bottom:
                                                    availableSuppliers.isEmpty &&
                                                            !supplierState
                                                                .isLoading
                                                        ? 0
                                                        : 2,
                                              ),
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: const Color(
                                                    0xFF2E7D32,
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFF2E7D32),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 14,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                  ),
                                                ),
                                                icon: const Icon(
                                                  Icons.add_business_outlined,
                                                  size: 16,
                                                ),
                                                label: const Text(
                                                  'New Supplier',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                onPressed: () async {
                                                  await context.push(
                                                    '/suppliers/new',
                                                  );
                                                  if (!mounted) return;
                                                  await ref
                                                      .read(
                                                        supplierProvider
                                                            .notifier,
                                                      )
                                                      .loadSuppliers();
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
                                  value: safeOriginalPurchaseId,
                                  items: originalPurchaseOptions.map((p) {
                                    return DropdownMenuItem(
                                      value: p.id,
                                      child: Text(
                                        '${p.purchaseNumber} (₹${p.grandTotal})',
                                      ),
                                    );
                                  }).toList(),
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
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: _PurchaseSuggestField(
                                      label: 'Category',
                                      hintText: 'Type category (e.g. Dairy)',
                                      controller: _categoryController,
                                      focusNode: _categoryFocusNode,
                                      suggestions: categorySuggestions,
                                      onChanged: (val) {
                                        setState(() {
                                          if (_selectedProduct != null &&
                                              _selectedProduct!.category
                                                      .toLowerCase() !=
                                                  val.trim().toLowerCase()) {
                                            _selectedProduct = null;
                                          }
                                        });
                                      },
                                      onSuggestionSelected: (val) {
                                        setState(() {
                                          _categoryController.text = val;
                                          _subCategoryController.clear();
                                          _selectedProduct = null;
                                          _productNameController.clear();
                                        });
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: _PurchaseSuggestField(
                                      key: ValueKey(
                                        'subcat-${_categoryController.text.trim().toLowerCase()}',
                                      ),
                                      label: 'Sub Category',
                                      hintText: 'Type sub category',
                                      controller: _subCategoryController,
                                      focusNode: _subCategoryFocusNode,
                                      suggestions: subCategorySuggestions,
                                      onChanged: (_) => setState(() {
                                        _selectedProduct = null;
                                      }),
                                      onSuggestionSelected: (val) {
                                        setState(() {
                                          _subCategoryController.text = val;
                                          _selectedProduct = null;
                                          _productNameController.clear();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              purchaseState.isLoadingProducts
                                  ? const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Center(
                                        child: SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                                    )
                                  : _buildProductSuggestField(),
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
                                      icon: _isAddingItem
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.add, size: 16),
                                      label: Text(
                                        _isAddingItem ? 'Adding...' : 'Add Item',
                                      ),
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
                                      onPressed: _isAddingItem ? null : _addItem,
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
                                onPressed: _isSaving
                                    ? null
                                    : () =>
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
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check, size: 18),
                                label: Text(
                                  _isSaving
                                      ? 'Saving...'
                                      : 'Confirm & Add Stock',
                                ),
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
                                onPressed: _isSaving
                                    ? null
                                    : () => _savePurchase(
                                          PurchaseStatus.confirmed,
                                        ),
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


  Widget _buildProductSuggestField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<Product>(
          textEditingController: _productNameController,
          focusNode: _productFocusNode,
          displayStringForOption: (p) => p.name,
          optionsBuilder: (TextEditingValue value) {
            final q = value.text.trim().toLowerCase();
            final category = _categoryController.text.trim().toLowerCase();
            final subCategory = _subCategoryController.text.trim().toLowerCase();
            final all = ref.read(purchaseProvider).products.where((p) {
              if (!p.isActive) return false;
              if (category.isNotEmpty &&
                  !p.category.toLowerCase().contains(category)) {
                return false;
              }
              if (subCategory.isNotEmpty &&
                  !p.subCategory.toLowerCase().contains(subCategory)) {
                return false;
              }
              if (q.isEmpty) return true;
              return p.name.toLowerCase().contains(q) ||
                  p.code.toLowerCase().contains(q) ||
                  p.sku.toLowerCase().contains(q) ||
                  p.barcode.toLowerCase().contains(q);
            }).take(30);
            return all;
          },
          onSelected: _applySelectedProduct,
          fieldViewBuilder: (context, textController, fieldFocusNode, onSubmit) {
            return AppTextField(
              label: 'Select Product *',
              hintText: 'Type product name / code (manual entry allowed)',
              controller: textController,
              focusNode: fieldFocusNode,
              onChanged: (val) {
                setState(() {
                  if (_selectedProduct != null &&
                      _selectedProduct!.name.toLowerCase() !=
                          val.trim().toLowerCase()) {
                    _selectedProduct = null;
                  }
                });
              },
              onFieldSubmitted: (_) => onSubmit(),
              suffixIcon: textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        textController.clear();
                        setState(() => _selectedProduct = null);
                      },
                    )
                  : const Icon(Icons.inventory_2_outlined, size: 18),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final list = options.toList();
            if (list.isEmpty) {
              final typed = _productNameController.text.trim();
              if (typed.isEmpty) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.add_circle_outline, size: 18),
                      title: Text(
                        'New product: "$typed"',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: const Text(
                        'Will be created when you tap Add Item',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              );
            }
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 220,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final p = list[index];
                      final meta = [
                        if (p.code.isNotEmpty) p.code,
                        if (p.category.isNotEmpty) p.category,
                        if (p.subCategory.isNotEmpty) p.subCategory,
                      ].join(' • ');
                      return ListTile(
                        dense: true,
                        title: Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '$meta  |  ₹${p.purchasePrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => onSelected(p),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Always shows the full suggestion list on open (not filtered by the
/// already-selected value). Typing a new name is still allowed.
class _PurchaseSuggestField extends StatefulWidget {
  const _PurchaseSuggestField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.onChanged,
    required this.onSuggestionSelected,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> suggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSuggestionSelected;

  @override
  State<_PurchaseSuggestField> createState() => _PurchaseSuggestFieldState();
}

class _PurchaseSuggestFieldState extends State<_PurchaseSuggestField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  double _fieldWidth = 280;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(_PurchaseSuggestField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
    }
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _showOverlay();
    } else {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        if (!widget.focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    if (widget.suggestions.isEmpty) {
      _removeOverlay();
      return;
    }
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final options = List<String>.from(widget.suggestions);
        if (options.isEmpty) return const SizedBox.shrink();
        return Positioned.fill(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    widget.focusNode.unfocus();
                    _removeOverlay();
                  },
                ),
              ),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 4),
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                child: TextFieldTapRegion(
                  child: Material(
                    color: panelColor,
                    elevation: 8,
                    shadowColor: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 220,
                          minWidth: _fieldWidth,
                          maxWidth: _fieldWidth,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final selected = option.toLowerCase() ==
                                widget.controller.text.trim().toLowerCase();
                            return InkWell(
                              onTap: () => _pick(option),
                              child: Container(
                                width: _fieldWidth,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                color: selected
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: selected
                                        ? AppColors.accent
                                        : (isDark
                                            ? AppColors.textDarkPrimary
                                            : AppColors.textLightPrimary),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _pick(String option) {
    widget.controller.text = option;
    widget.controller.selection = TextSelection.collapsed(
      offset: option.length,
    );
    widget.onSuggestionSelected(option);
    widget.focusNode.unfocus();
    _removeOverlay();
  }

  void _clear() {
    widget.controller.clear();
    widget.onChanged('');
    setState(() {});
    _showOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _fieldWidth = constraints.maxWidth;
        return CompositedTransformTarget(
          link: _layerLink,
          child: AppTextField(
            label: widget.label,
            hintText: widget.hintText,
            controller: widget.controller,
            focusNode: widget.focusNode,
            onTap: _showOverlay,
            onChanged: (val) {
              widget.onChanged(val);
              _showOverlay();
            },
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _clear,
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_drop_down, size: 22),
                    onPressed: () {
                      if (widget.focusNode.hasFocus) {
                        _showOverlay();
                      } else {
                        widget.focusNode.requestFocus();
                      }
                    },
                  ),
          ),
        );
      },
    );
  }
}
