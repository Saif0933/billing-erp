import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

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
            color: const Color(0xFF0F5A3C).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
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
                  children: const [
                    Text(
                      'Sales Invoices',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create and track tax invoices, credit notes, and customer account receipts.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
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
                          color: Colors.green.shade300.withOpacity(0.5),
                          size: 16,
                        ),
                      ),
                      Positioned(
                        right: -15,
                        bottom: 10,
                        child: Icon(
                          Icons.add,
                          color: Colors.green.shade300.withOpacity(0.5),
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
                                color: Colors.black.withOpacity(0.15),
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
                                color: Colors.black.withOpacity(0.15),
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
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(
              Icons.post_add_outlined,
              color: Color(0xFF0F5A3C),
              size: 20,
            ),
            label: const Text(
              'Create Invoice',
              style: TextStyle(
                color: Color(0xFF0F5A3C),
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              'No invoices match the selected search criteria.',
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

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final allInvoices = billingState.invoices
        .where((inv) => !inv.isCreditNote)
        .toList();

    // Filter invoices
    final filteredInvoices = allInvoices.where((inv) {
      final matchesSearch =
          inv.invoiceNumber.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          inv.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus =
          _selectedStatusFilter == 'All' ||
          inv.status.name.toLowerCase() == _selectedStatusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                  Text(
                    'Search Invoices',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textDarkPrimary
                          : AppColors.textLightPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.surfaceDark
                              : const Color(0xFFF1F8F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.borderDark
                                : const Color(0xFFE8F5E9),
                            width: 1.5,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.filter_alt_outlined,
                            color: Color(0xFF2E7D32),
                          ),
                          onPressed: () => _showFilterBottomSheet(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (filteredInvoices.isEmpty)
              _buildEmptyState(context)
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
                      label: 'Place of Supply',
                      cellBuilder: (inv) => Text(inv.placeOfSupply),
                    ),
                    TableColumnSpec<Invoice>(
                      label: 'Grand Total',
                      isNumeric: true,
                      cellBuilder: (inv) => Text(
                        '₹${inv.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TableColumnSpec<Invoice>(
                      label: 'Balance Due',
                      isNumeric: true,
                      cellBuilder: (inv) => Text(
                        '₹${inv.balanceAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              inv.balanceAmount > 0 &&
                                  inv.status != InvoiceStatus.cancelled
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                    ),
                    TableColumnSpec<Invoice>(
                      label: 'Status',
                      cellBuilder: (inv) {
                        Color badgeColor;
                        switch (inv.status) {
                          case InvoiceStatus.draft:
                            badgeColor = Colors.grey;
                            break;
                          case InvoiceStatus.confirmed:
                            badgeColor = Colors.blue;
                            break;
                          case InvoiceStatus.partiallyPaid:
                            badgeColor = Colors.orange;
                            break;
                          case InvoiceStatus.paid:
                            badgeColor = Colors.green;
                            break;
                          case InvoiceStatus.cancelled:
                            badgeColor = Colors.red;
                            break;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inv.status.name.toUpperCase(),
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  mobileCardBuilder: (inv) => InkWell(
                    onTap: () => context.push('/sales/${inv.id}'),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                inv.invoiceNumber,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                inv.status.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: inv.status == InvoiceStatus.paid
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Customer: ${inv.customerName}'),
                          Text(
                            'Date: ${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year}',
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Amount: ₹${inv.grandTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Balance: ₹${inv.balanceAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                  ),
                ),
              ),
          ],
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
