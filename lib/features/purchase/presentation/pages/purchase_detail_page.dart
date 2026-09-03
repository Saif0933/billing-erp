import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class PurchaseDetailPage extends ConsumerStatefulWidget {
  final String purchaseId;
  const PurchaseDetailPage({super.key, required this.purchaseId});

  @override
  ConsumerState<PurchaseDetailPage> createState() => _PurchaseDetailPageState();
}

class _PurchaseDetailPageState extends ConsumerState<PurchaseDetailPage> {
  final _amountPaidController = TextEditingController();
  final _refNoController = TextEditingController();
  String _paymentMode = 'Bank';
  DateTime _paymentDate = DateTime.now();

  @override
  void dispose() {
    _amountPaidController.dispose();
    _refNoController.dispose();
    super.dispose();
  }

  void _showRecordPaymentDialog(Purchase purchase) {
    _amountPaidController.text = purchase.balanceAmount.toString();
    _refNoController.text = 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Outward Payment'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Purchase Remaining Payable: ₹${purchase.balanceAmount}'),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Amount Paid (₹) *',
                    controller: _amountPaidController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Reference / Transaction ID *',
                    controller: _refNoController,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdownField<String>(
                    label: 'Payment Mode',
                    value: _paymentMode,
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Bank', child: Text('Bank Transfer')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                      DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
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
                  label: 'Save Payment',
                  onPressed: () async {
                    final double amount = double.tryParse(_amountPaidController.text) ?? 0.0;
                    if (amount <= 0 || amount > purchase.balanceAmount) {
                      AppFeedback.showSnackbar(context, message: 'Invalid payment amount!', isError: true);
                      return;
                    }

                    final payment = Payment(
                      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
                      supplierId: purchase.supplierId,
                      supplierName: purchase.supplierName,
                      amount: amount,
                      date: _paymentDate,
                      paymentMode: _paymentMode,
                      referenceNumber: _refNoController.text,
                      notes: 'Paid against bill ${purchase.purchaseNumber}',
                      allocations: [
                        PaymentAllocation(
                          purchaseId: purchase.id,
                          amountAllocated: amount,
                        ),
                      ],
                    );

                    await ref.read(billingRepositoryProvider.notifier).addPayment(payment);

                    if (mounted) {
                      Navigator.pop(ctx);
                      AppFeedback.showSnackbar(context, message: 'Supplier payment recorded successfully!');
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

    final purchase = billingState.purchases.firstWhere(
      (p) => p.id == widget.purchaseId,
      orElse: () => Purchase(
        id: '',
        purchaseNumber: 'Not Found',
        supplierInvoiceNumber: '',
        purchaseDate: DateTime.now(),
        supplierId: '',
        supplierName: '',
        items: [],
        taxableAmount: 0,
        cgst: 0,
        sgst: 0,
        igst: 0,
        cess: 0,
        freightCharges: 0,
        otherCharges: 0,
        roundOff: 0,
        grandTotal: 0,
        balanceAmount: 0,
        paymentMode: '',
        status: PurchaseStatus.draft,
        notes: '',
      ),
    );

    if (purchase.id.isEmpty) {
      return const Scaffold(body: Center(child: Text('Purchase record not found.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(purchase.purchaseNumber),
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
                  title: purchase.isDebitNote ? 'Debit Note: ${purchase.purchaseNumber}' : 'Purchase Bill: ${purchase.purchaseNumber}',
                  description: 'Status: ${purchase.status.name.toUpperCase()} • Supplier: ${purchase.supplierName}',
                  breadcrumbs: ['Dashboard', 'Purchase', purchase.purchaseNumber],
                  actions: [
                    if (purchase.status == PurchaseStatus.draft)
                      AppButton(
                        label: 'Confirm Bill & Add Stock',
                        icon: Icons.check_circle_outline,
                        onPressed: () async {
                          await ref.read(billingRepositoryProvider.notifier).confirmPurchase(purchase.id);
                          if (mounted) AppFeedback.showSnackbar(context, message: 'Purchase bill confirmed and inventory updated!');
                        },
                      ),
                    if (purchase.status != PurchaseStatus.paid &&
                        purchase.status != PurchaseStatus.cancelled &&
                        purchase.status != PurchaseStatus.draft)
                      AppButton(
                        label: 'Record Outward Payment',
                        icon: Icons.payment_outlined,
                        onPressed: () => _showRecordPaymentDialog(purchase),
                      ),
                  ],
                ),

                // Bill Metadata Card
                AppCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 600;

                      final supplierWidget = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Supplier Account:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(purchase.supplierName, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text('Supplier Invoice Ref: ${purchase.supplierInvoiceNumber}'),
                        ],
                      );

                      final detailsWidget = Column(
                        crossAxisAlignment: isSmall ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                        children: [
                          const Text('Bill Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('Date: ${purchase.purchaseDate.day}/${purchase.purchaseDate.month}/${purchase.purchaseDate.year}'),
                          Text('Payment Mode: ${purchase.paymentMode}'),
                          if (purchase.isDebitNote)
                            Text('Original Bill: ${purchase.originalPurchaseId}', style: const TextStyle(color: Colors.red)),
                        ],
                      );

                      if (isSmall) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            supplierWidget,
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            detailsWidget,
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: supplierWidget),
                          const SizedBox(width: 16),
                          Expanded(child: detailsWidget),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Items list
                AppCard(
                  padding: EdgeInsets.zero,
                  child: AppTable<PurchaseItem>(
                    items: purchase.items,
                    emptyMessage: 'No products in this bill.',
                    columns: [
                      TableColumnSpec<PurchaseItem>(
                        label: 'Product Name',
                        flex: 2,
                        cellBuilder: (it) => Text(it.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      TableColumnSpec<PurchaseItem>(
                        label: 'HSN Code',
                        cellBuilder: (it) => Text(it.hsnCode),
                      ),
                      TableColumnSpec<PurchaseItem>(
                        label: 'Quantity',
                        isNumeric: true,
                        cellBuilder: (it) => Text('${it.quantity} ${it.unit}'),
                      ),
                      TableColumnSpec<PurchaseItem>(
                        label: 'Rate',
                        isNumeric: true,
                        cellBuilder: (it) => Text('₹${it.rate.toStringAsFixed(2)}'),
                      ),
                      TableColumnSpec<PurchaseItem>(
                        label: 'Discount',
                        isNumeric: true,
                        cellBuilder: (it) => Text('${it.discountPercentage.toStringAsFixed(0)}%'),
                      ),
                      TableColumnSpec<PurchaseItem>(
                        label: 'Taxable Val',
                        isNumeric: true,
                        cellBuilder: (it) => Text('₹${it.taxableValue.toStringAsFixed(2)}'),
                      ),
                      TableColumnSpec<PurchaseItem>(
                        label: 'GST Rate',
                        cellBuilder: (it) => Text('${it.gstRate.toStringAsFixed(0)}%'),
                      ),
                      TableColumnSpec<PurchaseItem>(
                        label: 'GST Amt',
                        isNumeric: true,
                        cellBuilder: (it) => Text('₹${(it.cgst + it.sgst + it.igst).toStringAsFixed(2)}'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Totals
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 700;

                    final notesWidget = AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Audit & Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(purchase.notes.isNotEmpty ? purchase.notes : 'No audit details specified.'),
                        ],
                      ),
                    );

                    final totalsWidget = AppCard(
                      child: Column(
                        children: [
                          _buildSummaryRow('Taxable Amount:', '₹${purchase.taxableAmount.toStringAsFixed(2)}'),
                          if (purchase.cgst > 0) _buildSummaryRow('CGST Amount:', '₹${purchase.cgst.toStringAsFixed(2)}'),
                          if (purchase.sgst > 0) _buildSummaryRow('SGST Amount:', '₹${purchase.sgst.toStringAsFixed(2)}'),
                          if (purchase.igst > 0) _buildSummaryRow('IGST Amount:', '₹${purchase.igst.toStringAsFixed(2)}'),
                          if (purchase.cess > 0) _buildSummaryRow('Cess Amount:', '₹${purchase.cess.toStringAsFixed(2)}'),
                          _buildSummaryRow('Freight Charges:', '₹${purchase.freightCharges.toStringAsFixed(2)}'),
                          _buildSummaryRow('Other Charges:', '₹${purchase.otherCharges.toStringAsFixed(2)}'),
                          _buildSummaryRow('Round Off:', '₹${purchase.roundOff.toStringAsFixed(2)}'),
                          const Divider(),
                          _buildSummaryRow(
                            'Grand Total:',
                            '₹${purchase.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          _buildSummaryRow(
                            'Payable Remaining:',
                            '₹${purchase.balanceAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: purchase.balanceAmount > 0 && purchase.status != PurchaseStatus.cancelled ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    );

                    if (isSmall) {
                      return Column(
                        children: [
                          notesWidget,
                          const SizedBox(height: AppSpacing.md),
                          totalsWidget,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: notesWidget),
                        const SizedBox(width: AppSpacing.md),
                        SizedBox(width: 350, child: totalsWidget),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Cancel Bill action
                if (purchase.status != PurchaseStatus.cancelled) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        label: 'Cancel & Reverse Bill',
                        icon: Icons.cancel_outlined,
                        type: AppButtonType.danger,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel Purchase Bill'),
                              content: Text('Are you sure you want to cancel bill ${purchase.purchaseNumber}? This will reverse all stock increases and ledger balances.'),
                              actions: [
                                TextButton(
                                  child: const Text('Back'),
                                  onPressed: () => Navigator.pop(ctx),
                                ),
                                AppButton(
                                  label: 'Confirm Cancellation',
                                  type: AppButtonType.danger,
                                  onPressed: () async {
                                    await ref.read(billingRepositoryProvider.notifier).cancelPurchase(purchase.id);
                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      AppFeedback.showSnackbar(context, message: 'Purchase bill cancelled and balances reversed!');
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
