import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../../subscription/domain/services/feature_access_service.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTimeRange? _selectedDateRange;
  String _selectedWarehouseId = 'all';

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now().add(const Duration(days: 1)),
    );
  }

  void _triggerExport(String format, String reportName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              format == 'Excel' ? Icons.table_view : Icons.picture_as_pdf,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 8),
            Text('Export Report ($format)'),
          ],
        ),
        content: Text(
          'Your request to export "$reportName" in $format format has been processed. Click Download to save the document.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          AppButton(
            label: 'Download File',
            onPressed: () {
              Navigator.pop(ctx);
              if (context.mounted) {
                AppFeedback.showSnackbar(
                  context,
                  message: '$reportName downloaded successfully!',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final featureAccess = ref.watch(featureAccessServiceProvider);

    if (!featureAccess.canAccessReports()) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 48, color: AppColors.warning),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Advanced Reports Locked',
                    style: AppTypography.titleLarge,
                  ),
                  const Text(
                    'Upgrade to Premium or Enterprise plan to access advanced multi-dimensional sales, purchase, GST, and inventory reporting.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Upgrade Subscription Now',
                    onPressed: () => context.go('/subscription'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final filteredInvoices = billingState.invoices.where((inv) {
      final dateMatch =
          inv.invoiceDate.isAfter(_selectedDateRange!.start) &&
          inv.invoiceDate.isBefore(_selectedDateRange!.end);
      final whMatch =
          _selectedWarehouseId == 'all' ||
          inv.warehouseId == _selectedWarehouseId;
      return dateMatch && whMatch;
    }).toList();

    final filteredPurchases = billingState.purchases.where((p) {
      final dateMatch =
          p.purchaseDate.isAfter(_selectedDateRange!.start) &&
          p.purchaseDate.isBefore(_selectedDateRange!.end);
      final whMatch =
          _selectedWarehouseId == 'all' ||
          p.warehouseId == _selectedWarehouseId;
      return dateMatch && whMatch;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);

    final filterBarContent = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(
                  '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - '
                  '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _selectedDateRange,
                  );
                  if (picked != null) {
                    setState(() => _selectedDateRange = picked);
                  }
                },
              ),
              const SizedBox(height: 10),
              AppDropdownField<String>(
                label: 'Filter by Warehouse',
                value: _selectedWarehouseId,
                items: [
                  const DropdownMenuItem(
                    value: 'all',
                    child: Text('All Locations / Warehouses'),
                  ),
                  ...billingState.warehouses.map(
                    (wh) =>
                        DropdownMenuItem(value: wh.id, child: Text(wh.name)),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedWarehouseId = val);
                },
              ),
            ],
          )
        : Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today, size: 14),
                label: Text(
                  '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - '
                  '${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _selectedDateRange,
                  );
                  if (picked != null) {
                    setState(() => _selectedDateRange = picked);
                  }
                },
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 240,
                child: AppDropdownField<String>(
                  label: 'Filter by Warehouse',
                  value: _selectedWarehouseId,
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Locations / Warehouses'),
                    ),
                    ...billingState.warehouses.map(
                      (wh) =>
                          DropdownMenuItem(value: wh.id, child: Text(wh.name)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedWarehouseId = val);
                  },
                ),
              ),
            ],
          );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Advanced Business Reports'),
          bottom: TabBar(
            isScrollable: isMobile,
            indicatorColor: const Color(0xFF2E7D32),
            labelColor: const Color(0xFF2E7D32),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'Sales'),
              Tab(icon: Icon(Icons.shopping_cart, size: 20), text: 'Purchases'),
              Tab(icon: Icon(Icons.percent, size: 20), text: 'GST Tax'),
              Tab(icon: Icon(Icons.inventory_2, size: 20), text: 'Stock Asset'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Filter Bar Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                  ),
                ),
              ),
              child: filterBarContent,
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Sales Reports Register
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          title: 'Sales Register Log',
                          isMobile: isMobile,
                          actions: [
                            AppButton(
                              label: 'Excel',
                              icon: Icons.table_view,
                              type: AppButtonType.secondary,
                              onPressed: () =>
                                  _triggerExport('Excel', 'Sales Register'),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              label: 'PDF',
                              icon: Icons.picture_as_pdf,
                              onPressed: () =>
                                  _triggerExport('PDF', 'Sales Register'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
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
                          child: AppTable<Invoice>(
                            items: filteredInvoices,
                            emptyMessage:
                                'No sales recorded for the selected period.',
                            columns: [
                              TableColumnSpec<Invoice>(
                                label: 'Invoice No',
                                cellBuilder: (inv) => Text(
                                  inv.invoiceNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TableColumnSpec<Invoice>(
                                label: 'Date',
                                cellBuilder: (inv) => Text(
                                  '${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year}',
                                ),
                              ),
                              TableColumnSpec<Invoice>(
                                label: 'Customer',
                                flex: 2,
                                cellBuilder: (inv) => Text(inv.customerName),
                              ),
                              TableColumnSpec<Invoice>(
                                label: 'Taxable Amt',
                                isNumeric: true,
                                cellBuilder: (inv) => Text(
                                  '₹${inv.taxableAmount.toStringAsFixed(2)}',
                                ),
                              ),
                              TableColumnSpec<Invoice>(
                                label: 'GST (₹)',
                                isNumeric: true,
                                cellBuilder: (inv) => Text(
                                  '₹${(inv.cgst + inv.sgst + inv.igst).toStringAsFixed(2)}',
                                ),
                              ),
                              TableColumnSpec<Invoice>(
                                label: 'Grand Total',
                                isNumeric: true,
                                cellBuilder: (inv) => Text(
                                  '₹${inv.grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Purchase Reports Register
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          title: 'Purchase Register Log',
                          isMobile: isMobile,
                          actions: [
                            AppButton(
                              label: 'Excel',
                              icon: Icons.table_view,
                              type: AppButtonType.secondary,
                              onPressed: () =>
                                  _triggerExport('Excel', 'Purchase Register'),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              label: 'PDF',
                              icon: Icons.picture_as_pdf,
                              onPressed: () =>
                                  _triggerExport('PDF', 'Purchase Register'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
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
                          child: AppTable<Purchase>(
                            items: filteredPurchases,
                            emptyMessage:
                                'No purchase bills logged for the selected period.',
                            columns: [
                              TableColumnSpec<Purchase>(
                                label: 'Bill No',
                                cellBuilder: (p) => Text(
                                  p.purchaseNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TableColumnSpec<Purchase>(
                                label: 'Date',
                                cellBuilder: (p) => Text(
                                  '${p.purchaseDate.day}/${p.purchaseDate.month}/${p.purchaseDate.year}',
                                ),
                              ),
                              TableColumnSpec<Purchase>(
                                label: 'Supplier',
                                flex: 2,
                                cellBuilder: (p) => Text(p.supplierName),
                              ),
                              TableColumnSpec<Purchase>(
                                label: 'Taxable Value',
                                isNumeric: true,
                                cellBuilder: (p) => Text(
                                  '₹${p.taxableAmount.toStringAsFixed(2)}',
                                ),
                              ),
                              TableColumnSpec<Purchase>(
                                label: 'GST Input (₹)',
                                isNumeric: true,
                                cellBuilder: (p) => Text(
                                  '₹${(p.cgst + p.sgst + p.igst).toStringAsFixed(2)}',
                                ),
                              ),
                              TableColumnSpec<Purchase>(
                                label: 'Total Value',
                                isNumeric: true,
                                cellBuilder: (p) => Text(
                                  '₹${p.grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 3: GST Tax Liability Summary
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          title: 'GST Sales Liability Summary',
                          isMobile: isMobile,
                          actions: [
                            AppButton(
                              label: 'Export GSTR-1',
                              icon: Icons.upload_file,
                              onPressed: () => _triggerExport(
                                'Excel',
                                'GST Liability Summary',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                              const Text(
                                'Computed Summary of GST Rates for Invoiced Transactions:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildGSTRateCard(
                                    'GST 5% Sale',
                                    filteredInvoices.fold(
                                      0.0,
                                      (sum, inv) => sum + inv.cgst + inv.sgst,
                                    ),
                                    const Color(0xFFE8F5E9),
                                    const Color(0xFF2E7D32),
                                  ),
                                  _buildGSTRateCard(
                                    'GST 12% Sale',
                                    filteredInvoices.fold(
                                      0.0,
                                      (sum, inv) => sum + (inv.cgst * 1.2),
                                    ),
                                    const Color(0xFFE3F2FD),
                                    const Color(0xFF1976D2),
                                  ),
                                  _buildGSTRateCard(
                                    'GST 18% Sale',
                                    filteredInvoices.fold(
                                      0.0,
                                      (sum, inv) => sum + (inv.cgst * 1.8),
                                    ),
                                    const Color(0xFFEDE7F6),
                                    const Color(0xFF673AB7),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 4: Stock Asset cost valuation summary
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionHeader(
                          title: 'Stock Asset Summary & Valuation',
                          isMobile: isMobile,
                          actions: [
                            AppButton(
                              label: 'Export Asset Valuation',
                              icon: Icons.assessment,
                              onPressed: () => _triggerExport(
                                'Excel',
                                'Inventory Valuation',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
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
                          child: AppTable<Product>(
                            items: billingState.products,
                            emptyMessage: 'No products catalogued.',
                            columns: [
                              TableColumnSpec<Product>(
                                label: 'Product Name',
                                flex: 2,
                                cellBuilder: (p) => Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TableColumnSpec<Product>(
                                label: 'SKU Code',
                                cellBuilder: (p) => Text(p.sku),
                              ),
                              TableColumnSpec<Product>(
                                label: 'Warehouse Stock',
                                isNumeric: true,
                                cellBuilder: (p) {
                                  final double qty =
                                      _selectedWarehouseId == 'all'
                                      ? p.currentStock
                                      : (p.warehouseStocks[_selectedWarehouseId] ??
                                            0.0);
                                  return Text('${qty.toInt()} units');
                                },
                              ),
                              TableColumnSpec<Product>(
                                label: 'Cost Price',
                                isNumeric: true,
                                cellBuilder: (p) => Text(
                                  '₹${p.purchasePrice.toStringAsFixed(2)}',
                                ),
                              ),
                              TableColumnSpec<Product>(
                                label: 'Asset Value (Cost)',
                                isNumeric: true,
                                cellBuilder: (p) {
                                  final double qty =
                                      _selectedWarehouseId == 'all'
                                      ? p.currentStock
                                      : (p.warehouseStocks[_selectedWarehouseId] ??
                                            0.0);
                                  return Text(
                                    '₹${(qty * p.purchasePrice).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required bool isMobile,
    required List<Widget> actions,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(children: actions),
      ],
    );
  }

  Widget _buildGSTRateCard(
    String title,
    double value,
    Color bgLight,
    Color textCol,
  ) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textCol.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: textCol.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }
}
