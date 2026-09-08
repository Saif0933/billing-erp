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
import '../../../supplier/presentation/providers/supplier_provider.dart';
import '../providers/payments_provider.dart';

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
  bool _isSaving = false;
  bool _isLoadingPurchases = false;
  bool _isLoadingRef = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplierProvider.notifier).loadSuppliers();
      _fetchNextRefCode();
    });
  }

  Future<void> _fetchNextRefCode() async {
    setState(() => _isLoadingRef = true);
    try {
      final apiService = ref.read(paymentsApiServiceProvider);
      final refNum = await apiService.getNextPaymentRef();
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

  void _onSupplierSelected(Supplier? s) async {
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
      _isLoadingPurchases = true;
    });

    try {
      final livePurchases = await ref.read(paymentEntryProvider.notifier).loadUnpaidPurchases(s.id);
      if (livePurchases.isNotEmpty && mounted) {
        final updatedPurchases = livePurchases.map((dto) {
          final existing = billingState.purchases.cast<Purchase?>().firstWhere(
            (p) => p?.id == dto.id,
            orElse: () => null,
          );
          if (existing != null) {
            return existing.copyWith(
              balanceAmount: dto.balanceAmount,
            );
          }
          return Purchase(
            id: dto.id,
            purchaseNumber: dto.purchaseNumber,
            supplierInvoiceNumber: dto.supplierInvoiceNumber ?? dto.purchaseNumber,
            purchaseDate: dto.purchaseDate,
            supplierId: s.id,
            supplierName: s.name,
            items: const [],
            taxableAmount: dto.totalAmount,
            cgst: 0,
            sgst: 0,
            igst: 0,
            cess: 0,
            freightCharges: 0,
            otherCharges: 0,
            roundOff: 0,
            grandTotal: dto.totalAmount,
            balanceAmount: dto.balanceAmount,
            paymentMode: 'Bank',
            status: dto.paymentStatus == 'PAID'
                ? PurchaseStatus.paid
                : (dto.paymentStatus == 'PARTIALLY_PAID'
                    ? PurchaseStatus.partiallyPaid
                    : PurchaseStatus.confirmed),
            notes: '',
          );
        }).toList();

        setState(() {
          _unpaidPurchases = updatedPurchases;
        });
      }
    } catch (_) {
      // Graceful fallback to local purchases
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPurchases = false;
        });
      }
    }
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

    // If purchase bills are allocated, ensure allocated sum does not exceed total payment amount
    if (_allocations.isNotEmpty && allocatedSum > totalAmount + 0.01) {
      AppFeedback.showSnackbar(
        context,
        message: 'The total allocated amount (₹${allocatedSum.toStringAsFixed(2)}) cannot exceed the payment amount (₹${totalAmount.toStringAsFixed(2)})!',
        isError: true,
      );
      return;
    }

    // Over-allocation check per individual purchase bill
    for (var entry in _allocations.entries) {
      final pur = _unpaidPurchases.firstWhere((p) => p.id == entry.key);
      if (entry.value > pur.balanceAmount + 0.01) {
        AppFeedback.showSnackbar(
          context,
          message: 'Allocated amount for bill ${pur.purchaseNumber} exceeds outstanding balance!',
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
        await ref.read(paymentEntryProvider.notifier).submitPayment(
          supplierId: _selectedSupplier!.id,
          supplierName: _selectedSupplier!.name,
          amount: totalAmount,
          date: _paymentDate,
          paymentMode: _paymentMode,
          referenceNumber: _refController.text.isNotEmpty ? _refController.text : null,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          allocations: _allocations,
        );

        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Payment Entry recorded successfully!');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showSnackbar(context, message: 'Failed to record payment: $e', isError: true);
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
    final supplierState = ref.watch(supplierProvider);
    final availableSuppliers = supplierState.suppliers;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Supplier Payment')),
      body: SingleChildScrollView(
        padding: Responsive.isMobile(context)
            ? const EdgeInsets.all(AppSpacing.md)
            : const EdgeInsets.all(AppSpacing.lg),
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
                        if (availableSuppliers.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Responsive.isMobile(context)
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFF64748B)),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'No suppliers found in database.',
                                              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.add_business_outlined, size: 16),
                                        label: const Text('Add Supplier'),
                                        onPressed: () => context.push('/suppliers/new'),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const Icon(Icons.local_shipping_outlined, size: 20, color: Color(0xFF64748B)),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Text(
                                          'No suppliers found in database.',
                                          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                                        ),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.add_business_outlined, size: 16),
                                        label: const Text('Add Supplier'),
                                        onPressed: () => context.push('/suppliers/new'),
                                      ),
                                    ],
                                  ),
                          ),
                        ] else ...[
                          AppDropdownField<Supplier>(
                            label: 'Supplier *',
                            value: availableSuppliers.contains(_selectedSupplier) ? _selectedSupplier : null,
                            items: availableSuppliers.map((s) {
                              return DropdownMenuItem(value: s, child: Text('${s.name} (Payable: ₹${s.currentBalance})'));
                            }).toList(),
                            onChanged: _onSupplierSelected,
                          ),
                        ],
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
                                hintText: _isLoadingRef ? 'Generating...' : 'e.g. PAY-20260907-0001',
                                suffixIcon: IconButton(
                                  icon: _isLoadingRef
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.refresh, size: 18),
                                  tooltip: 'Regenerate Reference ID',
                                  onPressed: _isLoadingRef ? null : _fetchNextRefCode,
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
                          if (Responsive.isMobile(context))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Bill Allocation Engine',
                                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (_isLoadingPurchases) ...[
                                      const SizedBox(width: 8),
                                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppButton(
                                  label: 'Auto-Allocate Bills',
                                  type: AppButtonType.secondary,
                                  onPressed: _autoAllocate,
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text('Bill Allocation Engine', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                                    if (_isLoadingPurchases) ...[
                                      const SizedBox(width: 8),
                                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                    ],
                                  ],
                                ),
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
                            emptyMessage: 'This supplier has no outstanding purchase bills. Payment will be recorded on-account / advance.',
                            mobileCardBuilder: (pur) => _buildPurchaseCard(pur),
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

                  Responsive.isMobile(context)
                      ? Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Cancel',
                                type: AppButtonType.secondary,
                                onPressed: () => context.pop(),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: AppButton(
                                label: 'Save Entry',
                                isLoading: _isSaving,
                                onPressed: _savePayment,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppButton(label: 'Cancel', type: AppButtonType.text, onPressed: () => context.pop()),
                            const SizedBox(width: AppSpacing.md),
                            AppButton(
                              label: 'Save Entry',
                              isLoading: _isSaving,
                              onPressed: _savePayment,
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

  Widget _buildPurchaseCard(Purchase pur) {
    final controller = TextEditingController(
      text: _allocations[pur.id]?.toString() ?? '0.0',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pur.purchaseNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${pur.purchaseDate.day}/${pur.purchaseDate.month}/${pur.purchaseDate.year}',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ₹${pur.grandTotal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
              Text(
                'Payable: ₹${pur.balanceAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Allocation Amount (₹)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
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
        ],
      ),
    );
  }
}
