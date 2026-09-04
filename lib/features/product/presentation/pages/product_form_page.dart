import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../product-listing/data/models/product_dto.dart';
import '../../../product-listing/presentation/providers/billing_cart_provider.dart';
import '../../../product-listing/presentation/providers/product_listing_provider.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  final String? productId;
  const ProductFormPage({super.key, this.productId});

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _primaryUnitController = TextEditingController(text: 'PCS');
  final _secondaryUnitController = TextEditingController();
  final _purchasePriceController = TextEditingController(text: '0.00');
  final _sellingPriceController = TextEditingController(text: '0.00');
  final _mrpController = TextEditingController(text: '0.00');
  final _wholesalePriceController = TextEditingController(text: '0.00');
  final _minStockLevelController = TextEditingController(text: '10');
  final _openingStockController = TextEditingController(text: '0');
  final _batchNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  final _brandController = TextEditingController();

  double _selectedGstRate = 18.0;
  bool _isEdit = false;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.productId != null && widget.productId!.isNotEmpty;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProductDetails());
    }
  }

  Future<void> _loadProductDetails() async {
    setState(() => _isLoading = true);
    try {
      Product? found;

      // 1. Try local billingRepository
      final stateRepo = ref.read(billingRepositoryProvider);
      found = stateRepo.products.where((p) => p.id == widget.productId).firstOrNull;

      // 2. Try fetching from backend API
      if (found == null && widget.productId != null) {
        try {
          final dto = await ref.read(productApiServiceProvider).getProductById(widget.productId!);
          found = dto.toBillingProduct();
        } catch (_) {}
      }

      if (found != null && mounted) {
        _nameController.text = found.name;
        _codeController.text = found.code;
        _skuController.text = found.sku;
        _barcodeController.text = found.barcode;
        _hsnCodeController.text = found.hsnCode;
        _primaryUnitController.text = found.primaryUnit.isNotEmpty ? found.primaryUnit : 'PCS';
        _secondaryUnitController.text = found.secondaryUnit;
        _purchasePriceController.text = found.purchasePrice.toStringAsFixed(2);
        _sellingPriceController.text = found.sellingPrice.toStringAsFixed(2);
        _mrpController.text = found.mrp.toStringAsFixed(2);
        _wholesalePriceController.text = found.wholesalePrice.toStringAsFixed(2);
        _minStockLevelController.text = found.minStockLevel.toStringAsFixed(0);
        _openingStockController.text = found.openingStock.toStringAsFixed(0);
        _batchNumberController.text = found.batchNumber;
        _expiryDateController.text = found.expiryDate;
        _serialNumberController.text = found.serialNumber;
        _categoryController.text = found.category.isNotEmpty ? found.category : 'General';
        _brandController.text = found.brand;

        setState(() {
          _selectedGstRate = found!.gstRate;
        });
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showSnackbar(
          context,
          message: 'Failed to load product details: ${e.toString().replaceAll('Exception:', '').trim()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _hsnCodeController.dispose();
    _primaryUnitController.dispose();
    _secondaryUnitController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _mrpController.dispose();
    _wholesalePriceController.dispose();
    _minStockLevelController.dispose();
    _openingStockController.dispose();
    _batchNumberController.dispose();
    _expiryDateController.dispose();
    _serialNumberController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final openStock = double.tryParse(_openingStockController.text.trim()) ?? 0.0;
    final sellPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final buyPrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final mrpPrice = double.tryParse(_mrpController.text.trim()) ?? sellPrice;
    final wholePrice = double.tryParse(_wholesalePriceController.text.trim()) ?? sellPrice;
    final minStock = double.tryParse(_minStockLevelController.text.trim()) ?? 0.0;

    final productDto = ProductDto(
      id: _isEdit ? widget.productId! : '',
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      itemCode: _codeController.text.trim(),
      sku: _skuController.text.trim(),
      barcode: _barcodeController.text.trim(),
      hsnCode: _hsnCodeController.text.trim(),
      primaryUnit: _primaryUnitController.text.trim().isNotEmpty
          ? _primaryUnitController.text.trim().toUpperCase()
          : 'PCS',
      secondaryUnit: _secondaryUnitController.text.trim(),
      unit: _primaryUnitController.text.trim().isNotEmpty
          ? _primaryUnitController.text.trim().toUpperCase()
          : 'PCS',
      gstRate: _selectedGstRate,
      gstRatePercent: _selectedGstRate,
      purchasePrice: buyPrice,
      sellingPrice: sellPrice,
      mrp: mrpPrice,
      wholesalePrice: wholePrice,
      minStockLevel: minStock,
      openingStock: openStock,
      currentStock: openStock,
      stock: openStock.round(),
      category: _categoryController.text.trim().isNotEmpty
          ? _categoryController.text.trim()
          : 'General',
      brand: _brandController.text.trim(),
    );

    try {
      final apiService = ref.read(productApiServiceProvider);
      ProductDto savedDto;

      if (_isEdit) {
        savedDto = await apiService.updateProduct(productDto);
        await ref
            .read(billingRepositoryProvider.notifier)
            .updateProduct(savedDto.toBillingProduct());
        ref
            .read(productListingProvider.notifier)
            .updateProduct(savedDto.toListingItem());

        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: 'Product "${savedDto.name}" updated successfully!',
          );
          context.pop();
        }
      } else {
        savedDto = await apiService.createProduct(productDto);
        await ref
            .read(billingRepositoryProvider.notifier)
            .addProduct(savedDto.toBillingProduct());
        ref.read(productListingProvider.notifier).loadProducts(refresh: true);

        if (mounted) {
          AppFeedback.showSnackbar(
            context,
            message: 'Product "${savedDto.name}" created successfully!',
          );
          context.pop();
        }
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppPageHeader(
                          title: _isEdit
                              ? 'Edit Product Profile'
                              : 'New Product Master',
                          description:
                              'Set pricing, barcodes, stock levels, GST tax slabs, and warehouse bins.',
                          breadcrumbs: [
                            'Dashboard',
                            'Products',
                            _isEdit ? 'Edit' : 'Add',
                          ],
                        ),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Core Identity',
                                style: AppTypography.titleLarge
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppTextField(
                                label: 'Product Name *',
                                hintText: 'e.g. Organic Wheat Flour (5kg)',
                                controller: _nameController,
                                validator: (val) => val == null ||
                                        val.trim().isEmpty
                                    ? 'Product name is required'
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Item Code',
                                      hintText: 'e.g. WHT5K (auto-generated if empty)',
                                      controller: _codeController,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'SKU (Stock Keeping Unit)',
                                      hintText: 'e.g. WHT-005',
                                      controller: _skuController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Barcode (EAN-13, UPC, Code-128)',
                                      hintText: 'e.g. 8901234567890',
                                      controller: _barcodeController,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'HSN Tax Classification Code',
                                      hintText: 'e.g. 1101, 8471 (2-8 digits)',
                                      controller: _hsnCodeController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Category',
                                      hintText: 'e.g. Groceries, Dairy, Snacks',
                                      controller: _categoryController,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Brand Name',
                                      hintText: 'e.g. Acme Organic, Parle',
                                      controller: _brandController,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: AppSpacing.xl),
                              Text(
                                'Tax & Units',
                                style: AppTypography.titleLarge
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppDropdownField<double>(
                                      label: 'GST Tax Rate *',
                                      value: _selectedGstRate,
                                      items: gstRates.map((rate) {
                                        return DropdownMenuItem(
                                          value: rate,
                                          child: Text(
                                              '${rate.toStringAsFixed(0)}% GST'),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(
                                          () => _selectedGstRate = val ?? 18.0),
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Primary Unit * (e.g. PCS, Bag, Kg, Ltr)',
                                      controller: _primaryUnitController,
                                      validator: (val) => val == null ||
                                              val.trim().isEmpty
                                          ? 'Primary unit is required'
                                          : null,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Secondary Unit (Optional)',
                                      controller: _secondaryUnitController,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: AppSpacing.xl),
                              Text(
                                'Pricing Structure',
                                style: AppTypography.titleLarge
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Purchase Price (₹)',
                                      hintText: '0.00',
                                      controller: _purchasePriceController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Selling Price (₹) *',
                                      hintText: '0.00',
                                      controller: _sellingPriceController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      validator: (val) {
                                        if (val == null ||
                                            val.trim().isEmpty) {
                                          return 'Selling price is required';
                                        }
                                        final num =
                                            double.tryParse(val.trim());
                                        if (num == null || num < 0) {
                                          return 'Invalid price';
                                        }
                                        return null;
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
                                      label: 'MRP (Maximum Retail Price ₹)',
                                      hintText: '0.00',
                                      controller: _mrpController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Wholesale Price (₹)',
                                      hintText: '0.00',
                                      controller: _wholesalePriceController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: AppSpacing.xl),
                              Text(
                                'Inventory Control & Stock',
                                style: AppTypography.titleLarge
                                    .copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Opening Stock Balance',
                                      hintText: '0',
                                      controller: _openingStockController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Minimum Low Stock Alert Level',
                                      hintText: '10',
                                      controller: _minStockLevelController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ResponsiveRow(
                                children: [
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Batch Number',
                                      hintText: 'e.g. BATCH-2026-A',
                                      controller: _batchNumberController,
                                    ),
                                  ),
                                  Expanded(
                                    child: AppTextField(
                                      label: 'Expiry Date (YYYY-MM-DD)',
                                      hintText: 'e.g. 2027-12-31',
                                      controller: _expiryDateController,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AppButton(
                                    label: 'Cancel',
                                    type: AppButtonType.text,
                                    onPressed: _isSaving
                                        ? null
                                        : () => context.pop(),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  AppButton(
                                    label: _isSaving
                                        ? 'Saving...'
                                        : (_isEdit
                                            ? 'Update Product'
                                            : 'Save Product'),
                                    icon: _isSaving
                                        ? null
                                        : (_isEdit
                                            ? Icons.save_outlined
                                            : Icons.check),
                                    onPressed:
                                        _isSaving ? null : _handleSave,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
