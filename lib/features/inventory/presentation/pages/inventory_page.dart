import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final _adjustmentQtyController = TextEditingController();
  final _reasonController = TextEditingController();
  Product? _selectedProduct;

  @override
  void dispose() {
    _adjustmentQtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _showStockAdjustmentDialog(
    BuildContext context,
    List<Product> products,
  ) {
    _adjustmentQtyController.text = '0';
    _reasonController.clear();
    _selectedProduct = null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Stock Adjustment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppDropdownField<Product>(
                      label: 'Product Item *',
                      value: _selectedProduct,
                      items: products.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} (Current: ${p.currentStock})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (p) =>
                          setDialogState(() => _selectedProduct = p),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Adjustment Quantity * (e.g. +10, -5)',
                      controller: _adjustmentQtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: 'Reason for Adjustment *',
                      controller: _reasonController,
                      hintText: 'e.g. Damaged, mismatch',
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                AppButton(
                  label: 'Save Adjustment',
                  onPressed: () async {
                    final double qty =
                        double.tryParse(_adjustmentQtyController.text) ?? 0.0;
                    if (_selectedProduct == null ||
                        qty == 0.0 ||
                        _reasonController.text.isEmpty) {
                      AppFeedback.showSnackbar(
                        context,
                        message: 'Please fill in all required fields!',
                        isError: true,
                      );
                      return;
                    }

                    await ref
                        .read(billingRepositoryProvider.notifier)
                        .adjustStock(
                          _selectedProduct!.id,
                          qty,
                          _reasonController.text,
                        );

                    if (mounted) {
                      Navigator.pop(ctx);
                      AppFeedback.showSnackbar(
                        context,
                        message: 'Stock adjusted successfully!',
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCustomMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final allProducts = billingState.products;

    // Filter low stock products
    final lowStockItems = allProducts
        .where((p) => p.currentStock <= p.minStockLevel)
        .toList();

    // Compute stock valuation: Sum of (Current Stock * Purchase Price)
    final double stockValuation = allProducts.fold(
      0.0,
      (sum, p) => sum + (p.currentStock * p.purchasePrice),
    );

    // Sort stock movements descending by date
    final movements = List<StockMovement>.from(billingState.stockMovements)
      ..sort((a, b) => b.date.compareTo(a.date));

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Inventory Master')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'Basic Inventory Management',
                description:
                    'Monitor item balances, valuation summaries, and stock ledger movements.',
                breadcrumbs: const ['Dashboard', 'Inventory', 'Stock'],
                actions: [
                  AppButton(
                    label: 'Manual Adjustment',
                    icon: Icons.tune_outlined,
                    type: AppButtonType.secondary,
                    onPressed: () =>
                        _showStockAdjustmentDialog(context, allProducts),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // KPI Stats
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: Responsive.isMobile(context) ? 1 : 3,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: Responsive.isMobile(context) ? 3.2 : 2.5,
                children: [
                  _buildCustomMetricCard(
                    context: context,
                    title: 'Total Stock Valuation',
                    value: '₹${stockValuation.toStringAsFixed(2)}',
                    subtitle: 'Computed on Purchase Prices',
                    icon: Icons.monetization_on_outlined,
                    color: const Color(0xFF2E7D32),
                  ),
                  _buildCustomMetricCard(
                    context: context,
                    title: 'Unique Product Items',
                    value: '${allProducts.length} Items',
                    subtitle: 'Active Products Directory',
                    icon: Icons.grid_view_outlined,
                    color: const Color(0xFF1976D2),
                  ),
                  _buildCustomMetricCard(
                    context: context,
                    title: 'Low Stock Alerts',
                    value: '${lowStockItems.length} Warnings',
                    subtitle: lowStockItems.isNotEmpty ? 'Requires attention' : 'Secure stock levels',
                    icon: Icons.warning_amber_rounded,
                    color: lowStockItems.isNotEmpty
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF388E3C),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // TabBar in attractive wrapper
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                ),
                child: TabBar(
                  tabs: const [
                    Tab(text: 'Stock Summary Valuation'),
                    Tab(text: 'Stock Ledger Movements'),
                  ],
                  labelColor: const Color(0xFF2E7D32),
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: const UnderlineTabIndicator(
                    borderSide: BorderSide(color: Color(0xFF2E7D32), width: 3),
                  ),
                  labelStyle: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              SizedBox(
                height: 480,
                child: TabBarView(
                  children: [
                    // Tab 1: Stock Summary
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<Product>(
                        items: allProducts,
                        emptyMessage: 'No products registered.',
                        columns: [
                          TableColumnSpec<Product>(
                            label: 'Item Name',
                            flex: 2,
                            cellBuilder: (p) => Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TableColumnSpec<Product>(
                            label: 'Code / SKU',
                            cellBuilder: (p) => Text('${p.code} (${p.sku})'),
                          ),
                          TableColumnSpec<Product>(
                            label: 'Pur Price',
                            isNumeric: true,
                            cellBuilder: (p) =>
                                Text('₹${p.purchasePrice.toStringAsFixed(2)}'),
                          ),
                          TableColumnSpec<Product>(
                            label: 'Current Stock',
                            isNumeric: true,
                            cellBuilder: (p) {
                              final isLow = p.currentStock <= p.minStockLevel;
                              return Text(
                                '${p.currentStock} ${p.primaryUnit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isLow ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
                                ),
                              );
                            },
                          ),
                          TableColumnSpec<Product>(
                            label: 'Min Threshold',
                            isNumeric: true,
                            cellBuilder: (p) =>
                                Text('${p.minStockLevel} ${p.primaryUnit}'),
                          ),
                          TableColumnSpec<Product>(
                            label: 'Stock Value (₹)',
                            isNumeric: true,
                            cellBuilder: (p) => Text(
                              '₹${(p.currentStock * p.purchasePrice).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab 2: Stock Ledger
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<StockMovement>(
                        items: movements,
                        emptyMessage: 'No stock transactions logged.',
                        columns: [
                          TableColumnSpec<StockMovement>(
                            label: 'Date',
                            cellBuilder: (m) => Text(
                              '${m.date.day}/${m.date.month}/${m.date.year}',
                            ),
                          ),
                          TableColumnSpec<StockMovement>(
                            label: 'Product Name',
                            flex: 2,
                            cellBuilder: (m) => Text(
                              m.productName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          TableColumnSpec<StockMovement>(
                            label: 'Ref Code',
                            cellBuilder: (m) => Text(m.referenceNumber),
                          ),
                          TableColumnSpec<StockMovement>(
                            label: 'Movement Type',
                            cellBuilder: (m) => Text(m.type.name.toUpperCase()),
                          ),
                          TableColumnSpec<StockMovement>(
                            label: 'Adjustment Qty',
                            isNumeric: true,
                            cellBuilder: (m) => Text(
                              m.quantity >= 0
                                  ? '+${m.quantity}'
                                  : '${m.quantity}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: m.quantity >= 0
                                    ? const Color(0xFF388E3C)
                                    : const Color(0xFFD32F2F),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
