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
  final _primaryUnitController = TextEditingController(text: 'Bag');
  final _secondaryUnitController = TextEditingController(text: 'Kg');
  final _purchasePriceController = TextEditingController(text: '0.0');
  final _sellingPriceController = TextEditingController(text: '0.0');
  final _mrpController = TextEditingController(text: '0.0');
  final _wholesalePriceController = TextEditingController(text: '0.0');
  final _minStockLevelController = TextEditingController(text: '10');
  final _openingStockController = TextEditingController(text: '0');
  final _batchNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  final _brandController = TextEditingController();

  double _selectedGstRate = 18.0;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.productId != null && widget.productId!.isNotEmpty;
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProductDetails());
    }
  }

  void _loadProductDetails() {
    final stateRepo = ref.read(billingRepositoryProvider);
    final prod = stateRepo.products.firstWhere((p) => p.id == widget.productId);

    _nameController.text = prod.name;
    _codeController.text = prod.code;
    _skuController.text = prod.sku;
    _barcodeController.text = prod.barcode;
    _hsnCodeController.text = prod.hsnCode;
    _primaryUnitController.text = prod.primaryUnit;
    _secondaryUnitController.text = prod.secondaryUnit;
    _purchasePriceController.text = prod.purchasePrice.toString();
    _sellingPriceController.text = prod.sellingPrice.toString();
    _mrpController.text = prod.mrp.toString();
    _wholesalePriceController.text = prod.wholesalePrice.toString();
    _minStockLevelController.text = prod.minStockLevel.toString();
    _openingStockController.text = prod.openingStock.toString();
    _batchNumberController.text = prod.batchNumber;
    _expiryDateController.text = prod.expiryDate;
    _serialNumberController.text = prod.serialNumber;
    _categoryController.text = prod.category;
    _brandController.text = prod.brand;

    setState(() {
      _selectedGstRate = prod.gstRate;
    });
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
    if (_formKey.currentState!.validate()) {
      final billingRepo = ref.read(billingRepositoryProvider.notifier);

      final openStock = double.tryParse(_openingStockController.text) ?? 0.0;

      final product = Product(
        id: _isEdit ? widget.productId! : 'prod_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        code: _codeController.text,
        sku: _skuController.text,
        barcode: _barcodeController.text,
        hsnCode: _hsnCodeController.text,
        primaryUnit: _primaryUnitController.text,
        secondaryUnit: _secondaryUnitController.text,
        gstRate: _selectedGstRate,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
        mrp: double.tryParse(_mrpController.text) ?? 0.0,
        wholesalePrice: double.tryParse(_wholesalePriceController.text) ?? 0.0,
        minStockLevel: double.tryParse(_minStockLevelController.text) ?? 0.0,
        openingStock: openStock,
        currentStock: _isEdit
            ? (ref.read(billingRepositoryProvider).products.firstWhere((p) => p.id == widget.productId).currentStock)
            : openStock,
        batchNumber: _batchNumberController.text,
        expiryDate: _expiryDateController.text,
        serialNumber: _serialNumberController.text,
        category: _categoryController.text,
        brand: _brandController.text,
      );

      if (_isEdit) {
        await billingRepo.updateProduct(product);
        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Product updated successfully!');
          context.pop();
        }
      } else {
        await billingRepo.addProduct(product);
        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Product created successfully!');
          context.pop();
        }
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
      body: SingleChildScrollView(
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
                    title: _isEdit ? 'Edit Product Item' : 'New Product Master',
                    description: 'Set stock limits, price lists, barcodes, and tax specifications.',
                    breadcrumbs: ['Dashboard', 'Products', _isEdit ? 'Edit' : 'Add'],
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Item Core details', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextField(
                          label: 'Product Name *',
                          controller: _nameController,
                          validator: (val) => val == null || val.isEmpty ? 'Product name is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Item Code / SKU *',
                                controller: _codeController,
                                validator: (val) => val == null || val.isEmpty ? 'Item code is required' : null,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Barcode',
                                controller: _barcodeController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'HSN Code *',
                                controller: _hsnCodeController,
                                validator: (val) => val == null || val.isEmpty ? 'HSN Code is required' : null,
                              ),
                            ),
                            Expanded(
                              child: AppDropdownField<double>(
                                label: 'GST Tax Rate *',
                                value: _selectedGstRate,
                                items: gstRates.map((rate) {
                                  return DropdownMenuItem(value: rate, child: Text('${rate.toStringAsFixed(0)}%'));
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedGstRate = val ?? 18.0),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.xl),
                        Text('Units & Packaging', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.lg),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Primary Unit * (e.g. Bag, Box, Pcs)',
                                controller: _primaryUnitController,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Secondary Unit (e.g. Kg, Gm, Ltr)',
                                controller: _secondaryUnitController,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.xl),
                        Text('Price Configuration (INR)', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.lg),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Purchase Price *',
                                controller: _purchasePriceController,
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid price' : null,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Selling Price *',
                                controller: _sellingPriceController,
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid price' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'MRP *',
                                controller: _mrpController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Wholesale Price',
                                controller: _wholesalePriceController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: AppSpacing.xl),
                        Text('Inventory Thresholds', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.lg),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Minimum Stock Warning Level',
                                controller: _minStockLevelController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Opening Stock Quantity',
                                controller: _openingStockController,
                                keyboardType: TextInputType.number,
                                readOnly: _isEdit,
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
                                controller: _categoryController,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Brand Name',
                                controller: _brandController,
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
                                controller: _batchNumberController,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Expiry Date (YYYY-MM-DD)',
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
                              onPressed: () => context.pop(),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            AppButton(
                              label: 'Save Item',
                              onPressed: _handleSave,
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
