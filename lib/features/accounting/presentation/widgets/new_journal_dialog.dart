import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/general_journal_provider.dart';

class NewJournalDialog extends ConsumerStatefulWidget {
  const NewJournalDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const NewJournalDialog(),
    );
  }

  @override
  ConsumerState<NewJournalDialog> createState() => _NewJournalDialogState();
}

class _NewJournalDialogState extends ConsumerState<NewJournalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _narrationController = TextEditingController();
  final _refController = TextEditingController();
  final _debitAmountController = TextEditingController(text: '0.00');
  final _creditAmountController = TextEditingController(text: '0.00');

  String? _selectedDebitAccountId;
  String? _selectedCreditAccountId;
  String _selectedType = 'Standard';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(generalJournalNotifierProvider.notifier).fetchAccounts();
    });
  }

  @override
  void dispose() {
    _narrationController.dispose();
    _refController.dispose();
    _debitAmountController.dispose();
    _creditAmountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final debitVal = double.tryParse(_debitAmountController.text.trim()) ?? 0.0;
    final creditVal = double.tryParse(_creditAmountController.text.trim()) ?? 0.0;

    if (debitVal <= 0 || creditVal <= 0) {
      AppFeedback.showSnackbar(
        context,
        message: 'Both Debit and Credit amounts must be greater than zero.',
        isError: true,
      );
      return;
    }

    if ((debitVal - creditVal).abs() > 0.01) {
      AppFeedback.showSnackbar(
        context,
        message: 'Out of Balance! Debit (₹${debitVal.toStringAsFixed(2)}) must equal Credit (₹${creditVal.toStringAsFixed(2)}).',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final dto = CreateJournalEntryDto(
      entryDate: DateTime.now(),
      type: parseJournalType(_selectedType),
      reference: _refController.text.trim(),
      narration: _narrationController.text.trim(),
      status: JournalEntryStatus.posted,
      debitAccountId: _selectedDebitAccountId,
      creditAccountId: _selectedCreditAccountId,
      debitAmount: debitVal,
      creditAmount: creditVal,
    );

    final success = await ref.read(generalJournalNotifierProvider.notifier).createJournalEntry(dto);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      AppFeedback.showSnackbar(
        context,
        message: 'Journal entry posted successfully!',
      );
    } else {
      final err = ref.read(generalJournalNotifierProvider).error ?? 'Failed to post journal entry';
      AppFeedback.showSnackbar(
        context,
        message: err,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generalJournalNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultAccounts = [
      const AccountDropdownItemDto(id: 'acc_1001', name: '1.1 Cash in Hand', code: '1001', type: 'CASH'),
      const AccountDropdownItemDto(id: 'acc_1002', name: '1.2 Bank Accounts', code: '1002', type: 'BANK'),
      const AccountDropdownItemDto(id: 'acc_1003', name: '1.3 Accounts Receivable', code: '1003', type: 'CUSTOMER'),
      const AccountDropdownItemDto(id: 'acc_2001', name: '2.1 Accounts Payable', code: '2001', type: 'SUPPLIER'),
      const AccountDropdownItemDto(id: 'acc_3001', name: '3.1 Owner Capital', code: '3001', type: 'OTHER'),
      const AccountDropdownItemDto(id: 'acc_4001', name: '4.1 Sales Revenue', code: '4001', type: 'SALES'),
      const AccountDropdownItemDto(id: 'acc_5001', name: '5.1 Salaries & Wages', code: '5001', type: 'EXPENSE'),
      const AccountDropdownItemDto(id: 'acc_5002', name: '5.2 Rent & Utilities', code: '5002', type: 'EXPENSE'),
    ];

    final accounts = state.availableAccounts.isNotEmpty ? state.availableAccounts : defaultAccounts;

    // Set initial accounts if not yet set
    _selectedDebitAccountId ??= accounts.first.id;
    _selectedCreditAccountId ??= accounts.length > 1 ? accounts[1].id : accounts.first.id;

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
                          child: const Icon(Icons.post_add, color: Color(0xFF15803D), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Create Journal Entry',
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
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
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
                      // Journal Type Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Journal Type',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Standard', child: Text('Standard Journal')),
                          DropdownMenuItem(value: 'Adjustment', child: Text('Adjustment Journal')),
                          DropdownMenuItem(value: 'Recurring', child: Text('Recurring Journal')),
                        ],
                        onChanged: _isSubmitting ? null : (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Reference Number & Narration
                      TextFormField(
                        controller: _refController,
                        enabled: !_isSubmitting,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Reference Number',
                          hintText: 'e.g. JV-57 or Invoice Ref',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _narrationController,
                        enabled: !_isSubmitting,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Narration / Description *',
                          hintText: 'Describe this transaction...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Double Entry Legs Header
                      const Text(
                        'Accounting Distribution (Dr = Cr)',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      // Debit Account + Amount
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDebitAccountId,
                              decoration: const InputDecoration(
                                labelText: 'Debit Account (Dr)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: accounts.map((acc) {
                                return DropdownMenuItem(
                                  value: acc.id,
                                  child: Text(acc.name, style: const TextStyle(fontSize: 12.5)),
                                );
                              }).toList(),
                              onChanged: _isSubmitting ? null : (val) {
                                if (val != null) setState(() => _selectedDebitAccountId = val);
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _debitAmountController,
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              decoration: const InputDecoration(
                                labelText: 'Debit Amount (₹)',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              onChanged: (val) {
                                // Auto-fill credit if credit is zero
                                final d = double.tryParse(val) ?? 0.0;
                                final c = double.tryParse(_creditAmountController.text) ?? 0.0;
                                if (c == 0.0 && d > 0) {
                                  _creditAmountController.text = d.toStringAsFixed(2);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Credit Account + Amount
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCreditAccountId,
                              decoration: const InputDecoration(
                                labelText: 'Credit Account (Cr)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: accounts.map((acc) {
                                return DropdownMenuItem(
                                  value: acc.id,
                                  child: Text(acc.name, style: const TextStyle(fontSize: 12.5)),
                                );
                              }).toList(),
                              onChanged: _isSubmitting ? null : (val) {
                                if (val != null) setState(() => _selectedCreditAccountId = val);
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _creditAmountController,
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                              decoration: const InputDecoration(
                                labelText: 'Credit Amount (₹)',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
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
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check, size: 16, color: Colors.white),
                    label: Text(
                      _isSubmitting ? 'Posting...' : 'Post Journal',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSubmitting ? null : _submitForm,
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
