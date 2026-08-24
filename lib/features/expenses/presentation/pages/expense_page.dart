import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class ExpensePage extends ConsumerStatefulWidget {
  const ExpensePage({super.key});

  @override
  ConsumerState<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends ConsumerState<ExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _vendorController = TextEditingController();
  final _amountController = TextEditingController(text: '0.0');
  final _gstController = TextEditingController(text: '0.0');
  final _notesController = TextEditingController();

  String _selectedCategory = 'Office Expenses';
  String _paymentMode = 'Bank';
  DateTime _expenseDate = DateTime.now();

  @override
  void dispose() {
    _vendorController.dispose();
    _amountController.dispose();
    _gstController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddExpenseDialog(BuildContext context) {
    _vendorController.clear();
    _amountController.text = '0.0';
    _gstController.text = '0.0';
    _notesController.clear();
    _selectedCategory = 'Office Expenses';
    _paymentMode = 'Bank';
    _expenseDate = DateTime.now();

    final categories = [
      'Rent',
      'Electricity',
      'Internet',
      'Salary',
      'Travel',
      'Advertisement',
      'Office Expenses',
      'Repairs & Maintenance',
      'Other Expenses',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record Basic Expense'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppDropdownField<String>(
                        label: 'Expense Category *',
                        value: _selectedCategory,
                        items: categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => _selectedCategory = val ?? 'Office Expenses'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Vendor / Payee Name *',
                        controller: _vendorController,
                        validator: (val) => val == null || val.isEmpty ? 'Vendor name is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Expense Amount (₹) *',
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppTextField(
                              label: 'GST Tax Included (₹)',
                              controller: _gstController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppDropdownField<String>(
                              label: 'Payment Mode',
                              value: _paymentMode,
                              items: const [
                                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                DropdownMenuItem(value: 'Bank', child: Text('Bank Transfer')),
                                DropdownMenuItem(value: 'UPI', child: Text('UPI / QR')),
                              ],
                              onChanged: (val) => setDialogState(() => _paymentMode = val ?? 'Bank'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                TextButton.icon(
                                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                                  label: Text('${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}'),
                                  onPressed: () async {
                                    final selected = await showDatePicker(
                                      context: context,
                                      initialDate: _expenseDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (selected != null) {
                                      setDialogState(() {
                                        _expenseDate = selected;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Internal Notes',
                        controller: _notesController,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                AppButton(
                  label: 'Save Expense',
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final double amount = double.tryParse(_amountController.text) ?? 0.0;
                      final double gst = double.tryParse(_gstController.text) ?? 0.0;

                      final exp = Expense(
                        id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
                        category: _selectedCategory,
                        date: _expenseDate,
                        vendor: _vendorController.text,
                        amount: amount,
                        gst: gst,
                        paymentMode: _paymentMode,
                        attachmentPath: '',
                        notes: _notesController.text,
                      );

                      await ref.read(billingRepositoryProvider.notifier).addExpense(exp);

                      if (mounted) {
                        Navigator.pop(ctx);
                        AppFeedback.showSnackbar(context, message: 'Expense entry saved successfully!');
                      }
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
    final expenses = billingState.expenses;

    // Filter categories
    final totalExpensesSum = expenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Business Expenses',
              description: 'Record operating expenses (electricity, rent, packaging) to track cash outflows.',
              breadcrumbs: const ['Dashboard', 'Expenses'],
              actions: [
                AppButton(
                  label: 'Record Expense',
                  icon: Icons.add_circle_outline,
                  onPressed: () => _showAddExpenseDialog(context),
                ),
              ],
            ),

            // Top Stat card
            AppMetricCard(
              title: 'Total Recorded Operating Expenses',
              value: '₹${totalExpensesSum.toStringAsFixed(2)}',
              subtitle: 'Cash outflows excluding merchant inventory purchases',
              icon: Icons.money_off_outlined,
              iconColor: Colors.red,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Table of expenses
            AppCard(
              padding: EdgeInsets.zero,
              child: AppTable<Expense>(
                items: expenses,
                emptyMessage: 'No expenses recorded yet. Click Record Expense to log a cash outflow.',
                columns: [
                  TableColumnSpec<Expense>(
                    label: 'Date',
                    cellBuilder: (e) => Text('${e.date.day}/${e.date.month}/${e.date.year}'),
                  ),
                  TableColumnSpec<Expense>(
                    label: 'Category',
                    cellBuilder: (e) => Text(e.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  TableColumnSpec<Expense>(
                    label: 'Vendor / Payee',
                    flex: 2,
                    cellBuilder: (e) => Text(e.vendor),
                  ),
                  TableColumnSpec<Expense>(
                    label: 'Payment Mode',
                    cellBuilder: (e) => Text(e.paymentMode),
                  ),
                  TableColumnSpec<Expense>(
                    label: 'Tax Included (GST) (₹)',
                    isNumeric: true,
                    cellBuilder: (e) => Text('₹${e.gst.toStringAsFixed(2)}'),
                  ),
                  TableColumnSpec<Expense>(
                    label: 'Total Amount (₹)',
                    isNumeric: true,
                    cellBuilder: (e) => Text(
                      '₹${e.amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
