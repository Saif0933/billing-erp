import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class PaymentEntryPage extends ConsumerStatefulWidget {
  const PaymentEntryPage({super.key});

  @override
  ConsumerState<PaymentEntryPage> createState() => _PaymentEntryPageState();
}

class _PaymentEntryPageState extends ConsumerState<PaymentEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _notesController = TextEditingController();

  Supplier? _selectedSupplier;
  DateTime _paymentDate = DateTime.now();
  String _paymentMode = 'Bank';

  List<Purchase> _unpaidPurchases = [];
  final Map<String, double> _allocations = {};

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSupplierSelected(Supplier? s) {
    if (s == null) return;
    final billingState = ref.read(billingRepositoryProvider);
    final supplierPurchases = billingState.purchases
        .where((p) => p.supplierId == s.id && p.status != PurchaseStatus.paid && p.status != PurchaseStatus.cancelled)
        .toList();

    setState(() {
      _selectedSupplier = s;
      _unpaidPurchases = supplierPurchases;
      _allocations.clear();
      _amountController.clear();
    });
  }

  void _autoAllocate() {
    final double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) {
      AppFeedback.showSnackbar(context, message: 'Please enter a valid payment amount first!', isError: true);
      return;
    }

    setState(() {
      _allocations.clear();
      double remaining = totalAmount;
      final sortedPurchases = List<Purchase>.from(_unpaidPurchases)..sort((a, b) => a.purchaseDate.compareTo(b.purchaseDate));
      for (var p in sortedPurchases) {
        if (remaining <= 0) break;
        final double alloc = remaining >= p.balanceAmount ? p.balanceAmount : remaining;
        _allocations[p.id] = double.parse(alloc.toStringAsFixed(2));
        remaining -= alloc;
      }
    });
  }

  void _savePayment() async {
    if (_selectedSupplier == null) {
      AppFeedback.showSnackbar(context, message: 'Please select a supplier!', isError: true);
      return;
    }

    final double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) {
      AppFeedback.showSnackbar(context, message: 'Please enter a valid payment amount!', isError: true);
      return;
    }

    final double allocatedSum = _allocations.values.fold(0.0, (sum, val) => sum + val);
    if (double.parse(allocatedSum.toStringAsFixed(2)) != double.parse(totalAmount.toStringAsFixed(2))) {
      AppFeedback.showSnackbar(
        context,
        message: 'Allocated sum (₹${allocatedSum.toStringAsFixed(2)}) does not equal total payment (₹${totalAmount.toStringAsFixed(2)})!',
        isError: true,
      );
      return;
    }

    for (var entry in _allocations.entries) {
      final pur = _unpaidPurchases.firstWhere((p) => p.id == entry.key);
      if (entry.value > pur.balanceAmount) {
        AppFeedback.showSnackbar(
          context,
          message: 'Allocated amount for bill ${pur.purchaseNumber} exceeds outstanding balance!',
          isError: true,
        );
        return;
      }
    }

    if (_formKey.currentState!.validate()) {
      final payment = Payment(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        supplierId: _selectedSupplier!.id,
        supplierName: _selectedSupplier!.name,
        amount: totalAmount,
        date: _paymentDate,
        paymentMode: _paymentMode,
        referenceNumber: _refController.text.isNotEmpty
            ? _refController.text
            : 'PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        notes: _notesController.text,
        allocations: _allocations.entries.map((e) {
          return PaymentAllocation(purchaseId: e.key, amountAllocated: e.value);
        }).toList(),
      );

      await ref.read(billingRepositoryProvider.notifier).addPayment(payment);

      if (mounted) {
        AppFeedback.showSnackbar(context, message: 'Payment Entry recorded successfully!');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Record Supplier Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppPageHeader(
                    title: 'New Payment Outward',
                    description: 'Record payments made to merchants, adjusting balances against supplier bills.',
                    breadcrumbs: const ['Dashboard', 'Payments', 'Payment Entry'],
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Payment Parameters', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.lg),
                        AppDropdownField<Supplier>(
                          label: 'Supplier *',
                          value: _selectedSupplier,
                          items: billingState.suppliers.map((s) {
                            return DropdownMenuItem(value: s, child: Text('${s.name} (Payable: ₹${s.currentBalance})'));
                          }).toList(),
                          onChanged: _onSupplierSelected,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Payment Amount (₹) *',
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Reference Code / Txn ID',
                                controller: _refController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppDropdownField<String>(
                                label: 'Payment Mode',
                                value: _paymentMode,
                                items: const [
                                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                  DropdownMenuItem(value: 'Bank', child: Text('Bank Transfer')),
                                  DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                                ],
                                onChanged: (val) => setState(() => _paymentMode = val ?? 'Bank'),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Payment Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                  TextButton.icon(
                                    icon: const Icon(Icons.calendar_month_outlined),
                                    label: Text('${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}'),
                                    onPressed: () async {
                                      final selected = await showDatePicker(
                                        context: context,
                                        initialDate: _paymentDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (selected != null) setState(() => _paymentDate = selected);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Allocation Table
                  if (_selectedSupplier != null) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Bill Allocation Engine', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              AppButton(
                                label: 'Auto-Allocate Bills',
                                type: AppButtonType.secondary,
                                onPressed: _autoAllocate,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTable<Purchase>(
                            items: _unpaidPurchases,
                            emptyMessage: 'This supplier has no outstanding purchase bills to allocate.',
                            columns: [
                              TableColumnSpec<Purchase>(
                                label: 'Bill No.',
                                cellBuilder: (pur) => Text(pur.purchaseNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              TableColumnSpec<Purchase>(
                                label: 'Date',
                                cellBuilder: (pur) => Text('${pur.purchaseDate.day}/${pur.purchaseDate.month}/${pur.purchaseDate.year}'),
                              ),
                              TableColumnSpec<Purchase>(
                                label: 'Total Value',
                                isNumeric: true,
                                cellBuilder: (pur) => Text('₹${pur.grandTotal.toStringAsFixed(2)}'),
                              ),
                              TableColumnSpec<Purchase>(
                                label: 'Payable Bal',
                                isNumeric: true,
                                cellBuilder: (pur) => Text('₹${pur.balanceAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                              ),
                              TableColumnSpec<Purchase>(
                                label: 'Allocation Amount (₹)',
                                flex: 2,
                                cellBuilder: (pur) {
                                  final controller = TextEditingController(
                                    text: _allocations[pur.id]?.toString() ?? '0.0',
                                  );
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: TextFormField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                                      onChanged: (val) {
                                        final double allocAmt = double.tryParse(val) ?? 0.0;
                                        setState(() {
                                          if (allocAmt > 0) {
                                            _allocations[pur.id] = allocAmt;
                                          } else {
                                            _allocations.remove(pur.id);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  AppCard(
                    child: AppTextField(
                      label: 'Payment Notes',
                      controller: _notesController,
                      maxLines: 2,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(label: 'Cancel', type: AppButtonType.text, onPressed: () => context.pop()),
                      const SizedBox(width: AppSpacing.md),
                      AppButton(label: 'Save Entry', onPressed: _savePayment),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
