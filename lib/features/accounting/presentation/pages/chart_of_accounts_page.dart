import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/accounting_models.dart';
import '../../../../core/permissions/permission_models.dart';
import '../../../../core/permissions/permission_service.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

class ChartOfAccountsPage extends ConsumerStatefulWidget {
  const ChartOfAccountsPage({super.key});

  @override
  ConsumerState<ChartOfAccountsPage> createState() => _ChartOfAccountsPageState();
}

class _ChartOfAccountsPageState extends ConsumerState<ChartOfAccountsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.accounting)) {
      return const LockedFeaturePage(featureName: 'Advanced Accounting');
    }

    final authState = ref.watch(authProvider);
    final billingState = ref.watch(billingRepositoryProvider);
    final userEmail = authState.user?.email ?? 'owner@taxbunny.com';

    final userMap = billingState.customUsers.firstWhere(
      (u) => u['email'] == userEmail,
      orElse: () => {
        'role': 'owner',
        'permissions': <String, bool>{},
      },
    );

    final String roleStr = userMap['role'] ?? 'owner';
    final UserRole currentRole = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.owner,
    );

    final canCreate = PermissionService.hasPermission(currentRole, AppPermission.createAccounts);
    final canEdit = PermissionService.hasPermission(currentRole, AppPermission.editAccounts);
    final canDeactivate = PermissionService.hasPermission(currentRole, AppPermission.deactivateAccounts);

    final allAccounts = billingState.accounts;

    List<Account> filterAndType(AccountType type) {
      return allAccounts.where((acc) {
        if (acc.type != type) return false;
        if (_searchQuery.isEmpty) return true;
        return acc.name.toLowerCase().contains(_searchQuery) || acc.code.contains(_searchQuery);
      }).toList();
    }

    final assets = filterAndType(AccountType.asset);
    final liabilities = filterAndType(AccountType.liability);
    final equity = filterAndType(AccountType.equity);
    final income = filterAndType(AccountType.income);
    final expenses = filterAndType(AccountType.expense);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart of Accounts'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Assets', icon: Icon(Icons.account_balance)),
            Tab(text: 'Liabilities', icon: Icon(Icons.credit_card)),
            Tab(text: 'Equity', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Income', icon: Icon(Icons.trending_up)),
            Tab(text: 'Expenses', icon: Icon(Icons.trending_down)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Search Accounts',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                if (canCreate) ...[
                  const SizedBox(width: 16),
                  AppButton(
                    label: 'Add Account',
                    icon: Icons.add,
                    onPressed: () => _showAddAccountDialog(context),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAccountsTab(assets, canEdit, canDeactivate),
                _buildAccountsTab(liabilities, canEdit, canDeactivate),
                _buildAccountsTab(equity, canEdit, canDeactivate),
                _buildAccountsTab(income, canEdit, canDeactivate),
                _buildAccountsTab(expenses, canEdit, canDeactivate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsTab(List<Account> accounts, bool canEdit, bool canDeactivate) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: AppTable<Account>(
        items: accounts,
        emptyMessage: 'No accounts found in this category.',
        columns: [
          TableColumnSpec<Account>(
            label: 'Code',
            cellBuilder: (acc) => Text(
              acc.code,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TableColumnSpec<Account>(
            label: 'Name',
            cellBuilder: (acc) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(acc.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(acc.groupName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          TableColumnSpec<Account>(
            label: 'Type',
            cellBuilder: (acc) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                acc.type.name.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          TableColumnSpec<Account>(
            label: 'Balance',
            isNumeric: true,
            cellBuilder: (acc) {
              final color = acc.currentBalance >= 0 ? Colors.green : Colors.red;
              return Text(
                '₹${acc.currentBalance.toStringAsFixed(2)}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              );
            },
          ),
          TableColumnSpec<Account>(
            label: 'Status',
            cellBuilder: (acc) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: acc.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                acc.isActive ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  fontSize: 10,
                  color: acc.isActive ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          TableColumnSpec<Account>(
            label: 'Actions',
            cellBuilder: (acc) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.history, size: 20),
                  tooltip: 'View Ledger Details',
                  onPressed: () => _viewAccountLedger(acc),
                ),
                if (canEdit && !acc.isSystemAccount)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit Account',
                    onPressed: () => _showEditAccountDialog(context, acc),
                  ),
                if (canDeactivate && acc.isActive && !acc.isSystemAccount)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    tooltip: 'Deactivate Account',
                    onPressed: () => _confirmDeactivateAccount(acc),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewAccountLedger(Account acc) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final billingState = ref.watch(billingRepositoryProvider);
            final List<JournalEntryLine> ledgerLines = [];
            for (var entry in billingState.journalEntries) {
              if (entry.status == JournalStatus.posted) {
                for (var line in entry.lines) {
                  if (line.accountId == acc.id) {
                    ledgerLines.add(line);
                  }
                }
              }
            }

            return AlertDialog(
              title: Text('Ledger: ${acc.name} (${acc.code})'),
              content: SizedBox(
                width: 600,
                height: 400,
                child: AppTable<JournalEntryLine>(
                  items: ledgerLines,
                  emptyMessage: 'No transactions posted to this account yet.',
                  columns: [
                    TableColumnSpec<JournalEntryLine>(
                      label: 'Ref ID',
                      cellBuilder: (line) => Text(line.journalEntryId, style: const TextStyle(fontSize: 11)),
                    ),
                    TableColumnSpec<JournalEntryLine>(
                      label: 'Description',
                      cellBuilder: (line) => Text(line.description),
                    ),
                    TableColumnSpec<JournalEntryLine>(
                      label: 'Debit (Dr)',
                      isNumeric: true,
                      cellBuilder: (line) => Text(
                        line.debit > 0 ? '₹${line.debit.toStringAsFixed(2)}' : '-',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                    TableColumnSpec<JournalEntryLine>(
                      label: 'Credit (Cr)',
                      isNumeric: true,
                      cellBuilder: (line) => Text(
                        line.credit > 0 ? '₹${line.credit.toStringAsFixed(2)}' : '-',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddAccountDialog(BuildContext context) {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final groupController = TextEditingController();
    AccountType selectedType = AccountType.asset;
    double openingBal = 0.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Account Code *',
                      controller: codeController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Account Name *',
                      controller: nameController,
                    ),
                    const SizedBox(height: 12),
                    AppDropdownField<AccountType>(
                      label: 'Account Type *',
                      value: selectedType,
                      items: AccountType.values.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Group Name (e.g. Current Assets) *',
                      controller: groupController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Opening Balance (₹)',
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        openingBal = double.tryParse(val) ?? 0.0;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Save Account',
                  onPressed: () async {
                    if (codeController.text.isEmpty || nameController.text.isEmpty || groupController.text.isEmpty) {
                      AppFeedback.showSnackbar(context, message: 'Please fill in all mandatory fields.', isError: true);
                      return;
                    }

                    final newAcc = Account(
                      id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                      businessId: 'biz_01',
                      code: codeController.text.trim(),
                      name: nameController.text.trim(),
                      type: selectedType,
                      groupName: groupController.text.trim(),
                      isSystemAccount: false,
                      isActive: true,
                      openingDebit: selectedType == AccountType.asset || selectedType == AccountType.expense ? openingBal : 0.0,
                      openingCredit: selectedType != AccountType.asset && selectedType != AccountType.expense ? openingBal : 0.0,
                      currentBalance: openingBal,
                      createdAt: DateTime.now(),
                    );

                    await ref.read(billingRepositoryProvider.notifier).addAccount(newAcc);
                    Navigator.pop(ctx);
                    AppFeedback.showSnackbar(context, message: 'Account added successfully!');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAccountDialog(BuildContext context, Account acc) {
    final nameController = TextEditingController(text: acc.name);
    final groupController = TextEditingController(text: acc.groupName);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Edit Account: ${acc.code}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Account Name *',
                controller: nameController,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Group Name *',
                controller: groupController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            AppButton(
              label: 'Save Changes',
              onPressed: () async {
                if (nameController.text.isEmpty || groupController.text.isEmpty) {
                  AppFeedback.showSnackbar(context, message: 'Name and Group are required.', isError: true);
                  return;
                }

                final updated = acc.copyWith(
                  name: nameController.text.trim(),
                  groupName: groupController.text.trim(),
                );

                await ref.read(billingRepositoryProvider.notifier).updateAccount(updated);
                Navigator.pop(ctx);
                AppFeedback.showSnackbar(context, message: 'Account updated successfully!');
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeactivateAccount(Account acc) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Deactivate Account?'),
          content: Text('Are you sure you want to deactivate account "${acc.name}" (${acc.code})? It will no longer accept postings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                try {
                  await ref.read(billingRepositoryProvider.notifier).deactivateAccount(acc.id);
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(context, message: 'Account deactivated.');
                } catch (e) {
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(context, message: e.toString().replaceAll('Exception: ', ''), isError: true);
                }
              },
              child: const Text('Deactivate', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
