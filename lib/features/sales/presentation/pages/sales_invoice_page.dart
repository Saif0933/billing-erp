import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../providers/sales_invoice_provider.dart';

class SalesInvoicePage extends ConsumerStatefulWidget {
  const SalesInvoicePage({super.key});

  @override
  ConsumerState<SalesInvoicePage> createState() => _SalesInvoicePageState();
}

class _SalesInvoicePageState extends ConsumerState<SalesInvoicePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(salesInvoiceNotifierProvider.notifier);
      final remote = await notifier.refreshInvoices();
      if (!mounted) return;
      ref.read(billingRepositoryProvider.notifier).mergeRemoteInvoices(
            remote.map((dto) => dto.toInvoice()).toList(),
          );
    });
  }

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
              StatefulBuilder(
                builder: (context, setModalState) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'All',
                          'Draft',
                          'Confirmed',
                          'PartiallyPaid',
                          'Paid',
                          'Cancelled',
                        ].map((status) {
                          final isSelected = _selectedStatusFilter == status;
                          return ChoiceChip(
                            label: Text(
                              status == 'PartiallyPaid'
                                  ? 'Partially Paid'
                                  : status,
                            ),
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
                                setModalState(() {});
                                Navigator.pop(ctx);
                              }
                            },
                          );
                        }).toList(),
                  );
                },
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A2F)
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sales & Billing',
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
                  'Invoices',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
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

  Widget _buildGreenBanner(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth <= Responsive.compactMax;
        final isSmallScreen = constraints.maxWidth < 400;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F5A3C), Color(0xFF083D28)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F5A3C).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isSmallScreen ? 14 : (compact ? 16 : 24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Invoices',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 19 : (compact ? 21 : 24),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create and track tax invoices, credit notes, and customer account receipts.',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: -15,
                              top: -10,
                              child: Icon(
                                Icons.bolt,
                                color: Colors.green.shade300.withValues(alpha: 0.5),
                                size: 16,
                              ),
                            ),
                            Positioned(
                              right: -15,
                              bottom: 10,
                              child: Icon(
                                Icons.add,
                                color: Colors.green.shade300.withValues(alpha: 0.5),
                                size: 14,
                              ),
                            ),
                            Transform.rotate(
                              angle: 0.1,
                              child: Container(
                                width: 58,
                                height: 76,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 5,
                                      color: const Color(0xFF81C784),
                                      margin: const EdgeInsets.only(bottom: 6),
                                    ),
                                    Container(
                                      width: 42,
                                      height: 3,
                                      color: Colors.grey.shade200,
                                      margin: const EdgeInsets.only(bottom: 4),
                                    ),
                                    Container(
                                      width: 38,
                                      height: 3,
                                      color: Colors.grey.shade200,
                                      margin: const EdgeInsets.only(bottom: 4),
                                    ),
                                    Container(
                                      width: 25,
                                      height: 3,
                                      color: Colors.grey.shade200,
                                      margin: const EdgeInsets.only(bottom: 4),
                                    ),
                                    Container(
                                      width: 40,
                                      height: 3,
                                      color: Colors.grey.shade200,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveRow(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.point_of_sale_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Flexible(
                        child: Text(
                          'Retail POS Terminal',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onPressed: () => context.go('/pos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.post_add_outlined,
                        color: Color(0xFF0F5A3C),
                        size: 20,
                      ),
                      label: const Flexible(
                        child: Text(
                          'Create Invoice',
                          style: TextStyle(
                            color: Color(0xFF0F5A3C),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      onPressed: () => context.push('/sales/new'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F5A3C),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, {required String message}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: DashedRectPainter(
        color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        gap: 6.0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E3A2F)
                        : const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF2E7D32),
                    size: 38,
                  ),
                ),
                const Positioned(
                  top: 4,
                  left: -8,
                  child: Icon(Icons.add, color: Color(0xFF81C784), size: 12),
                ),
                const Positioned(
                  top: 36,
                  right: -10,
                  child: Icon(
                    Icons.star_border,
                    color: Color(0xFF81C784),
                    size: 10,
                  ),
                ),
                const Positioned(
                  bottom: 8,
                  right: -6,
                  child: Icon(Icons.add, color: Color(0xFF81C784), size: 12),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Empty List',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textLightPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(InvoiceStatus status) {
    Color badgeColor;
    String label;
    switch (status) {
      case InvoiceStatus.draft:
        badgeColor = Colors.grey;
        label = 'DRAFT';
        break;
      case InvoiceStatus.confirmed:
        badgeColor = Colors.blue;
        label = 'CONFIRMED';
        break;
      case InvoiceStatus.partiallyPaid:
        badgeColor = Colors.orange;
        label = 'PARTIALLY PAID';
        break;
      case InvoiceStatus.paid:
        badgeColor = const Color(0xFF2E7D32);
        label = 'PAID';
        break;
      case InvoiceStatus.cancelled:
        badgeColor = Colors.red;
        label = 'CANCELLED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final invoiceState = ref.watch(salesInvoiceNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final mergedByNumber = <String, Invoice>{};
    for (final inv in billingState.invoices.where((i) => !i.isCreditNote)) {
      final key = inv.invoiceNumber.trim().isNotEmpty
          ? inv.invoiceNumber.trim().toLowerCase()
          : inv.id;
      mergedByNumber[key] = inv;
    }
    for (final dto in invoiceState.invoices) {
      final inv = dto.toInvoice();
      final key = inv.invoiceNumber.trim().isNotEmpty
          ? inv.invoiceNumber.trim().toLowerCase()
          : inv.id;
      mergedByNumber[key] = inv;
    }
    final allInvoices = mergedByNumber.values.toList()
      ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

    // Filter invoices
    final filteredInvoices = allInvoices.where((inv) {
      final q = _searchQuery.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          inv.invoiceNumber.toLowerCase().contains(q) ||
          inv.customerName.toLowerCase().contains(q);
      final matchesStatus =
          _selectedStatusFilter == 'All' ||
          inv.status.name.toLowerCase() == _selectedStatusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: Responsive.pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader(context),
              _buildGreenBanner(context),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Search Invoices',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textLightPrimary,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _selectedStatusFilter != 'All')
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedStatusFilter = 'All';
                              });
                            },
                            child: const Text(
                              'Clear Filters',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              decoration: InputDecoration(
                                hintText: 'Search by invoice number or name...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.grey.shade400,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                          });
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 48,
                          width: 48,
                          margin: const EdgeInsets.only(left: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : const Color(0xFFF1F8F5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE8F5E9),
                              width: 1.5,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.filter_alt_outlined,
                              color: _selectedStatusFilter != 'All'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF2E7D32),
                            ),
                            tooltip: 'Filter Status',
                            onPressed: () => _showFilterBottomSheet(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          'All',
                          'Draft',
                          'Confirmed',
                          'PartiallyPaid',
                          'Paid',
                          'Cancelled',
                        ].map((status) {
                          final isSelected = _selectedStatusFilter == status;
                          final displayLabel = status == 'PartiallyPaid'
                              ? 'Partially Paid'
                              : status;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(displayLabel),
                              selected: isSelected,
                              selectedColor: isDark
                                  ? const Color(0xFF1E3A2F)
                                  : const Color(0xFFE8F5E9),
                              checkmarkColor: const Color(0xFF2E7D32),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                color: isSelected
                                    ? const Color(0xFF2E7D32)
                                    : (isDark
                                        ? AppColors.textDarkSecondary
                                        : AppColors.textLightSecondary),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              visualDensity: VisualDensity.compact,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatusFilter = status;
                                  });
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (invoiceState.isLoadingList && filteredInvoices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredInvoices.isEmpty)
                _buildEmptyState(
                  context,
                  message: allInvoices.isEmpty
                      ? 'No sales invoices yet. Create an invoice to see it here.'
                      : 'No invoices match the selected search criteria.',
                )
              else
                AppCard(
                  padding: EdgeInsets.zero,
                  child: AppTable<Invoice>(
                    items: filteredInvoices,
                    emptyMessage:
                        'No invoices match the selected search criteria.',
                    columns: [
                      TableColumnSpec<Invoice>(
                        label: 'Invoice Number',
                        cellBuilder: (inv) => InkWell(
                          onTap: () => context.push('/sales/${inv.id}'),
                          child: Text(
                            inv.invoiceNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Date',
                        cellBuilder: (inv) => Text(
                          '${inv.invoiceDate.day.toString().padLeft(2, '0')}/${inv.invoiceDate.month.toString().padLeft(2, '0')}/${inv.invoiceDate.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Customer',
                        flex: 2,
                        cellBuilder: (inv) => Text(
                          inv.customerName.isEmpty
                              ? 'Walk-in Customer'
                              : inv.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Place of Supply',
                        cellBuilder: (inv) => Text(
                          inv.placeOfSupply.isEmpty ? '-' : inv.placeOfSupply,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Grand Total',
                        isNumeric: true,
                        cellBuilder: (inv) => Text(
                          '₹${inv.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Balance Due',
                        isNumeric: true,
                        cellBuilder: (inv) => Text(
                          '₹${inv.balanceAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: inv.balanceAmount > 0 &&
                                    inv.status != InvoiceStatus.cancelled
                                ? Colors.red
                                : const Color(0xFF2E7D32),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TableColumnSpec<Invoice>(
                        label: 'Status',
                        cellBuilder: (inv) => _buildStatusBadge(inv.status),
                      ),
                    ],
                    mobileCardBuilder: (inv) {
                      final isDarkCard =
                          Theme.of(context).brightness == Brightness.dark;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push('/sales/${inv.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDarkCard
                                ? AppColors.surfaceDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkCard
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      inv.invoiceNumber,
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkCard
                                            ? AppColors.textDarkPrimary
                                            : AppColors.textLightPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(inv.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      inv.customerName.isEmpty
                                          ? 'Walk-in Customer'
                                          : inv.customerName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDarkCard
                                            ? AppColors.textDarkSecondary
                                            : AppColors.textLightSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${inv.invoiceDate.day.toString().padLeft(2, '0')}/${inv.invoiceDate.month.toString().padLeft(2, '0')}/${inv.invoiceDate.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  if (inv.placeOfSupply.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        inv.placeOfSupply,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Total: ₹${inv.grandTotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: isDarkCard
                                                ? AppColors.textDarkPrimary
                                                : AppColors.textLightPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          inv.balanceAmount > 0 &&
                                                  inv.status !=
                                                      InvoiceStatus.cancelled
                                              ? 'Balance: ₹${inv.balanceAmount.toStringAsFixed(2)}'
                                              : (inv.status ==
                                                      InvoiceStatus.cancelled
                                                  ? 'Cancelled'
                                                  : 'Fully Paid'),
                                          style: TextStyle(
                                            color: inv.balanceAmount > 0 &&
                                                    inv.status !=
                                                        InvoiceStatus.cancelled
                                                ? Colors.red.shade700
                                                : (inv.status ==
                                                        InvoiceStatus.cancelled
                                                    ? Colors.grey
                                                    : const Color(0xFF2E7D32)),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.radius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
    );

    final Path dashedPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = gap;
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
