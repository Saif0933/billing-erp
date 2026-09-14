import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';
import '../providers/chart_of_accounts_provider.dart';

class CoaAddAccountDialog extends ConsumerStatefulWidget {
  const CoaAddAccountDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const CoaAddAccountDialog(),
    );
  }

  @override
  ConsumerState<CoaAddAccountDialog> createState() => _CoaAddAccountDialogState();
}

class _CoaAddAccountDialogState extends ConsumerState<CoaAddAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.00');
  final _descController = TextEditingController();

  String _selectedParentCode = '1000';
  CoaAccountType _selectedType = CoaAccountType.asset;
  bool _isGroup = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Ensure parent groups are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chartOfAccountsNotifierProvider.notifier).fetchAccountGroups();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _balanceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onParentChanged(String? code, List<Map<String, dynamic>> groups) {
    if (code == null) return;
    setState(() {
      _selectedParentCode = code;
      final matched = groups.firstWhere(
        (g) => g['code']?.toString() == code,
        orElse: () => <String, dynamic>{},
      );
      if (matched.isNotEmpty && matched['type'] != null) {
        _selectedType = parseCoaType(matched['type']);
      } else {
        if (code.startsWith('1')) _selectedType = CoaAccountType.asset;
        if (code.startsWith('2')) _selectedType = CoaAccountType.liability;
        if (code.startsWith('3')) _selectedType = CoaAccountType.equity;
        if (code.startsWith('4') || code.startsWith('6')) _selectedType = CoaAccountType.income;
        if (code.startsWith('5')) _selectedType = CoaAccountType.expense;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final rawBalance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    final dto = CreateCoaAccountDto(
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      type: _selectedType,
      parentCode: _selectedParentCode.isNotEmpty ? _selectedParentCode : null,
      openingBalance: rawBalance,
      description: _descController.text.trim(),
      isGroup: _isGroup,
    );

    final success = await ref.read(chartOfAccountsNotifierProvider.notifier).createAccount(dto);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.pop(context);
      AppFeedback.showSnackbar(
        context,
        message: 'Account "${dto.name}" created successfully!',
      );
    } else {
      final errorMsg = ref.read(chartOfAccountsNotifierProvider).error ?? 'Failed to create account';
      AppFeedback.showSnackbar(
        context,
        message: errorMsg,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chartOfAccountsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fallback parent groups if backend returned empty list
    final defaultGroups = <Map<String, dynamic>>[
      {'code': '1000', 'name': '1. Assets', 'type': 'asset'},
      {'code': '2000', 'name': '2. Liabilities', 'type': 'liability'},
      {'code': '3000', 'name': '3. Equity', 'type': 'equity'},
      {'code': '4000', 'name': '4. Income', 'type': 'income'},
      {'code': '5000', 'name': '5. Expenses', 'type': 'expense'},
      {'code': '6000', 'name': '6. Other Income', 'type': 'income'},
    ];

    final availableGroups = state.parentGroups.isNotEmpty ? state.parentGroups : defaultGroups;

    // Ensure selected parent code is in available groups
    final selectedCode = availableGroups.any((g) => g['code']?.toString() == _selectedParentCode)
        ? _selectedParentCode
        : availableGroups.first['code']?.toString() ?? '1000';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
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
                          child: const Icon(Icons.account_tree_outlined, color: Color(0xFF15803D), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Add New Account',
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
                      // Parent Group Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedCode,
                        decoration: const InputDecoration(
                          labelText: 'Parent Group *',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: availableGroups.map((grp) {
                          final code = grp['code']?.toString() ?? '';
                          final name = grp['name']?.toString() ?? '';
                          final label = name.startsWith(code) ? name : '$code - $name';
                          return DropdownMenuItem(
                            value: code,
                            child: Text(label, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: _isSubmitting ? null : (val) => _onParentChanged(val, availableGroups),
                      ),
                      const SizedBox(height: 12),

                      // Account Name & Code Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _nameController,
                              enabled: !_isSubmitting,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Account Name *',
                                hintText: 'e.g. Petty Cash',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _codeController,
                              enabled: !_isSubmitting,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Code *',
                                hintText: 'e.g. 1004',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Opening Balance & IsGroup Checkbox Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _balanceController,
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 13),
                              decoration: const InputDecoration(
                                labelText: 'Opening Balance (₹)',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: _isGroup,
                                onChanged: _isSubmitting
                                    ? null
                                    : (val) => setState(() => _isGroup = val ?? false),
                              ),
                              const Text('Is Group', style: TextStyle(fontSize: 12.5)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: _descController,
                        enabled: !_isSubmitting,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Description / Notes',
                          hintText: 'Brief purpose of this account',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      _isSubmitting ? 'Saving...' : 'Save Account',
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
