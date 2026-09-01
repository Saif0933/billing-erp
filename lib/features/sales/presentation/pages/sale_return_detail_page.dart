import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/models/warehouse_models.dart';
import '../../../../core/services/invoice_pdf_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class SaleReturnDetailPage extends ConsumerWidget {
  final String returnId;
  const SaleReturnDetailPage({super.key, required this.returnId});

  void _showCancelDialog(BuildContext context, WidgetRef ref, Invoice ret) {
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
              await ref.read(billingRepositoryProvider.notifier).cancelInvoice(ret.id);
              AppFeedback.showSnackbar(context, message: 'Sale return cancelled successfully.');
            },
          ),
        ],
      ),
    );
  }

  void _confirmReturn(BuildContext context, WidgetRef ref, Invoice ret) async {
    await ref.read(billingRepositoryProvider.notifier).confirmInvoice(ret.id);
    AppFeedback.showSnackbar(context, message: 'Sale return confirmed! Inventory restocked & balance adjusted.');
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingRepositoryProvider);
    final activeBiz = ref.watch(businessProvider).activeBusiness;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final ret = billingState.invoices.firstWhere(
      (inv) =>
          inv.id == returnId ||
          inv.invoiceNumber.toLowerCase() == returnId.toLowerCase(),
      orElse: () => Invoice(
        id: '',
        invoiceNumber: 'Not Found',
        invoiceDate: DateTime.now(),
        customerId: '',
        customerName: '',
        billingAddress: '',
        shippingAddress: '',
        placeOfSupply: '',
        items: [],
        taxableAmount: 0,
        cgst: 0,
        sgst: 0,
        igst: 0,
        cess: 0,
        roundOff: 0,
        grandTotal: 0,
        balanceAmount: 0,
        paymentMode: '',
        status: InvoiceStatus.draft,
        notes: '',
        termsConditions: '',
      ),
    );

    if (ret.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sale Return Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Sale Return Not Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/sales/returns'),
                child: const Text('Back to Sale Returns'),
              ),
            ],
          ),
        ),
      );
    }

    final originalInvoice = billingState.invoices.cast<Invoice?>().firstWhere(
          (i) =>
              i != null &&
              !i.isCreditNote &&
              (i.id == ret.originalInvoiceId ||
                  i.invoiceNumber.toLowerCase() == ret.originalInvoiceId.toLowerCase()),
          orElse: () => null,
        );

    final warehouse = billingState.warehouses.firstWhere(
      (w) => w.id == ret.warehouseId,
      orElse: () => billingState.warehouses.isNotEmpty ? billingState.warehouses.first : const Warehouse(id: 'main', name: 'Main Warehouse', code: 'M-WH', address: '', contact: '', isActive: true),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Return: ${ret.invoiceNumber}'),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print / Export Credit Note PDF',
            onPressed: () {
              if (activeBiz != null) {
                InvoicePdfService.share(ret, activeBiz);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            AppPageHeader(
              title: 'Credit Note / Sale Return',
              description: 'Detailed breakdown of returned products, tax credits, and customer balance adjustment.',
              breadcrumbs: ['Dashboard', 'Sales', 'Sale Returns', ret.invoiceNumber],
              actions: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print Credit Note PDF'),
                  onPressed: () {
                    if (activeBiz != null) {
                      InvoicePdfService.share(ret, activeBiz);
                    }
                  },
                ),
                if (ret.status == InvoiceStatus.draft) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Confirm Return'),
                    onPressed: () => _confirmReturn(context, ref, ret),
                  ),
                ],
                if (ret.status != InvoiceStatus.cancelled) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel Return'),
                    onPressed: () => _showCancelDialog(context, ref, ret),
                  ),
                ],
              ],
            ),

            // Main Info Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ret.invoiceNumber,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00897B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildStatusBadge(ret.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Return Date: ${ret.invoiceDate.day}/${ret.invoiceDate.month}/${ret.invoiceDate.year}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Credit Amount', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            '₹${ret.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00897B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ResponsiveRow(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CUSTOMER INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            Text(ret.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            if (ret.billingAddress.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(ret.billingAddress, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ),
                            if (ret.placeOfSupply.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('Place of Supply: ${ret.placeOfSupply}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ORIGINAL INVOICE LINK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            if (originalInvoice != null) ...[
                              InkWell(
                                onTap: () => context.push('/sales/${originalInvoice.id}'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F3D32) : const Color(0xFFE0F2F1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF00897B).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.receipt_long, size: 16, color: Color(0xFF00897B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${originalInvoice.invoiceNumber} (View)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00897B),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Dated: ${originalInvoice.invoiceDate.day}/${originalInvoice.invoiceDate.month}/${originalInvoice.invoiceDate.year} • Amount: ₹${originalInvoice.grandTotal.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                            ] else ...[
                              Text(
                                ret.originalInvoiceId.isNotEmpty ? ret.originalInvoiceId : 'Direct Return (No Reference)',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RESTOCK & SETTLEMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.warehouse_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('Restock Godown: ${warehouse.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.payment_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text('Settlement: ${ret.paymentMode.isNotEmpty ? ret.paymentMode : "Credit Note"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Items Breakdown Table
            AppCard(
              title: 'Returned Items Breakdown',
              child: AppTable<InvoiceItem>(
                items: ret.items,
                emptyMessage: 'No items in this return record.',
                columns: [
                  TableColumnSpec<InvoiceItem>(
                    label: 'Product / Service',
                    flex: 2,
                    cellBuilder: (item) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('HSN/SAC: ${item.hsnSac}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                  ),
                  TableColumnSpec<InvoiceItem>(
                    label: 'Returned Qty',
                    isNumeric: true,
                    cellBuilder: (item) => Text(
                      '${item.quantity} ${item.unit}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TableColumnSpec<InvoiceItem>(
                    label: 'Rate / Unit',
                    isNumeric: true,
                    cellBuilder: (item) => Text('₹${item.rate.toStringAsFixed(2)}'),
                  ),
                  TableColumnSpec<InvoiceItem>(
                    label: 'Taxable Value',
                    isNumeric: true,
                    cellBuilder: (item) => Text('₹${item.taxableValue.toStringAsFixed(2)}'),
                  ),
                  TableColumnSpec<InvoiceItem>(
                    label: 'GST Rate',
                    isNumeric: true,
                    cellBuilder: (item) => Text('${item.gstRate.toStringAsFixed(0)}%'),
                  ),
                  TableColumnSpec<InvoiceItem>(
                    label: 'Total Tax',
                    isNumeric: true,
                    cellBuilder: (item) {
                      final tax = item.cgst + item.sgst + item.igst + item.cess;
                      return Text('₹${tax.toStringAsFixed(2)}');
                    },
                  ),
                  TableColumnSpec<InvoiceItem>(
                    label: 'Total Credit',
                    isNumeric: true,
                    cellBuilder: (item) {
                      final total = item.taxableValue + item.cgst + item.sgst + item.igst + item.cess;
                      return Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Financial Summary & Notes
            ResponsiveRow(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: AppCard(
                    title: 'Return Notes & Reasons',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ret.notes.isNotEmpty) ...[
                          const Text('Return Justification / Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(ret.notes, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          const SizedBox(height: 16),
                        ],
                        if (ret.termsConditions.isNotEmpty) ...[
                          const Text('Terms & Conditions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(ret.termsConditions, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 2,
                  child: AppCard(
                    title: 'Financial Breakdown',
                    child: Column(
                      children: [
                        _buildSummaryLine('Taxable Amount', '₹${ret.taxableAmount.toStringAsFixed(2)}'),
                        if (ret.cgst > 0)
                          _buildSummaryLine('CGST', '₹${ret.cgst.toStringAsFixed(2)}'),
                        if (ret.sgst > 0)
                          _buildSummaryLine('SGST', '₹${ret.sgst.toStringAsFixed(2)}'),
                        if (ret.igst > 0)
                          _buildSummaryLine('IGST', '₹${ret.igst.toStringAsFixed(2)}'),
                        if (ret.cess > 0)
                          _buildSummaryLine('Cess', '₹${ret.cess.toStringAsFixed(2)}'),
                        if (ret.roundOff != 0)
                          _buildSummaryLine('Round Off', '₹${ret.roundOff.toStringAsFixed(2)}'),
                        const Divider(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF00382E) : const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total Credit',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                '₹${ret.grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF00897B),
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryLine(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
