import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/services/invoice_pdf_service.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class SaleReturnPage extends ConsumerStatefulWidget {
  const SaleReturnPage({super.key});

  @override
  ConsumerState<SaleReturnPage> createState() => _SaleReturnPageState();
}

class _SaleReturnPageState extends ConsumerState<SaleReturnPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textLightPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['All', 'Draft', 'Confirmed', 'Cancelled'].map((
                  status,
                ) {
                  final isSelected = _selectedStatusFilter == status;
                  return ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    selectedColor: isDark
                        ? const Color(0xFF1E3A2F)
                        : const Color(0xFFE8F5E9),
                    checkmarkColor: const Color(0xFF2E7D32),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : (isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStatusFilter = status;
                        });
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Sales',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/sales');
                }
              },
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A2F)
                    : const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.assignment_return_outlined,
                color: Color(0xFF00897B),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sales Operations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textLightPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  'Sales',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Sale Returns (Credit Notes)',
                  style: TextStyle(
                    color: Color(0xFF00897B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTealBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF004D40)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_return,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'CREDIT NOTES & RETURNS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sale Returns Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Record returned goods, adjust customer receivables, issue GST Credit Notes, and automatically restock your inventory.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!Responsive.isMobile(context)) ...[
            const SizedBox(width: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF004D40),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              label: const Text(
                'New Sale Return',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () => context.push('/sales/returns/new'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Invoice> returns) {
    final confirmedReturns = returns
        .where((r) => r.status == InvoiceStatus.confirmed)
        .toList();
    final draftReturns = returns
        .where((r) => r.status == InvoiceStatus.draft)
        .toList();
    final totalReturnValue = confirmedReturns.fold(
      0.0,
      (sum, r) => sum + r.grandTotal,
    );
    final totalRestockedItems = confirmedReturns.fold(0.0, (sum, r) {
      return sum + r.items.fold(0.0, (iSum, item) => iSum + item.quantity);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1000;

        final cards = [
          _buildStatCard(
            title: 'Total Returns Value',
            value: '₹${totalReturnValue.toStringAsFixed(2)}',
            subtitle: '${confirmedReturns.length} confirmed returns',
            icon: Icons.currency_rupee,
            accentColor: const Color(0xFF00897B),
            bgColor: const Color(0xFFE0F2F1),
          ),
          _buildStatCard(
            title: 'Confirmed Returns',
            value: '${confirmedReturns.length}',
            subtitle: 'Credit notes issued',
            icon: Icons.check_circle_outline,
            accentColor: const Color(0xFF2E7D32),
            bgColor: const Color(0xFFE8F5E9),
          ),
          _buildStatCard(
            title: 'Items Restocked',
            value: totalRestockedItems.toStringAsFixed(0),
            subtitle: 'Units added back to inventory',
            icon: Icons.inventory_2_outlined,
            accentColor: const Color(0xFF1976D2),
            bgColor: const Color(0xFFE3F2FD),
          ),
          _buildStatCard(
            title: 'Pending Drafts',
            value: '${draftReturns.length}',
            subtitle: 'Returns awaiting approval',
            icon: Icons.pending_actions_outlined,
            accentColor: const Color(0xFFF57C00),
            bgColor: const Color(0xFFFFF3E0),
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: c,
                  ),
                )
                .toList(),
          );
        } else if (isTablet) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? accentColor.withOpacity(0.2) : bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textLightSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textLightPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color bg;
    Color fg;
    String text;

    switch (status) {
      case InvoiceStatus.draft:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        text = 'DRAFT';
        break;
      case InvoiceStatus.confirmed:
      case InvoiceStatus.paid:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        text = 'CONFIRMED';
        break;
      case InvoiceStatus.partiallyPaid:
        bg = const Color(0xFFE0F7FA);
        fg = const Color(0xFF00838F);
        text = 'ADJUSTED';
        break;
      case InvoiceStatus.cancelled:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        text = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Invoice ret) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Sale Return?'),
        content: Text(
          'Are you sure you want to cancel return ${ret.invoiceNumber}?\n\nIf confirmed, this will reverse the restocked inventory quantities and restore the customer balance.',
        ),
        actions: [
          TextButton(
            child: const Text('No, Keep It'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel Return'),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(billingRepositoryProvider.notifier)
                  .cancelInvoice(ret.id);
              if (mounted) {
                AppFeedback.showSnackbar(
                  context,
                  message: 'Sale return cancelled successfully.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmReturn(BuildContext context, Invoice ret) async {
    await ref.read(billingRepositoryProvider.notifier).confirmInvoice(ret.id);
    if (mounted) {
      AppFeedback.showSnackbar(
        context,
        message:
            'Sale return confirmed! Inventory restocked & balance adjusted.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final billingState = ref.watch(billingRepositoryProvider);
    final activeBiz = ref.watch(businessProvider).activeBusiness;

    // Filter to Credit Notes only
    final allReturns = billingState.invoices
        .where((inv) => inv.isCreditNote)
        .toList();

    final filteredReturns = allReturns.where((ret) {
      final matchesSearch =
          ret.invoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          ret.originalInvoiceId.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          ret.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ret.notes.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _selectedStatusFilter == 'All' ||
          ret.status.name.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      floatingActionButton: Responsive.isMobile(context)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/sales/returns/new'),
              icon: const Icon(Icons.add),
              label: const Text('New Return'),
              backgroundColor: const Color(0xFF00897B),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPageHeader(context),
            _buildTealBanner(context),
            const SizedBox(height: AppSpacing.lg),
            _buildSummaryCards(allReturns),
            const SizedBox(height: AppSpacing.lg),

            // Search & Filter Card
            AppCard(
              child: Column(
                children: [
                  ResponsiveRow(
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppTextField(
                          label: 'Search Returns & Credit Notes',
                          hintText:
                              'Search by return no., original invoice, customer, or reason...',
                          controller: _searchController,
                          prefixIcon: const Icon(Icons.search),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                        ),
                      ),
                      if (!Responsive.isMobile(context))
                        SizedBox(
                          width: 180,
                          child: AppDropdownField<String>(
                            label: 'Filter Status',
                            value: _selectedStatusFilter,
                            items: const [
                              DropdownMenuItem(
                                value: 'All',
                                child: Text('All Statuses'),
                              ),
                              DropdownMenuItem(
                                value: 'Draft',
                                child: Text('Draft'),
                              ),
                              DropdownMenuItem(
                                value: 'Confirmed',
                                child: Text('Confirmed'),
                              ),
                              DropdownMenuItem(
                                value: 'Cancelled',
                                child: Text('Cancelled'),
                              ),
                            ],
                            onChanged: (val) => setState(
                              () => _selectedStatusFilter = val ?? 'All',
                            ),
                          ),
                        ),
                      if (Responsive.isMobile(context))
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.filter_list),
                            label: Text('Status: $_selectedStatusFilter'),
                            onPressed: () => _showFilterBottomSheet(context),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Returns Table / List
                  AppTable<Invoice>(
                    items: filteredReturns,
                    emptyMessage: allReturns.isEmpty
                        ? 'No sale returns recorded yet. Click "New Sale Return" to create your first credit note.'
                        : 'No sale returns match your search or filter criteria.',
                    columns: [
                      TableColumnSpec<Invoice>(
                        label: 'Return No.',
                        cellBuilder: (ret) => InkWell(
                          onTap: () => context.push('/sales/returns/${ret.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ret.invoiceNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00897B),
                                ),
                              ),
                              Text(
                                '${ret.invoiceDate.day}/${ret.invoiceDate.month}/${ret.invoiceDate.year}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Original Invoice',
                        cellBuilder: (ret) {
                          final origInv = billingState.invoices.firstWhere(
                            (i) =>
                                i.id == ret.originalInvoiceId ||
                                i.invoiceNumber == ret.originalInvoiceId,
                            orElse: () => ret,
                          );
                          final origNo = origInv.invoiceNumber.isNotEmpty
                              ? origInv.invoiceNumber
                              : ret.originalInvoiceId;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.receipt_outlined,
                                  size: 13,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  origNo.isNotEmpty ? origNo : 'Direct Return',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Customer',
                        flex: 2,
                        cellBuilder: (ret) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ret.customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (ret.placeOfSupply.isNotEmpty)
                              Text(
                                'POS: ${ret.placeOfSupply}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Items & Reason',
                        cellBuilder: (ret) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ret.items.length} ${ret.items.length == 1 ? "item" : "items"} returned',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (ret.notes.isNotEmpty)
                              Text(
                                ret.notes,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Return Value',
                        isNumeric: true,
                        cellBuilder: (ret) => Text(
                          '₹${ret.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00897B),
                          ),
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Status',
                        cellBuilder: (ret) => _buildStatusBadge(ret.status),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Actions',
                        cellBuilder: (ret) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 18,
                                color: Color(0xFF00897B),
                              ),
                              tooltip: 'View Details',
                              onPressed: () =>
                                  context.push('/sales/returns/${ret.id}'),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.print_outlined,
                                size: 18,
                                color: Colors.blueGrey,
                              ),
                              tooltip: 'Print Credit Note PDF',
                              onPressed: () {
                                if (activeBiz != null) {
                                  InvoicePdfService.share(ret, activeBiz);
                                }
                              },
                            ),
                            if (ret.status == InvoiceStatus.draft)
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color: Colors.green,
                                ),
                                tooltip: 'Confirm Return',
                                onPressed: () => _confirmReturn(context, ret),
                              ),
                            if (ret.status != InvoiceStatus.cancelled)
                              IconButton(
                                icon: const Icon(
                                  Icons.cancel_outlined,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                tooltip: 'Cancel Return',
                                onPressed: () =>
                                    _showCancelDialog(context, ret),
                              ),
                          ],
                        ),
                      ),
                    ],
                    mobileCardBuilder: (ret) => InkWell(
                      onTap: () => context.push('/sales/returns/${ret.id}'),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ret.invoiceNumber,
                                        style: AppTypography.titleMedium
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF00897B),
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${ret.invoiceDate.day}/${ret.invoiceDate.month}/${ret.invoiceDate.year}',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(ret.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Customer: ${ret.customerName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (ret.originalInvoiceId.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Linked Invoice: ${ret.originalInvoiceId}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (ret.notes.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  'Reason: ${ret.notes}',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Return Value: ₹${ret.grandTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00897B),
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${ret.items.length} items returned',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.print_outlined,
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        if (activeBiz != null) {
                                          InvoicePdfService.share(
                                            ret,
                                            activeBiz,
                                          );
                                        }
                                      },
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
}
