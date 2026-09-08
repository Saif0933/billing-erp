import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
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
  final _searchController = TextEditingController();
  Product? _selectedProduct;
  int _selectedTab = 0;
  bool _lowStockOnly = false;

  @override
  void dispose() {
    _adjustmentQtyController.dispose();
    _reasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatCurrency(double value) => '₹${value.toStringAsFixed(2)}';

  String _movementTypeLabel(StockMovementType type) {
    switch (type) {
      case StockMovementType.openingStock:
        return 'Opening';
      case StockMovementType.purchase:
        return 'Purchase';
      case StockMovementType.sale:
        return 'Sale';
      case StockMovementType.salesReturn:
        return 'Sales Return';
      case StockMovementType.purchaseReturn:
        return 'Purchase Return';
      case StockMovementType.adjustment:
        return 'Adjustment';
    }
  }

  Color _movementTypeColor(StockMovementType type) {
    switch (type) {
      case StockMovementType.purchase:
      case StockMovementType.salesReturn:
      case StockMovementType.openingStock:
        return AppColors.success;
      case StockMovementType.sale:
      case StockMovementType.purchaseReturn:
        return AppColors.info;
      case StockMovementType.adjustment:
        return AppColors.warning;
    }
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
            final isMobile = Responsive.isMobile(context);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Record Stock Adjustment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Use a positive quantity to add stock and a negative quantity to reduce it.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : AppColors.textLightSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppDropdownField<Product>(
                      label: 'Product Item *',
                      value: _selectedProduct,
                      items: products.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} (Current: ${_formatQty(p.currentStock)})',
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

  Widget _buildMetricCard({
    required bool isDark,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final titleColor = isDark
        ? AppColors.textDarkMuted
        : AppColors.textLightMuted;
    final valueColor = isDark
        ? AppColors.textDarkPrimary
        : AppColors.textLightPrimary;
    final subtitleColor = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textLightSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: valueColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: subtitleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs(bool isDark) {
    final tabs = [
      ('Stock Summary', Icons.inventory_2_outlined),
      ('Stock Ledger', Icons.receipt_long_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTab == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _selectedTab = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark ? AppColors.surfaceDark : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabs[index].$2,
                      size: 16,
                      color: selected
                          ? AppColors.accentDark
                          : (isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textLightMuted),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tabs[index].$1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected
                              ? (isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textLightPrimary)
                              : (isDark
                                  ? AppColors.textDarkMuted
                                  : AppColors.textLightSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductMobileCard(Product p, bool isDark) {
    final isLow = p.currentStock <= p.minStockLevel;
    final stockColor = isLow ? AppColors.error : AppColors.success;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(
                  label: isLow ? 'Low stock' : 'Healthy',
                  color: stockColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${p.code}  ·  ${p.sku}',
              style: AppTypography.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textDarkMuted
                    : AppColors.textLightMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Stock: ${_formatQty(p.currentStock)} ${p.primaryUnit}',
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: stockColor,
                    ),
                  ),
                ),
                Text(
                  _formatCurrency(p.currentStock * p.purchasePrice),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementMobileCard(StockMovement m, bool isDark) {
    final inbound = m.quantity >= 0;
    final qtyColor = inbound ? AppColors.success : AppColors.error;
    final typeColor = _movementTypeColor(m.type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.productName,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(
                  label: _movementTypeLabel(m.type),
                  color: typeColor,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${m.date.day}/${m.date.month}/${m.date.year}',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    m.referenceNumber,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  inbound ? '+${_formatQty(m.quantity)}' : _formatQty(m.quantity),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: qtyColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final allProducts = billingState.products;

    final lowStockItems = allProducts
        .where((p) => p.currentStock <= p.minStockLevel)
        .toList();

    final double stockValuation = allProducts.fold(
      0.0,
      (sum, p) => sum + (p.currentStock * p.purchasePrice),
    );

    final movements = List<StockMovement>.from(billingState.stockMovements)
      ..sort((a, b) => b.date.compareTo(a.date));

    final query = _searchController.text.trim().toLowerCase();
    final filteredProducts = allProducts.where((p) {
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.code.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query);
      final matchesStock = !_lowStockOnly || p.currentStock <= p.minStockLevel;
      return matchesQuery && matchesStock;
    }).toList();

    final filteredMovements = movements.where((m) {
      return query.isEmpty ||
          m.productName.toLowerCase().contains(query) ||
          m.referenceNumber.toLowerCase().contains(query);
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final metricCards = [
      _buildMetricCard(
        isDark: isDark,
        title: 'Total Stock Valuation',
        value: _formatCurrency(stockValuation),
        subtitle: 'Based on purchase prices',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.success,
      ),
      _buildMetricCard(
        isDark: isDark,
        title: 'Unique Product Items',
        value: '${allProducts.length}',
        subtitle: 'Active products in directory',
        icon: Icons.inventory_2_outlined,
        color: AppColors.info,
      ),
      _buildMetricCard(
        isDark: isDark,
        title: 'Low Stock Alerts',
        value: '${lowStockItems.length}',
        subtitle: lowStockItems.isNotEmpty
            ? 'Requires replenishment'
            : 'Stock levels are healthy',
        icon: Icons.warning_amber_rounded,
        color: lowStockItems.isNotEmpty ? AppColors.error : AppColors.success,
      ),
    ];

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            isMobile ? AppSpacing.pagePaddingMobile : AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: 'Stock Valuation',
                description:
                    'Monitor item balances, purchase-based value, and stock ledger movements.',
                breadcrumbs: const [
                  'Dashboard',
                  'Inventory Control',
                  'Stock Valuation',
                ],
                actions: [
                  AppButton(
                    label: 'Manual Adjustment',
                    icon: Icons.tune_outlined,
                    type: AppButtonType.primary,
                    onPressed: () =>
                        _showStockAdjustmentDialog(context, allProducts),
                  ),
                ],
              ),
              if (isMobile)
                Column(
                  children: [
                    for (int i = 0; i < metricCards.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpacing.sm),
                      metricCards[i],
                    ],
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < metricCards.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.md),
                      Expanded(child: metricCards[i]),
                    ],
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSegmentedTabs(isDark),
                    const SizedBox(height: AppSpacing.md),
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            label: 'Search',
                            hintText: _selectedTab == 0
                                ? 'Search by name, code or SKU'
                                : 'Search by product or reference',
                            controller: _searchController,
                            prefixIcon: const Icon(Icons.search, size: 20),
                            onChanged: (_) => setState(() {}),
                          ),
                          if (_selectedTab == 0) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FilterChip(
                                label: Text(
                                  'Low stock only (${lowStockItems.length})',
                                ),
                                selected: _lowStockOnly,
                                onSelected: (value) =>
                                    setState(() => _lowStockOnly = value),
                                selectedColor:
                                    AppColors.error.withValues(alpha: 0.14),
                                checkmarkColor: AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Search',
                              hintText: _selectedTab == 0
                                  ? 'Search by name, code or SKU'
                                  : 'Search by product or reference',
                              controller: _searchController,
                              prefixIcon: const Icon(Icons.search, size: 20),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          if (_selectedTab == 0) ...[
                            const SizedBox(width: AppSpacing.md),
                            Padding(
                              padding: const EdgeInsets.only(top: 20),
                              child: FilterChip(
                                label: Text(
                                  'Low stock only (${lowStockItems.length})',
                                ),
                                selected: _lowStockOnly,
                                onSelected: (value) =>
                                    setState(() => _lowStockOnly = value),
                                selectedColor:
                                    AppColors.error.withValues(alpha: 0.14),
                                checkmarkColor: AppColors.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                    if (_selectedTab == 0)
                      AppTable<Product>(
                        items: filteredProducts,
                        emptyMessage: query.isEmpty && !_lowStockOnly
                            ? 'No products registered.'
                            : 'No products match the current filters.',
                        mobileCardBuilder: (p) =>
                            _buildProductMobileCard(p, isDark),
                        columns: [
                          TableColumnSpec<Product>(
                            label: 'Item Name',
                            flex: 2,
                            cellBuilder: (p) => Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
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
                                Text(_formatCurrency(p.purchasePrice)),
                          ),
                          TableColumnSpec<Product>(
                            label: 'Current Stock',
                            isNumeric: true,
                            cellBuilder: (p) {
                              final isLow =
                                  p.currentStock <= p.minStockLevel;
                              return Text(
                                '${_formatQty(p.currentStock)} ${p.primaryUnit}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isLow
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              );
                            },
                          ),
                          TableColumnSpec<Product>(
                            label: 'Status',
                            cellBuilder: (p) {
                              final isLow =
                                  p.currentStock <= p.minStockLevel;
                              return _buildStatusChip(
                                label: isLow ? 'Low stock' : 'Healthy',
                                color: isLow
                                    ? AppColors.error
                                    : AppColors.success,
                              );
                            },
                          ),
                          TableColumnSpec<Product>(
                            label: 'Min Threshold',
                            isNumeric: true,
                            cellBuilder: (p) => Text(
                              '${_formatQty(p.minStockLevel)} ${p.primaryUnit}',
                            ),
                          ),
                          TableColumnSpec<Product>(
                            label: 'Stock Value (₹)',
                            isNumeric: true,
                            cellBuilder: (p) => Text(
                              _formatCurrency(
                                p.currentStock * p.purchasePrice,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      AppTable<StockMovement>(
                        items: filteredMovements,
                        emptyMessage: query.isEmpty
                            ? 'No stock transactions logged.'
                            : 'No movements match the current search.',
                        mobileCardBuilder: (m) =>
                            _buildMovementMobileCard(m, isDark),
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
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TableColumnSpec<StockMovement>(
                            label: 'Ref Code',
                            cellBuilder: (m) => Text(m.referenceNumber),
                          ),
                          TableColumnSpec<StockMovement>(
                            label: 'Movement Type',
                            cellBuilder: (m) => _buildStatusChip(
                              label: _movementTypeLabel(m.type),
                              color: _movementTypeColor(m.type),
                            ),
                          ),
                          TableColumnSpec<StockMovement>(
                            label: 'Adjustment Qty',
                            isNumeric: true,
                            cellBuilder: (m) => Text(
                              m.quantity >= 0
                                  ? '+${_formatQty(m.quantity)}'
                                  : _formatQty(m.quantity),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: m.quantity >= 0
                                    ? AppColors.success
                                    : AppColors.error,
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
        ),
      ),
    );
  }
}
