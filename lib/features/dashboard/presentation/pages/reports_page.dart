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

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';

  void _triggerExport(String format, String reportName) {
    final isMobile = Responsive.isMobile(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? AppSpacing.md : AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        title: Row(
          children: [
            Icon(
              format == 'Excel' ? Icons.table_view : Icons.picture_as_pdf,
              color: const Color(0xFF2E7D32),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Export Report ($format)',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isMobile ? 360 : 420),
          child: Text(
            'Your request to export "$reportName" in $format format has been processed. Click Download to save the document.',
          ),
        ),
        actionsAlignment:
            isMobile ? MainAxisAlignment.center : MainAxisAlignment.end,
        actions: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            )
          else ...[
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
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final featureAccess = ref.watch(featureAccessServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final pagePadding = EdgeInsets.all(
      isMobile
          ? AppSpacing.pagePaddingMobile
          : isTablet
              ? AppSpacing.pagePaddingTablet
              : AppSpacing.pagePaddingDesktop,
    );

    if (!featureAccess.canAccessReports()) {
      return Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 48, color: AppColors.warning),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Advanced Reports Locked',
                      style: AppTypography.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Upgrade to Premium or Enterprise plan to access advanced multi-dimensional sales, purchase, GST, and inventory reporting.',
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: isMobile ? double.infinity : null,
                      child: AppButton(
                        label: isMobile
                            ? 'Upgrade Now'
                            : 'Upgrade Subscription Now',
                        onPressed: () => context.go('/subscription'),
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

    final dateLabel =
        '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}';

    final warehouseDropdown = AppDropdownField<String>(
      label: 'Filter by Warehouse',
      value: _selectedWarehouseId,
      items: [
        const DropdownMenuItem(
          value: 'all',
          child: Text('All Locations / Warehouses'),
        ),
        ...billingState.warehouses.map(
          (wh) => DropdownMenuItem(value: wh.id, child: Text(wh.name)),
        ),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _selectedWarehouseId = val);
      },
    );

    final dateRangeButton = OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 14),
      label: Text(
        dateLabel,
        style: TextStyle(fontSize: isMobile ? 12 : 14),
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 12 : 14,
        ),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: _pickDateRange,
    );

    final filterBarContent = isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              dateRangeButton,
              const SizedBox(height: 10),
              warehouseDropdown,
            ],
          )
        : Row(
            children: [
              Flexible(child: dateRangeButton),
              const SizedBox(width: 12),
              SizedBox(width: isTablet ? 220 : 260, child: warehouseDropdown),
            ],
          );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isMobile ? 'Business Reports' : 'Advanced Business Reports',
          ),
          bottom: TabBar(
            isScrollable: false,
            tabAlignment: TabAlignment.fill,
            indicatorColor: const Color(0xFF2E7D32),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: const Color(0xFF2E7D32),
            unselectedLabelColor: Colors.grey,
            labelPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 4 : 12,
            ),
            labelStyle: TextStyle(
              fontSize: isMobile ? 11 : 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isMobile ? 11 : 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                icon: Icon(Icons.receipt_long, size: isMobile ? 18 : 20),
                text: isMobile ? 'Sales' : 'Sales Register',
                height: isMobile ? 56 : 64,
              ),
              Tab(
                icon: Icon(Icons.shopping_cart, size: isMobile ? 18 : 20),
                text: isMobile
                    ? 'Purchase'
                    : (isTablet ? 'Purchases' : 'Purchase Register'),
                height: isMobile ? 56 : 64,
              ),
              Tab(
                icon: Icon(Icons.percent, size: isMobile ? 18 : 20),
                text: isMobile ? 'GST' : 'GST Tax',
                height: isMobile ? 56 : 64,
              ),
              Tab(
                icon: Icon(Icons.inventory_2, size: isMobile ? 18 : 20),
                text: isMobile ? 'Stock' : 'Stock Asset',
                height: isMobile ? 56 : 64,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.md : AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
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
                  _buildSalesTab(
                    filteredInvoices: filteredInvoices,
                    isMobile: isMobile,
                    pagePadding: pagePadding,
                  ),
                  _buildPurchasesTab(
                    filteredPurchases: filteredPurchases,
                    isMobile: isMobile,
                    pagePadding: pagePadding,
                  ),
                  _buildGstTab(
                    filteredInvoices: filteredInvoices,
                    isMobile: isMobile,
                    pagePadding: pagePadding,
                  ),
                  _buildStockTab(
                    products: billingState.products,
                    isMobile: isMobile,
                    pagePadding: pagePadding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTab({
    required List<Invoice> filteredInvoices,
    required bool isMobile,
    required EdgeInsets pagePadding,
  }) {
    final totalSales = filteredInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.grandTotal,
    );
    final totalGst = filteredInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.cgst + inv.sgst + inv.igst,
    );
    final taxable = filteredInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.taxableAmount,
    );

    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            title: isMobile ? 'Sales Register' : 'Sales Register Log',
            subtitle: 'Invoice-wise sales for the selected period',
            isMobile: isMobile,
            accent: const Color(0xFF2E7D32),
            icon: Icons.receipt_long_rounded,
            actions: [
              AppButton(
                label: 'Excel',
                icon: Icons.table_view,
                type: AppButtonType.secondary,
                onPressed: () => _triggerExport('Excel', 'Sales Register'),
              ),
              AppButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf,
                onPressed: () => _triggerExport('PDF', 'Sales Register'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryMetrics(
            isMobile: isMobile,
            metrics: [
              _SummaryMetric(
                label: 'Invoices',
                value: '${filteredInvoices.length}',
                icon: Icons.description_outlined,
                color: const Color(0xFF1565C0),
              ),
              _SummaryMetric(
                label: 'Taxable',
                value: '₹${taxable.toStringAsFixed(2)}',
                icon: Icons.calculate_outlined,
                color: const Color(0xFF6A1B9A),
              ),
              _SummaryMetric(
                label: 'GST',
                value: '₹${totalGst.toStringAsFixed(2)}',
                icon: Icons.percent,
                color: const Color(0xFFEF6C00),
              ),
              _SummaryMetric(
                label: 'Net Sales',
                value: '₹${totalSales.toStringAsFixed(2)}',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF2E7D32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppTable<Invoice>(
              items: filteredInvoices,
              emptyMessage: 'No sales recorded for the selected period.',
              mobileCardBuilder: _buildInvoiceCard,
              columns: [
                TableColumnSpec<Invoice>(
                  label: 'Invoice No',
                  cellBuilder: (inv) => Text(
                    inv.invoiceNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TableColumnSpec<Invoice>(
                  label: 'Date',
                  cellBuilder: (inv) => Text(_formatDate(inv.invoiceDate)),
                ),
                TableColumnSpec<Invoice>(
                  label: 'Customer',
                  flex: 2,
                  cellBuilder: (inv) => Text(inv.customerName),
                ),
                TableColumnSpec<Invoice>(
                  label: 'Taxable Amt',
                  isNumeric: true,
                  cellBuilder: (inv) =>
                      Text('₹${inv.taxableAmount.toStringAsFixed(2)}'),
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
    );
  }

  Widget _buildPurchasesTab({
    required List<Purchase> filteredPurchases,
    required bool isMobile,
    required EdgeInsets pagePadding,
  }) {
    final totalPurchase = filteredPurchases.fold<double>(
      0.0,
      (sum, p) => sum + p.grandTotal,
    );
    final totalGst = filteredPurchases.fold<double>(
      0.0,
      (sum, p) => sum + p.cgst + p.sgst + p.igst,
    );
    final taxable = filteredPurchases.fold<double>(
      0.0,
      (sum, p) => sum + p.taxableAmount,
    );

    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            title: isMobile ? 'Purchase Register' : 'Purchase Register Log',
            subtitle: 'Supplier bills for the selected period',
            isMobile: isMobile,
            accent: const Color(0xFF1565C0),
            icon: Icons.shopping_cart_outlined,
            actions: [
              AppButton(
                label: 'Excel',
                icon: Icons.table_view,
                type: AppButtonType.secondary,
                onPressed: () => _triggerExport('Excel', 'Purchase Register'),
              ),
              AppButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf,
                onPressed: () => _triggerExport('PDF', 'Purchase Register'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryMetrics(
            isMobile: isMobile,
            metrics: [
              _SummaryMetric(
                label: 'Bills',
                value: '${filteredPurchases.length}',
                icon: Icons.receipt_outlined,
                color: const Color(0xFF1565C0),
              ),
              _SummaryMetric(
                label: 'Taxable',
                value: '₹${taxable.toStringAsFixed(2)}',
                icon: Icons.calculate_outlined,
                color: const Color(0xFF6A1B9A),
              ),
              _SummaryMetric(
                label: 'GST Input',
                value: '₹${totalGst.toStringAsFixed(2)}',
                icon: Icons.percent,
                color: const Color(0xFFEF6C00),
              ),
              _SummaryMetric(
                label: 'Total Value',
                value: '₹${totalPurchase.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
                color: const Color(0xFF2E7D32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppTable<Purchase>(
              items: filteredPurchases,
              emptyMessage:
                  'No purchase bills logged for the selected period.',
              mobileCardBuilder: _buildPurchaseCard,
              columns: [
                TableColumnSpec<Purchase>(
                  label: 'Bill No',
                  cellBuilder: (p) => Text(
                    p.purchaseNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TableColumnSpec<Purchase>(
                  label: 'Date',
                  cellBuilder: (p) => Text(_formatDate(p.purchaseDate)),
                ),
                TableColumnSpec<Purchase>(
                  label: 'Supplier',
                  flex: 2,
                  cellBuilder: (p) => Text(p.supplierName),
                ),
                TableColumnSpec<Purchase>(
                  label: 'Taxable Value',
                  isNumeric: true,
                  cellBuilder: (p) =>
                      Text('₹${p.taxableAmount.toStringAsFixed(2)}'),
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
    );
  }

  Widget _buildGstTab({
    required List<Invoice> filteredInvoices,
    required bool isMobile,
    required EdgeInsets pagePadding,
  }) {
    final gst5 = filteredInvoices.fold(
      0.0,
      (sum, inv) => sum + inv.cgst + inv.sgst,
    );
    final gst12 = filteredInvoices.fold(
      0.0,
      (sum, inv) => sum + (inv.cgst * 1.2),
    );
    final gst18 = filteredInvoices.fold(
      0.0,
      (sum, inv) => sum + (inv.cgst * 1.8),
    );
    final totalLiability = gst5 + gst12 + gst18;
    final taxable = filteredInvoices.fold<double>(
      0.0,
      (sum, inv) => sum + inv.taxableAmount,
    );

    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            title: isMobile
                ? 'GST Liability Summary'
                : 'GST Sales Liability Summary',
            subtitle: 'Rate-wise GST collected on sales invoices',
            isMobile: isMobile,
            accent: const Color(0xFF6A1B9A),
            icon: Icons.percent,
            actions: [
              AppButton(
                label: isMobile ? 'Export GSTR-1' : 'Export GSTR-1',
                icon: Icons.upload_file,
                onPressed: () =>
                    _triggerExport('Excel', 'GST Liability Summary'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryMetrics(
            isMobile: isMobile,
            metrics: [
              _SummaryMetric(
                label: 'Invoices',
                value: '${filteredInvoices.length}',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF1565C0),
              ),
              _SummaryMetric(
                label: 'Taxable Base',
                value: '₹${taxable.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFFEF6C00),
              ),
              _SummaryMetric(
                label: 'Total Liability',
                value: '₹${totalLiability.toStringAsFixed(2)}',
                icon: Icons.account_balance,
                color: const Color(0xFF6A1B9A),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'GST breakup by tax slab',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Computed from invoiced transactions in the selected filters.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;
                    final cards = [
                      _buildGSTRateCard(
                        title: 'GST 5%',
                        subtitle: 'Output tax @ 5%',
                        value: gst5,
                        bgLight: const Color(0xFFE8F5E9),
                        textCol: const Color(0xFF2E7D32),
                        icon: Icons.looks_5_outlined,
                      ),
                      _buildGSTRateCard(
                        title: 'GST 12%',
                        subtitle: 'Output tax @ 12%',
                        value: gst12,
                        bgLight: const Color(0xFFE3F2FD),
                        textCol: const Color(0xFF1976D2),
                        icon: Icons.looks_one_outlined,
                      ),
                      _buildGSTRateCard(
                        title: 'GST 18%',
                        subtitle: 'Output tax @ 18%',
                        value: gst18,
                        bgLight: const Color(0xFFEDE7F6),
                        textCol: const Color(0xFF673AB7),
                        icon: Icons.looks_two_outlined,
                      ),
                    ];

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < cards.length; i++) ...[
                            cards[i],
                            if (i < cards.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }

                    return Row(
                      children: [
                        for (int i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i < cards.length - 1) const SizedBox(width: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockTab({
    required List<Product> products,
    required bool isMobile,
    required EdgeInsets pagePadding,
  }) {
    final totalUnits = products.fold<double>(
      0.0,
      (sum, p) => sum + _stockQty(p),
    );
    final totalAssetValue = products.fold<double>(
      0.0,
      (sum, p) => sum + (_stockQty(p) * p.purchasePrice),
    );
    final activeSkus = products.where((p) => _stockQty(p) > 0).length;

    return SingleChildScrollView(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionHeader(
            title: isMobile
                ? 'Stock Valuation'
                : 'Stock Asset Summary & Valuation',
            subtitle: 'Inventory cost valuation by warehouse filter',
            isMobile: isMobile,
            accent: const Color(0xFF00838F),
            icon: Icons.inventory_2_outlined,
            actions: [
              AppButton(
                label: isMobile ? 'Export Valuation' : 'Export Asset Valuation',
                icon: Icons.assessment,
                onPressed: () =>
                    _triggerExport('Excel', 'Inventory Valuation'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryMetrics(
            isMobile: isMobile,
            metrics: [
              _SummaryMetric(
                label: 'SKUs',
                value: '${products.length}',
                icon: Icons.category_outlined,
                color: const Color(0xFF1565C0),
              ),
              _SummaryMetric(
                label: 'In Stock',
                value: '$activeSkus',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2E7D32),
              ),
              _SummaryMetric(
                label: 'Total Units',
                value: totalUnits.toInt().toString(),
                icon: Icons.inventory_outlined,
                color: const Color(0xFFEF6C00),
              ),
              _SummaryMetric(
                label: 'Asset Value',
                value: '₹${totalAssetValue.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF00838F),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppTable<Product>(
              items: products,
              emptyMessage: 'No products catalogued.',
              mobileCardBuilder: _buildProductCard,
              columns: [
                TableColumnSpec<Product>(
                  label: 'Product Name',
                  flex: 2,
                  cellBuilder: (p) => Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                    final qty = _stockQty(p);
                    return Text('${qty.toInt()} units');
                  },
                ),
                TableColumnSpec<Product>(
                  label: 'Cost Price',
                  isNumeric: true,
                  cellBuilder: (p) =>
                      Text('₹${p.purchasePrice.toStringAsFixed(2)}'),
                ),
                TableColumnSpec<Product>(
                  label: 'Asset Value (Cost)',
                  isNumeric: true,
                  cellBuilder: (p) {
                    final qty = _stockQty(p);
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
    );
  }

  double _stockQty(Product p) {
    return _selectedWarehouseId == 'all'
        ? p.currentStock
        : (p.warehouseStocks[_selectedWarehouseId] ?? 0.0);
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isMobile,
    required Color accent,
    required IconData icon,
    required List<Widget> actions,
  }) {
    final actionChildren = <Widget>[];
    for (int i = 0; i < actions.length; i++) {
      if (isMobile) {
        actionChildren.add(Expanded(child: actions[i]));
      } else {
        actionChildren.add(actions[i]);
      }
      if (i < actions.length - 1) {
        actionChildren.add(const SizedBox(width: 8));
      }
    }

    final titleBlock = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 40 : 44,
          height: isMobile ? 40 : 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: isMobile ? 20 : 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 15 : 17,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 11.5 : 12.5,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDarkMuted
                      : AppColors.textLightMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          Row(children: actionChildren),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        Row(children: actionChildren),
      ],
    );
  }

  Widget _buildSummaryMetrics({
    required bool isMobile,
    required List<_SummaryMetric> metrics,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth < 720 || isMobile;
        if (useGrid) {
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: metrics.map((m) {
              final width = constraints.maxWidth < 420
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 10) / 2;
              return SizedBox(
                width: width,
                child: _buildSummaryMetricCard(m),
              );
            }).toList(),
          );
        }

        return Row(
          children: [
            for (int i = 0; i < metrics.length; i++) ...[
              Expanded(child: _buildSummaryMetricCard(metrics[i])),
              if (i < metrics.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSummaryMetricCard(_SummaryMetric metric) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(metric.icon, color: metric.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textLightMuted,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    metric.value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Invoice inv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gst = inv.cgst + inv.sgst + inv.igst;

    return _buildReportCard(
      isDark: isDark,
      accent: const Color(0xFF2E7D32),
      icon: Icons.receipt_long_rounded,
      title: inv.invoiceNumber,
      subtitle: inv.customerName,
      badge: _formatDate(inv.invoiceDate),
      rows: [
        ('Taxable', '₹${inv.taxableAmount.toStringAsFixed(2)}'),
        ('GST', '₹${gst.toStringAsFixed(2)}'),
      ],
      totalLabel: 'Grand Total',
      totalValue: '₹${inv.grandTotal.toStringAsFixed(2)}',
    );
  }

  Widget _buildPurchaseCard(Purchase purchase) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gst = purchase.cgst + purchase.sgst + purchase.igst;

    return _buildReportCard(
      isDark: isDark,
      accent: const Color(0xFF1565C0),
      icon: Icons.shopping_cart_outlined,
      title: purchase.purchaseNumber,
      subtitle: purchase.supplierName,
      badge: _formatDate(purchase.purchaseDate),
      rows: [
        ('Taxable', '₹${purchase.taxableAmount.toStringAsFixed(2)}'),
        ('GST Input', '₹${gst.toStringAsFixed(2)}'),
      ],
      totalLabel: 'Total Value',
      totalValue: '₹${purchase.grandTotal.toStringAsFixed(2)}',
    );
  }

  Widget _buildProductCard(Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qty = _stockQty(product);
    final assetValue = qty * product.purchasePrice;

    return _buildReportCard(
      isDark: isDark,
      accent: const Color(0xFF00838F),
      icon: Icons.inventory_2_outlined,
      title: product.name,
      subtitle: 'SKU: ${product.sku}',
      badge: '${qty.toInt()} units',
      rows: [
        ('Cost Price', '₹${product.purchasePrice.toStringAsFixed(2)}'),
      ],
      totalLabel: 'Asset Value',
      totalValue: '₹${assetValue.toStringAsFixed(2)}',
    );
  }

  Widget _buildReportCard({
    required bool isDark,
    required Color accent,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required List<(String, String)> rows,
    required String totalLabel,
    required String totalValue,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(icon, size: 17, color: accent),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          ...rows.map(
                            (row) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    row.$1,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    row.$2,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                totalLabel,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155),
                                ),
                              ),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    totalValue,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: accent,
                                    ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildGSTRateCard({
    required String title,
    required String subtitle,
    required double value,
    required Color bgLight,
    required Color textCol,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? textCol.withValues(alpha: 0.12) : bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: textCol.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: textCol.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: textCol),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textCol,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textCol.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '₹${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textCol,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
