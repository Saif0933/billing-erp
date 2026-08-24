import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../core/services/invoice_pdf_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../business/presentation/providers/business_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class InvoiceDetailPage extends ConsumerStatefulWidget {
  final String invoiceId;
  const InvoiceDetailPage({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  final _amountReceivedController = TextEditingController();
  final _refNoController = TextEditingController();
  String _paymentMode = 'Bank';
  DateTime _paymentDate = DateTime.now();

  @override
  void dispose() {
    _amountReceivedController.dispose();
    _refNoController.dispose();
    super.dispose();
  }

  void _showReceivePaymentDialog(Invoice invoice) {
    _amountReceivedController.text = invoice.balanceAmount.toString();
    _refNoController.text = 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Payment Receipt'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Invoice Remaining Balance: ₹${invoice.balanceAmount}'),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Amount Received (₹) *',
                    controller: _amountReceivedController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Payment Reference / Transaction ID *',
                    controller: _refNoController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdownField<String>(
                    label: 'Payment Mode',
                    value: _paymentMode,
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Bank', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI / QR')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                    ],
                    onChanged: (val) => setDialogState(() => _paymentMode = val ?? 'Bank'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                AppButton(
                  label: 'Save Receipt',
                  onPressed: () async {
                    final double amount = double.tryParse(_amountReceivedController.text) ?? 0.0;
                    if (amount <= 0 || amount > invoice.balanceAmount) {
                      AppFeedback.showSnackbar(context, message: 'Invalid payment amount!', isError: true);
                      return;
                    }

                    final receipt = Receipt(
                      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
                      customerId: invoice.customerId,
                      customerName: invoice.customerName,
                      amount: amount,
                      date: _paymentDate,
                      paymentMode: _paymentMode,
                      referenceNumber: _refNoController.text,
                      notes: 'Paid against invoice ${invoice.invoiceNumber}',
                      allocations: [
                        ReceiptAllocation(
                          invoiceId: invoice.id,
                          amountAllocated: amount,
                        ),
                      ],
                    );

                    await ref.read(billingRepositoryProvider.notifier).addReceipt(receipt);
                    
                    if (mounted) {
                      Navigator.pop(ctx);
                      AppFeedback.showSnackbar(context, message: 'Payment receipt recorded successfully!');
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

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final activeBiz = ref.watch(businessProvider).activeBusiness;

    final invoice = billingState.invoices.firstWhere(
      (inv) => inv.id == widget.invoiceId,
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

    if (invoice.id.isEmpty) {
      return const Scaffold(body: Center(child: Text('Invoice not found.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppPageHeader(
                  title: invoice.isCreditNote ? 'Credit Note: ${invoice.invoiceNumber}' : 'Sales Invoice: ${invoice.invoiceNumber}',
                  description: 'Status: ${invoice.status.name.toUpperCase()} • Customer: ${invoice.customerName}',
                  breadcrumbs: ['Dashboard', 'Sales', invoice.invoiceNumber],
                  actions: [
                    if (invoice.status == InvoiceStatus.draft)
                      AppButton(
                        label: 'Confirm Invoice',
                        icon: Icons.check_circle_outline,
                        onPressed: () async {
                          await ref.read(billingRepositoryProvider.notifier).confirmInvoice(invoice.id);
                          if (mounted) AppFeedback.showSnackbar(context, message: 'Invoice confirmed successfully!');
                        },
                      ),
                    if (invoice.status != InvoiceStatus.cancelled)
                      AppButton(
                        label: 'Share PDF',
                        icon: Icons.share_outlined,
                        type: AppButtonType.secondary,
                        onPressed: () async {
                          if (activeBiz != null) {
                            await InvoicePdfService.share(invoice, activeBiz);
                          }
                        },
                      ),
                    if (invoice.status != InvoiceStatus.paid &&
                        invoice.status != InvoiceStatus.cancelled &&
                        invoice.status != InvoiceStatus.draft)
                      AppButton(
                        label: 'Record Payment',
                        icon: Icons.payments_outlined,
                        type: AppButtonType.primary,
                        onPressed: () => _showReceivePaymentDialog(invoice),
                      ),
                  ],
                ),

                // Invoice Meta Info
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Billed To:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text(invoice.customerName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              Text(invoice.billingAddress),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Invoice Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 4),
                              Text('Date: ${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}'),
                              Text('Place of Supply: ${invoice.placeOfSupply}'),
                              Text('Payment Mode: ${invoice.paymentMode}'),
                              if (invoice.isCreditNote)
                                Text('Original Invoice ID: ${invoice.originalInvoiceId}', style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Items list
                AppCard(
                  padding: EdgeInsets.zero,
                  child: AppTable<InvoiceItem>(
                    items: invoice.items,
                    emptyMessage: 'No items in this invoice.',
                    columns: [
                      TableColumnSpec<InvoiceItem>(
                        label: 'Item Name / Details',
                        flex: 2,
                        cellBuilder: (it) => Text(it.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      TableColumnSpec<InvoiceItem>(
                        label: 'HSN/SAC',
                        cellBuilder: (it) => Text(it.hsnSac),
                      ),
                      TableColumnSpec<InvoiceItem>(
                        label: 'Quantity',
                        isNumeric: true,
                        cellBuilder: (it) => Text('${it.quantity} ${it.unit}'),
                      ),
                      TableColumnSpec<InvoiceItem>(
                        label: 'Rate',
                        isNumeric: true,
                        cellBuilder: (it) => Text('₹${it.rate.toStringAsFixed(2)}'),
                      ),
                      TableColumnSpec<InvoiceItem>(
                        label: 'Discount',
                        isNumeric: true,
                        cellBuilder: (it) => Text('${it.discountPercentage.toStringAsFixed(0)}%'),
                      ),
                      TableColumnSpec<InvoiceItem>(
                        label: 'Taxable Val',
                        isNumeric: true,
                        cellBuilder: (it) => Text('₹${it.taxableValue.toStringAsFixed(2)}'),
                      ),
                      TableColumnSpec<InvoiceItem>(
                        label: 'GST Rate',
                        cellBuilder: (it) => Text('${it.gstRate.toStringAsFixed(0)}%'),
                      ),
                      TableColumnSpec<InvoiceItem>(
                        label: 'GST Amt',
                        isNumeric: true,
                        cellBuilder: (it) => Text('₹${(it.cgst + it.sgst + it.igst).toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Totals summary panel
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Terms & Conditions:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(invoice.termsConditions.isNotEmpty ? invoice.termsConditions : 'No terms specified.'),
                            if (invoice.notes.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              const Text('Internal Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(invoice.notes),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 350,
                      child: AppCard(
                        child: Column(
                          children: [
                            _buildSummaryRow('Taxable Amount:', '₹${invoice.taxableAmount.toStringAsFixed(2)}'),
                            if (invoice.cgst > 0) _buildSummaryRow('CGST Amount:', '₹${invoice.cgst.toStringAsFixed(2)}'),
                            if (invoice.sgst > 0) _buildSummaryRow('SGST Amount:', '₹${invoice.sgst.toStringAsFixed(2)}'),
                            if (invoice.igst > 0) _buildSummaryRow('IGST Amount:', '₹${invoice.igst.toStringAsFixed(2)}'),
                            if (invoice.cess > 0) _buildSummaryRow('Cess Amount:', '₹${invoice.cess.toStringAsFixed(2)}'),
                            _buildSummaryRow('Round Off:', '₹${invoice.roundOff.toStringAsFixed(2)}'),
                            const Divider(),
                            _buildSummaryRow(
                              'Grand Total:',
                              '₹${invoice.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                            _buildSummaryRow(
                              'Balance Remaining:',
                              '₹${invoice.balanceAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: invoice.balanceAmount > 0 && invoice.status != InvoiceStatus.cancelled ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Cancel Document Action
                if (invoice.status != InvoiceStatus.cancelled) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        label: 'Cancel & Reverse Invoice',
                        icon: Icons.cancel_outlined,
                        type: AppButtonType.danger,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Invoice'),
                              content: Text('Are you sure you want to cancel invoice ${invoice.invoiceNumber}? This will reverse all stock changes and ledger balances.'),
                              actions: [
                                TextButton(
                                  child: const Text('Back'),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                                AppButton(
                                  label: 'Confirm Cancellation',
                                  type: AppButtonType.danger,
                                  onPressed: () async {
                                    await ref.read(billingRepositoryProvider.notifier).cancelInvoice(invoice.id);
                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      AppFeedback.showSnackbar(context, message: 'Invoice cancelled and balances reversed!');
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {TextStyle? style}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style ?? const TextStyle(color: Colors.grey)),
          Text(value, style: style ?? const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
