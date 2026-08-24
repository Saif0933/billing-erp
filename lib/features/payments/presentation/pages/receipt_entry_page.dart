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

class ReceiptEntryPage extends ConsumerStatefulWidget {
  const ReceiptEntryPage({super.key});

  @override
  ConsumerState<ReceiptEntryPage> createState() => _ReceiptEntryPageState();
}

class _ReceiptEntryPageState extends ConsumerState<ReceiptEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  DateTime _receiptDate = DateTime.now();
  String _paymentMode = 'Bank';

  // Outstanding invoices for the selected customer, and the manually allocated amounts for each
  List<Invoice> _unpaidInvoices = [];
  final Map<String, double> _allocations = {}; // invoiceId -> amountAllocated

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCustomerSelected(Customer? customer) {
    if (customer == null) return;
    final billingState = ref.read(billingRepositoryProvider);
    final customerInvoices = billingState.invoices
        .where((inv) => inv.customerId == customer.id && inv.status != InvoiceStatus.paid && inv.status != InvoiceStatus.cancelled)
        .toList();

    setState(() {
      _selectedCustomer = customer;
      _unpaidInvoices = customerInvoices;
      _allocations.clear();
      _amountController.clear();
    });
  }

  void _autoAllocate() {
    final double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) {
      AppFeedback.showSnackbar(context, message: 'Please enter a valid amount first!', isError: true);
      return;
    }

    setState(() {
      _allocations.clear();
      double remaining = totalAmount;
      // Sort oldest invoices first based on date
      final sortedInvoices = List<Invoice>.from(_unpaidInvoices)..sort((a, b) => a.invoiceDate.compareTo(b.invoiceDate));
      for (var inv in sortedInvoices) {
        if (remaining <= 0) break;
        final double alloc = remaining >= inv.balanceAmount ? inv.balanceAmount : remaining;
        _allocations[inv.id] = double.parse(alloc.toStringAsFixed(2));
        remaining -= alloc;
      }
    });
  }

  void _saveReceipt() async {
    if (_selectedCustomer == null) {
      AppFeedback.showSnackbar(context, message: 'Please select a customer!', isError: true);
      return;
    }

    final double totalAmount = double.tryParse(_amountController.text) ?? 0.0;
    if (totalAmount <= 0) {
      AppFeedback.showSnackbar(context, message: 'Please enter a valid receipt amount!', isError: true);
      return;
    }

    final double allocatedSum = _allocations.values.fold(0.0, (sum, val) => sum + val);
    if (double.parse(allocatedSum.toStringAsFixed(2)) != double.parse(totalAmount.toStringAsFixed(2))) {
      AppFeedback.showSnackbar(
        context,
        message: 'The total allocated amount (₹${allocatedSum.toStringAsFixed(2)}) must equal the receipt amount (₹${totalAmount.toStringAsFixed(2)})!',
        isError: true,
      );
      return;
    }

    // Over-allocation check
    for (var entry in _allocations.entries) {
      final inv = _unpaidInvoices.firstWhere((i) => i.id == entry.key);
      if (entry.value > inv.balanceAmount) {
        AppFeedback.showSnackbar(
          context,
          message: 'Allocated amount for ${inv.invoiceNumber} exceeds outstanding balance!',
          isError: true,
        );
        return;
      }
    }

    if (_formKey.currentState!.validate()) {
      final receipt = Receipt(
        id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        amount: totalAmount,
        date: _receiptDate,
        paymentMode: _paymentMode,
        referenceNumber: _refController.text.isNotEmpty
            ? _refController.text
            : 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        notes: _notesController.text,
        allocations: _allocations.entries.map((e) {
          return ReceiptAllocation(invoiceId: e.key, amountAllocated: e.value);
        }).toList(),
      );

      await ref.read(billingRepositoryProvider.notifier).addReceipt(receipt);

      if (mounted) {
        AppFeedback.showSnackbar(context, message: 'Receipt Entry saved successfully!');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Record Customer Receipt')),
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
                    title: 'New Payment Receipt',
                    description: 'Record outward cash flow, allocating balances to unpaid client invoices.',
                    breadcrumbs: const ['Dashboard', 'Payments', 'Receipt Entry'],
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Receipt Parameters', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.lg),
                        AppDropdownField<Customer>(
                          label: 'Customer *',
                          value: _selectedCustomer,
                          items: billingState.customers.map((c) {
                            return DropdownMenuItem(value: c, child: Text('${c.name} (Outstanding: ₹${c.currentBalance})'));
                          }).toList(),
                          onChanged: _onCustomerSelected,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ResponsiveRow(
                          children: [
                            Expanded(
                              child: AppTextField(
                                label: 'Receipt Amount (₹) *',
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                              ),
                            ),
                            Expanded(
                              child: AppTextField(
                                label: 'Receipt Ref No / Txn ID',
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
                                  DropdownMenuItem(value: 'UPI / QR', child: Text('UPI / QR')),
                                  DropdownMenuItem(value: 'Card', child: Text('Card')),
                                ],
                                onChanged: (val) => setState(() => _paymentMode = val ?? 'Bank'),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Receipt Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                  TextButton.icon(
                                    icon: const Icon(Icons.calendar_month_outlined),
                                    label: Text('${_receiptDate.day}/${_receiptDate.month}/${_receiptDate.year}'),
                                    onPressed: () async {
                                      final selected = await showDatePicker(
                                        context: context,
                                        initialDate: _receiptDate,
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2030),
                                      );
                                      if (selected != null) setState(() => _receiptDate = selected);
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
                  if (_selectedCustomer != null) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Invoice Allocation Engine', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                              AppButton(
                                label: 'Auto-Allocate Outstanding',
                                type: AppButtonType.secondary,
                                onPressed: _autoAllocate,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTable<Invoice>(
                            items: _unpaidInvoices,
                            emptyMessage: 'This customer has no unpaid invoices to allocate.',
                            columns: [
                              TableColumnSpec<Invoice>(
                                label: 'Invoice No.',
                                cellBuilder: (inv) => Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              TableColumnSpec<Invoice>(
                                label: 'Date',
                                cellBuilder: (inv) => Text('${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year}'),
                              ),
                              TableColumnSpec<Invoice>(
                                label: 'Total Value',
                                isNumeric: true,
                                cellBuilder: (inv) => Text('₹${inv.grandTotal.toStringAsFixed(2)}'),
                              ),
                              TableColumnSpec<Invoice>(
                                label: 'Outstanding Bal',
                                isNumeric: true,
                                cellBuilder: (inv) => Text('₹${inv.balanceAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                              ),
                              TableColumnSpec<Invoice>(
                                label: 'Allocation Amount (₹)',
                                flex: 2,
                                cellBuilder: (inv) {
                                  final controller = TextEditingController(
                                    text: _allocations[inv.id]?.toString() ?? '0.0',
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
                                            _allocations[inv.id] = allocAmt;
                                          } else {
                                            _allocations.remove(inv.id);
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
                      AppButton(label: 'Save Entry', onPressed: _saveReceipt),
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
