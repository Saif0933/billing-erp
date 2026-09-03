import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../domain/models/purchase_return_model.dart';
import '../providers/purchase_return_provider.dart';

class CreatePurchaseReturnDialog extends ConsumerStatefulWidget {
  const CreatePurchaseReturnDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CreatePurchaseReturnDialog(),
    );
  }

  @override
  ConsumerState<CreatePurchaseReturnDialog> createState() => _CreatePurchaseReturnDialogState();
}

class _CreatePurchaseReturnDialogState extends ConsumerState<CreatePurchaseReturnDialog> {
  final _formKey = GlobalKey<FormState>();
  final _debitNoteNoController = TextEditingController(text: 'DN/26-27/006');
  final _originalBillController = TextEditingController(text: 'PUR-2026-0080');
  final _supplierNameController = TextEditingController(text: 'Apex Electronics Ltd');
  final _productNameController = TextEditingController(text: 'Wireless Bluetooth Headphones');
  final _qtyController = TextEditingController(text: '2');
  final _rateController = TextEditingController(text: '1500.00');
  final _reasonController = TextEditingController(text: 'Defective product / manufacturing fault');

  @override
  void dispose() {
    _debitNoteNoController.dispose();
    _originalBillController.dispose();
    _supplierNameController.dispose();
    _productNameController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final qty = double.tryParse(_qtyController.text) ?? 1.0;
    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final subtotal = qty * rate;
    final tax = subtotal * 0.18;
    final total = subtotal + tax;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF15803D).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.assignment_return_outlined, color: Color(0xFF15803D), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Record Purchase Return',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Form fields
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Debit Note # & Original Bill #
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _debitNoteNoController,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Debit Note # *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _originalBillController,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Original Purchase Bill # *',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Supplier Name
                      TextFormField(
                        controller: _supplierNameController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Supplier Name *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Item Details Header
                      const Text(
                        'Item Return Details',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Product Name
                      TextFormField(
                        controller: _productNameController,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Product / Item Name *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),

                      // Qty & Rate
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _qtyController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Return Qty',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (val) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _rateController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Unit Rate (₹)',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onChanged: (val) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Return Reason
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Return Reason / Notes *',
                          hintText: 'e.g. Defective items, transit damage...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Real-time Calculation Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.2) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal:', style: TextStyle(fontSize: 12)),
                                Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('GST Tax (18%):', style: TextStyle(fontSize: 12)),
                                Text('₹${tax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Debit Note Value:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  '₹${total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF15803D)),
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
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text('Issue Debit Note', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        final newReturn = PurchaseReturn(
                          id: 'pr_${DateTime.now().millisecondsSinceEpoch}',
                          debitNoteNumber: _debitNoteNoController.text.trim(),
                          originalPurchaseId: 'pur_manual',
                          originalPurchaseBillNumber: _originalBillController.text.trim(),
                          supplierId: 'sup_manual',
                          supplierName: _supplierNameController.text.trim(),
                          returnDate: DateTime.now(),
                          items: [
                            PurchaseReturnItem(
                              id: 'pri_${DateTime.now().millisecondsSinceEpoch}',
                              productId: 'prod_manual',
                              productName: _productNameController.text.trim(),
                              quantityReturned: qty,
                              unitPrice: rate,
                              gstRate: 18.0,
                              taxAmount: tax,
                              totalAmount: total,
                              returnReason: _reasonController.text.trim(),
                            ),
                          ],
                          subtotal: subtotal,
                          taxAmount: tax,
                          totalAmount: total,
                          amountAdjusted: 0.0,
                          status: PurchaseReturnStatus.confirmed,
                          returnReason: _reasonController.text.trim(),
                        );

                        ref.read(purchaseReturnsProvider.notifier).addReturn(newReturn);
                        Navigator.pop(context);
                        AppFeedback.showSnackbar(
                          context,
                          message: 'Debit Note ${_debitNoteNoController.text} issued successfully!',
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
