import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';

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

  String _selectedDebitAccount = '1001 - Cash in Hand';
  String _selectedCreditAccount = '4001 - Sales Revenue';
  String _selectedType = 'Standard';

  final _accounts = [
    '1001 - Cash in Hand',
    '1002 - Bank Accounts',
    '1003 - Accounts Receivable',
    '2001 - Accounts Payable',
    '3001 - Owner Capital',
    '4001 - Sales Revenue',
    '5001 - Salaries & Wages',
    '5002 - Rent & Utilities',
  ];

  @override
  void dispose() {
    _narrationController.dispose();
    _refController.dispose();
    _debitAmountController.dispose();
    _creditAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Reference Number & Narration
                      TextFormField(
                        controller: _refController,
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
                              initialValue: _selectedDebitAccount,
                              decoration: const InputDecoration(
                                labelText: 'Debit Account (Dr)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc, style: const TextStyle(fontSize: 12.5)))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedDebitAccount = val);
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _debitAmountController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              decoration: const InputDecoration(
                                labelText: 'Debit Amount (₹)',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
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
                              initialValue: _selectedCreditAccount,
                              decoration: const InputDecoration(
                                labelText: 'Credit Account (Cr)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              ),
                              items: _accounts.map((acc) => DropdownMenuItem(value: acc, child: Text(acc, style: const TextStyle(fontSize: 12.5)))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCreditAccount = val);
                              },
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _creditAmountController,
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                      label: const Text(
                        'Post Journal',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          Navigator.pop(context);
                          AppFeedback.showSnackbar(
                            context,
                            message: 'Journal entry posted successfully!',
                          );
                        }
                      },
                    ),
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
