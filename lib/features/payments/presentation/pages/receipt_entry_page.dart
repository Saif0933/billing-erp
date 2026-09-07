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
import '../../../customer/presentation/providers/customer_provider.dart';
import '../providers/payments_provider.dart';

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
  bool _isSaving = false;
  bool _isLoadingInvoices = false;
  bool _isLoadingRef = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProvider.notifier).loadCustomers();
      _fetchNextRefNumber();
    });
  }

  Future<void> _fetchNextRefNumber() async {
    setState(() => _isLoadingRef = true);
    try {
      final apiService = ref.read(paymentsApiServiceProvider);
      final refNum = await apiService.getNextReceiptRef();
      if (mounted) {
        setState(() {
          _refController.text = refNum;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingRef = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCustomerSelected(Customer? customer) async {
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
      _isLoadingInvoices = true;
    });

    try {
      final liveInvoices = await ref.read(receiptEntryProvider.notifier).loadUnpaidInvoices(customer.id);
      if (liveInvoices.isNotEmpty && mounted) {
        final updatedInvoices = liveInvoices.map((dto) {
          final existing = billingState.invoices.cast<Invoice?>().firstWhere(
            (i) => i?.id == dto.id,
            orElse: () => null,
          );
          if (existing != null) {
            return existing.copyWith(
              balanceAmount: dto.balanceAmount,
            );
          }
          return Invoice(
            id: dto.id,
            invoiceNumber: dto.invoiceNumber,
            invoiceDate: dto.invoiceDate,
            customerId: customer.id,
            customerName: customer.name,
            billingAddress: customer.billingAddress,
            shippingAddress: customer.shippingAddress,
            placeOfSupply: customer.state,
            items: const [],
            taxableAmount: dto.grandTotal,
            cgst: 0,
            sgst: 0,
            igst: 0,
            cess: 0,
            roundOff: 0,
            grandTotal: dto.grandTotal,
            balanceAmount: dto.balanceAmount,
            paymentMode: 'Bank',
            status: dto.paymentStatus == 'PAID'
                ? InvoiceStatus.paid
                : (dto.paymentStatus == 'PARTIALLY_PAID'
                    ? InvoiceStatus.partiallyPaid
                    : InvoiceStatus.draft),
            notes: '',
            termsConditions: '',
          );
        }).toList();

        setState(() {
          _unpaidInvoices = updatedInvoices;
        });
      }
    } catch (_) {
      // Graceful fallback to local invoices
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInvoices = false;
        });
      }
    }
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

    // If invoices are allocated, ensure allocated sum does not exceed total receipt amount
    if (_allocations.isNotEmpty && allocatedSum > totalAmount + 0.01) {
      AppFeedback.showSnackbar(
        context,
        message: 'The total allocated amount (₹${allocatedSum.toStringAsFixed(2)}) cannot exceed the receipt amount (₹${totalAmount.toStringAsFixed(2)})!',
        isError: true,
      );
      return;
    }

    // Over-allocation check per individual invoice
    for (var entry in _allocations.entries) {
      final inv = _unpaidInvoices.firstWhere((i) => i.id == entry.key);
      if (entry.value > inv.balanceAmount + 0.01) {
        AppFeedback.showSnackbar(
          context,
          message: 'Allocated amount for ${inv.invoiceNumber} exceeds outstanding balance!',
          isError: true,
        );
        return;
      }
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        await ref.read(receiptEntryProvider.notifier).submitReceipt(
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          amount: totalAmount,
          date: _receiptDate,
          paymentMode: _paymentMode,
          referenceNumber: _refController.text.isNotEmpty ? _refController.text : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          allocations: _allocations,
        );

        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Receipt Entry saved successfully!');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Failed to record receipt: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final availableCustomers = customerState.customers;

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
                        if (availableCustomers.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people_outline, size: 20, color: Color(0xFF64748B)),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'No customers found in database.',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                                  label: const Text('Add Customer'),
                                  onPressed: () => context.push('/customers/new'),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          AppDropdownField<Customer>(
                            label: 'Customer *',
                            value: availableCustomers.contains(_selectedCustomer) ? _selectedCustomer : null,
                            items: availableCustomers.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text('${c.name} (Outstanding: ₹${c.currentBalance.toStringAsFixed(2)})'),
                              );
                            }).toList(),
                            onChanged: _onCustomerSelected,
                          ),
                        ],
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
                                hintText: _isLoadingRef ? 'Generating...' : 'e.g. REC-20260907-0001',
                                suffixIcon: IconButton(
                                  icon: _isLoadingRef
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.refresh, size: 18),
                                  tooltip: 'Regenerate Reference ID',
                                  onPressed: _isLoadingRef ? null : _fetchNextRefNumber,
                                ),
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
                              Row(
                                children: [
                                  Text('Invoice Allocation Engine', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                  if (_isLoadingInvoices) ...[
                                    const SizedBox(width: 8),
                                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                  ],
                                ],
                              ),
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
                            emptyMessage: 'This customer has no unpaid invoices. Receipt will be recorded on-account / advance.',
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
                      AppButton(
                        label: 'Save Entry',
                        isLoading: _isSaving,
                        onPressed: _saveReceipt,
                      ),
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
