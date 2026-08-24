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
import '../../../../shared/widgets/app_table.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({super.key});

  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryFilter = 'All';
  bool _showOnlyLowStock = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final allProducts = billingState.products;

    // Get categories for filtering
    final categories = {'All', ...allProducts.map((p) => p.category).where((cat) => cat.isNotEmpty)};

    // Filter products
    final filteredProducts = allProducts.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.contains(_searchQuery);
      final matchesCategory = _selectedCategoryFilter == 'All' || p.category == _selectedCategoryFilter;
      final matchesLowStock = !_showOnlyLowStock || (p.currentStock <= p.minStockLevel);
      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.design_services_outlined),
            onPressed: () => context.push('/services'),
            tooltip: 'View Service Master',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Product Master',
              description: 'Manage physical inventory stock, HSN classification, and multiple price lists.',
              breadcrumbs: const ['Dashboard', 'Items', 'Products'],
              actions: [
                AppButton(
                  label: 'New Product',
                  icon: Icons.add_box_outlined,
                  onPressed: () => context.push('/products/new'),
                ),
              ],
            ),
            AppCard(
              child: Column(
                children: [
                  ResponsiveRow(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Search Products',
                          hintText: 'Search by product name, code, or barcode...',
                          controller: _searchController,
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      SizedBox(
                        width: Responsive.isMobile(context) ? double.infinity : 180,
                        child: AppDropdownField<String>(
                          label: 'Category',
                          value: _selectedCategoryFilter,
                          items: categories.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat == 'All' ? 'All Categories' : cat));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedCategoryFilter = val ?? 'All'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  CheckboxListTile(
                    title: const Text('Show only Low Stock Alert items'),
                    subtitle: const Text('Filters items where Current Stock <= Minimum Stock Level'),
                    value: _showOnlyLowStock,
                    onChanged: (val) => setState(() => _showOnlyLowStock = val ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTable<Product>(
                    items: filteredProducts,
                    emptyMessage: 'No products in inventory match the selected filters.',
                    columns: [
                      TableColumnSpec<Product>(
                        label: 'Product Info',
                        flex: 2,
                        cellBuilder: (p) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Code: ${p.code} | HSN: ${p.hsnCode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      TableColumnSpec<Product>(
                        label: 'Category',
                        cellBuilder: (p) => Text(p.category),
                      ),
                      TableColumnSpec<Product>(
                        label: 'Sale Price',
                        isNumeric: true,
                        cellBuilder: (p) => Text('₹${p.sellingPrice.toStringAsFixed(2)}'),
                      ),
                      TableColumnSpec<Product>(
                        label: 'Purchase Price',
                        isNumeric: true,
                        cellBuilder: (p) => Text('₹${p.purchasePrice.toStringAsFixed(2)}'),
                      ),
                      TableColumnSpec<Product>(
                        label: 'GST Rate',
                        cellBuilder: (p) => Text('${p.gstRate.toStringAsFixed(0)}%'),
                      ),
                      TableColumnSpec<Product>(
                        label: 'Stock',
                        isNumeric: true,
                        cellBuilder: (p) {
                          final isLow = p.currentStock <= p.minStockLevel;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${p.currentStock.toStringAsFixed(1)} ${p.primaryUnit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isLow ? Colors.red : Colors.green,
                                ),
                              ),
                              if (isLow)
                                const Text(
                                  'LOW STOCK',
                                  style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                            ],
                          );
                        },
                      ),
                      TableColumnSpec<Product>(
                        label: 'Actions',
                        cellBuilder: (p) => IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => context.push('/products/edit/${p.id}'),
                        ),
                      ),
                    ],
                    mobileCardBuilder: (p) {
                      final isLow = p.currentStock <= p.minStockLevel;
                      return AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(p.name, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold))),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => context.push('/products/edit/${p.id}'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Code: ${p.code} • SKU: ${p.sku} • HSN: ${p.hsnCode}'),
                            Text('Category: ${p.category} • GST: ${p.gstRate}%'),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Selling Price: ₹${p.sellingPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                    Text('Purchase Price: ₹${p.purchasePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Stock: ${p.currentStock} ${p.primaryUnit}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isLow ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    if (isLow)
                                      const Text(
                                        'LOW STOCK ALERT',
                                        style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                  ],
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
          ],
        ),
      ),
    );
  }
}
