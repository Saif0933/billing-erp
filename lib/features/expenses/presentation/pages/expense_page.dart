import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
        return Icons.apartment_rounded;
      case 'electricity':
        return Icons.bolt_rounded;
      case 'internet':
        return Icons.wifi_rounded;
      case 'salary':
        return Icons.badge_rounded;
      case 'travel':
        return Icons.directions_car_rounded;
      case 'advertisement':
        return Icons.campaign_rounded;
      case 'office expenses':
        return Icons.business_center_rounded;
      case 'repairs & maintenance':
        return Icons.build_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'rent':
        return const Color(0xFFD97706);
      case 'electricity':
        return const Color(0xFFEAB308);
      case 'internet':
        return const Color(0xFF0284C7);
      case 'salary':
        return const Color(0xFF059669);
      case 'travel':
        return const Color(0xFF6366F1);
      case 'advertisement':
        return const Color(0xFFEC4899);
      case 'office expenses':
        return const Color(0xFF8B5CF6);
      case 'repairs & maintenance':
        return const Color(0xFFF97316);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _showAddExpenseDialog() {
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

    final isMobile = Responsive.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            Future<void> handleSaveExpense() async {
              if (_formKey.currentState!.validate()) {
                final double amount =
                    double.tryParse(_amountController.text) ?? 0.0;
                final double gst =
                    double.tryParse(_gstController.text) ?? 0.0;

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

                await ref
                    .read(billingRepositoryProvider.notifier)
                    .addExpense(exp);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  AppFeedback.showSnackbar(
                    context,
                    message: 'Expense entry saved successfully!',
                  );
                }
              }
            }

            final double enteredAmount =
                double.tryParse(_amountController.text) ?? 0.0;
            final double enteredGst =
                double.tryParse(_gstController.text) ?? 0.0;
            final double netExpense =
                (enteredAmount - enteredGst).clamp(0.0, double.infinity);

            Widget buildDatePickerField() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date *',
                    style: AppTypography.titleSmall.copyWith(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textLightSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: () async {
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
                    borderRadius: AppRadius.smBorder,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: AppRadius.smBorder,
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.accentLight
                                : const Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_expenseDate.day.toString().padLeft(2, '0')}/${_expenseDate.month.toString().padLeft(2, '0')}/${_expenseDate.year}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.textDarkPrimary
                                    : AppColors.textLightPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            size: 20,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final paymentModeField = AppDropdownField<String>(
              label: 'Payment Mode',
              value: _paymentMode,
              items: [
                DropdownMenuItem(
                  value: 'Cash',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Cash',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Bank',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.account_balance_outlined,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Bank Transfer',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'UPI',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 16,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'UPI / QR',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (val) => setDialogState(
                () => _paymentMode = val ?? 'Bank',
              ),
            );

            return AlertDialog(
              insetPadding: isMobile
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 24)
                  : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                              : [const Color(0xFF2563EB), const Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Record Basic Expense',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Log operational cash outflow & tax details',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textDarkMuted
                                  : AppColors.textLightSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      splashRadius: 20,
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              contentPadding: isMobile
                  ? const EdgeInsets.fromLTRB(16, 16, 16, 8)
                  : const EdgeInsets.fromLTRB(24, 20, 24, 12),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppDropdownField<String>(
                          label: 'Expense Category *',
                          value: _selectedCategory,
                          items: categories.map((cat) {
                            final catColor = _getCategoryColor(cat);
                            final catIcon = _getCategoryIcon(cat);
                            return DropdownMenuItem(
                              value: cat,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      catIcon,
                                      size: 16,
                                      color: catColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      cat,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setDialogState(
                            () => _selectedCategory = val ?? 'Office Expenses',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Vendor / Payee Name *',
                          hintText: 'e.g. Landlord, Power Utility, Vendor LLC',
                          prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                          controller: _vendorController,
                          validator: (val) => val == null || val.isEmpty
                              ? 'Vendor name is required'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (isMobile) ...[
                          AppTextField(
                            label: 'Expense Amount (₹) *',
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDialogState(() {}),
                            validator: (val) =>
                                val == null || double.tryParse(val) == null
                                ? 'Invalid amount'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'GST Tax Included (₹)',
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.percent_rounded, size: 18),
                            controller: _gstController,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  label: 'Expense Amount (₹) *',
                                  hintText: '0.00',
                                  prefixIcon: const Icon(Icons.currency_rupee, size: 18),
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setDialogState(() {}),
                                  validator: (val) =>
                                      val == null || double.tryParse(val) == null
                                      ? 'Invalid amount'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppTextField(
                                  label: 'GST Tax Included (₹)',
                                  hintText: '0.00',
                                  prefixIcon: const Icon(Icons.percent_rounded, size: 18),
                                  controller: _gstController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setDialogState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        // Live Net Outflow breakdown card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 13,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Net Outflow',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${netExpense.toStringAsFixed(2)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.receipt_outlined,
                                          size: 13,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            'Tax Credit',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${enteredGst.toStringAsFixed(2)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (isMobile) ...[
                          paymentModeField,
                          const SizedBox(height: AppSpacing.md),
                          buildDatePickerField(),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(child: paymentModeField),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: buildDatePickerField()),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          label: 'Internal Notes',
                          hintText: 'Add invoice number, reference or payment details...',
                          prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                          controller: _notesController,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actionsPadding: isMobile
                  ? const EdgeInsets.fromLTRB(16, 0, 16, 16)
                  : const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: isMobile
                  ? [
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Cancel',
                              type: AppButtonType.secondary,
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppButton(
                              label: 'Save Expense',
                              icon: Icons.check_circle_outline,
                              onPressed: handleSaveExpense,
                            ),
                          ),
                        ],
                      ),
                    ]
                  : [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(
                            label: 'Cancel',
                            type: AppButtonType.secondary,
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          AppButton(
                            label: 'Save Expense',
                            icon: Icons.check_circle_outline,
                            onPressed: handleSaveExpense,
                          ),
                        ],
                      ),
                    ],
            );
          },
        );
      },
    );
  }

  Widget _buildExpenseCard(Expense exp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color categoryBg;
    Color categoryTextColor;
    switch (exp.category.toLowerCase()) {
      case 'rent':
        categoryBg = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
        categoryTextColor = isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309);
        break;
      case 'salary':
        categoryBg = isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7);
        categoryTextColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF15803D);
        break;
      case 'electricity':
      case 'internet':
        categoryBg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
        categoryTextColor = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8);
        break;
      default:
        categoryBg = isDark ? const Color(0xFF312E81) : const Color(0xFFEEF2FF);
        categoryTextColor = isDark ? const Color(0xFFC7D2FE) : const Color(0xFF4338CA);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Category chip + Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    exp.category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: categoryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${exp.date.day.toString().padLeft(2, '0')}/${exp.date.month.toString().padLeft(2, '0')}/${exp.date.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Middle row: Vendor Name + Payment Mode badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  exp.vendor,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  exp.paymentMode,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          // Optional Notes
          if (exp.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              exp.notes,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Divider(height: 16, color: Color(0xFFE2E8F0)),

          // Bottom row: Tax (GST) + Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  exp.gst > 0
                      ? 'GST: ₹${exp.gst.toStringAsFixed(2)}'
                      : 'No GST',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '₹${exp.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final expenses = billingState.expenses;

    // Filter categories
    final totalExpensesSum = expenses.fold<double>(
      0.0,
      (sum, e) => sum + e.amount,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: SingleChildScrollView(
        padding: Responsive.isMobile(context)
            ? const EdgeInsets.all(AppSpacing.md)
            : const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Business Expenses',
              description:
                  'Record operating expenses (electricity, rent, packaging) to track cash outflows.',
              breadcrumbs: const ['Dashboard', 'Expenses'],
              actions: [
                AppButton(
                  label: 'Record Expense',
                  icon: Icons.add_circle_outline,
                  onPressed: _showAddExpenseDialog,
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
                emptyMessage:
                    'No expenses recorded yet. Click Record Expense to log a cash outflow.',
                mobileCardBuilder: _buildExpenseCard,
                columns: [
                  TableColumnSpec<Expense>(
                    label: 'Date',
                    cellBuilder: (e) =>
                        Text('${e.date.day}/${e.date.month}/${e.date.year}'),
                  ),
                  TableColumnSpec<Expense>(
                    label: 'Category',
                    cellBuilder: (e) => Text(
                      e.category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
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
