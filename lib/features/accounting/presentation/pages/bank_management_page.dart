import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/accounting_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

class BankManagementPage extends ConsumerStatefulWidget {
  const BankManagementPage({super.key});

  @override
  ConsumerState<BankManagementPage> createState() => _BankManagementPageState();
}

class _BankManagementPageState extends ConsumerState<BankManagementPage> {
  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.accounting)) {
      return const LockedFeaturePage(featureName: 'Advanced Accounting');
    }

    final billing = ref.watch(billingRepositoryProvider);
    final bankAccounts = billing.bankAccounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash & Bank Management'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accounts Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    AppButton(
                      label: 'New Bank Account',
                      icon: Icons.add,
                      type: AppButtonType.secondary,
                      onPressed: () => _showAddBankAccountDialog(context),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      label: 'Contra Fund Transfer',
                      icon: Icons.swap_horiz,
                      onPressed: () => _showContraTransferDialog(context, bankAccounts, billing.accounts),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemCount: bankAccounts.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final cashAcc = billing.accounts.firstWhere((a) => a.id == 'acc_cash', orElse: () => Account(id: '', businessId: '', code: '', name: 'Cash', type: AccountType.asset, groupName: '', isSystemAccount: true, isActive: true, openingDebit: 0, openingCredit: 0, currentBalance: 15000, createdAt: DateTime.now()));
                  return _buildBankCard(
                    context,
                    accountName: 'Cash In Hand',
                    bankName: 'Liquid Currency',
                    accountNumber: 'PHYSICAL-TILL-01',
                    balance: cashAcc.currentBalance,
                    isCash: true,
                  );
                } else if (index == 1) {
                  final systemBank = billing.accounts.firstWhere((a) => a.id == 'acc_bank', orElse: () => Account(id: '', businessId: '', code: '', name: 'Bank', type: AccountType.asset, groupName: '', isSystemAccount: true, isActive: true, openingDebit: 0, openingCredit: 0, currentBalance: 250000, createdAt: DateTime.now()));
                  return _buildBankCard(
                    context,
                    accountName: 'Bunny Central Bank (System A/C)',
                    bankName: 'Central Bank',
                    accountNumber: 'SYSTEM-BANK-01',
                    balance: systemBank.currentBalance,
                    isCash: false,
                  );
                } else {
                  final bank = bankAccounts[index - 2];
                  return _buildBankCard(
                    context,
                    accountName: bank.accountName,
                    bankName: bank.bankName,
                    accountNumber: bank.accountNumber,
                    balance: bank.currentBalance,
                    isCash: false,
                  );
                }
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Recent Interbank / Contra Transfers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            AppCard(
              padding: EdgeInsets.zero,
              child: AppTable<JournalEntry>(
                items: billing.journalEntries.where((je) => je.referenceType == 'BankTransfer' && je.status == JournalStatus.posted).toList(),
                emptyMessage: 'No interbank fund transfers logged yet.',
                columns: [
                  TableColumnSpec<JournalEntry>(
                    label: 'Transfer Date',
                    cellBuilder: (je) => Text(je.date.toString().substring(0, 10)),
                  ),
                  TableColumnSpec<JournalEntry>(
                    label: 'Description & Narration',
                    cellBuilder: (je) => Text(je.narration),
                  ),
                  TableColumnSpec<JournalEntry>(
                    label: 'Transaction ID',
                    cellBuilder: (je) => Text(je.id, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  TableColumnSpec<JournalEntry>(
                    label: 'Amount Transferred',
                    isNumeric: true,
                    cellBuilder: (je) {
                      final amount = je.lines.first.debit;
                      return Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankCard(
    BuildContext context, {
    required String accountName,
    required String bankName,
    required String accountNumber,
    required double balance,
    required bool isCash,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                isCash ? Icons.money : Icons.account_balance,
                color: isCash ? Colors.amber : Colors.blue,
                size: 28,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isCash ? Colors.amber : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCash ? 'CASH' : 'BANK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isCash ? Colors.amber : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                accountName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$bankName • A/C: $accountNumber',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Available Balance:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddBankAccountDialog(BuildContext context) {
    final bankNameController = TextEditingController();
    final accountNameController = TextEditingController();
    final numberController = TextEditingController();
    final ifscController = TextEditingController();
    final branchController = TextEditingController();
    String accountType = 'Current';
    double openingBalance = 0.0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Bank Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Bank Name *',
                      controller: bankNameController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Account Holder Name *',
                      controller: accountNameController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Account Number *',
                      controller: numberController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'IFSC Code *',
                      controller: ifscController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Branch Address *',
                      controller: branchController,
                    ),
                    const SizedBox(height: 12),
                    AppDropdownField<String>(
                      label: 'Account Type *',
                      value: accountType,
                      items: const [
                        DropdownMenuItem(value: 'Current', child: Text('Current Account')),
                        DropdownMenuItem(value: 'Savings', child: Text('Savings Account')),
                        DropdownMenuItem(value: 'Overdraft', child: Text('Overdraft Limit A/C')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => accountType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Opening Balance (₹)',
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        openingBalance = double.tryParse(val) ?? 0.0;
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
                  label: 'Save Bank',
                  onPressed: () async {
                    if (bankNameController.text.isEmpty ||
                        accountNameController.text.isEmpty ||
                        numberController.text.isEmpty ||
                        ifscController.text.isEmpty) {
                      AppFeedback.showSnackbar(context, message: 'Please fill in all mandatory fields.', isError: true);
                      return;
                    }

                    final newBank = BankAccount(
                      id: 'bank_${DateTime.now().millisecondsSinceEpoch}',
                      businessId: 'biz_01',
                      bankName: bankNameController.text.trim(),
                      accountName: accountNameController.text.trim(),
                      accountNumber: numberController.text.trim(),
                      ifsc: ifscController.text.trim(),
                      branch: branchController.text.trim(),
                      accountType: accountType,
                      openingBalance: openingBalance,
                      currentBalance: openingBalance,
                      isActive: true,
                    );

                    final newAcc = Account(
                      id: 'acc_bank_${newBank.id}',
                      businessId: 'biz_01',
                      code: '100${2 + ref.read(billingRepositoryProvider).bankAccounts.length}',
                      name: '${newBank.bankName} (${newBank.accountName})',
                      type: AccountType.asset,
                      groupName: 'Bank Accounts',
                      isSystemAccount: false,
                      isActive: true,
                      openingDebit: openingBalance,
                      openingCredit: 0.0,
                      currentBalance: openingBalance,
                      createdAt: DateTime.now(),
                    );

                    await ref.read(billingRepositoryProvider.notifier).addAccount(newAcc);
                    await ref.read(billingRepositoryProvider.notifier).addBankAccount(newBank);
                    Navigator.pop(ctx);
                    AppFeedback.showSnackbar(context, message: 'Bank Account registered.');
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showContraTransferDialog(BuildContext context, List<BankAccount> bankAccounts, List<Account> systemAccounts) {
    final List<Map<String, String>> transferOptions = [
      {'id': 'acc_cash', 'name': 'Cash In Hand'},
      {'id': 'acc_bank', 'name': 'Bunny Central Bank (System A/C)'},
      ...bankAccounts.map((b) => {'id': 'acc_bank_${b.id}', 'name': '${b.bankName} (A/C: ${b.accountNumber})'}),
    ];

    String sourceId = transferOptions[0]['id']!;
    String destId = transferOptions[1]['id']!;
    double amount = 0.0;
    final refController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Contra Fund Transfer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppDropdownField<String>(
                    label: 'Source Account *',
                    value: sourceId,
                    items: transferOptions.map((opt) {
                      return DropdownMenuItem(value: opt['id'], child: Text(opt['name']!));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          sourceId = val;
                          if (sourceId == destId) {
                            destId = transferOptions.firstWhere((opt) => opt['id'] != sourceId)['id']!;
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppDropdownField<String>(
                    label: 'Destination Account *',
                    value: destId,
                    items: transferOptions.where((opt) => opt['id'] != sourceId).map((opt) {
                      return DropdownMenuItem(value: opt['id'], child: Text(opt['name']!));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => destId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Transfer Amount (₹) *',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      amount = double.tryParse(val) ?? 0.0;
                    },
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: 'Reference Number / Memo',
                    controller: refController,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Execute Contra Transfer',
                  onPressed: () async {
                    if (amount <= 0) {
                      AppFeedback.showSnackbar(context, message: 'Please specify a positive transfer amount.', isError: true);
                      return;
                    }

                    double sourceBal = 0.0;
                    final sourceAccount = systemAccounts.firstWhere(
                      (a) => a.id == sourceId,
                      orElse: () => Account(id: '', businessId: '', code: '', name: '', type: AccountType.asset, groupName: '', isSystemAccount: false, isActive: false, openingDebit: 0, openingCredit: 0, currentBalance: 0, createdAt: DateTime.now()),
                    );

                    if (sourceAccount.id.isNotEmpty) {
                      sourceBal = sourceAccount.currentBalance;
                    } else {
                      // Custom bank account resolve
                      if (sourceId.startsWith('acc_bank_')) {
                        final bankId = sourceId.replaceFirst('acc_bank_', '');
                        final bank = bankAccounts.firstWhere((b) => b.id == bankId);
                        sourceBal = bank.currentBalance;
                      }
                    }

                    if (sourceBal < amount) {
                      AppFeedback.showSnackbar(context, message: 'Insufficient funds available in selected source account.', isError: true);
                      return;
                    }

                    try {
                      final refNo = refController.text.trim().isEmpty ? 'TR-${DateTime.now().millisecondsSinceEpoch}' : refController.text.trim();

                      final notifier = ref.read(billingRepositoryProvider.notifier);
                      
                      // For simplicity, Contra transfers are posted as Manual Journal Entries affecting the accounts directly
                      final entryId = 'je_transfer_${DateTime.now().millisecondsSinceEpoch}';
                      final destAccount = systemAccounts.firstWhere(
                        (a) => a.id == destId,
                        orElse: () => Account(id: '', businessId: '', code: '', name: '', type: AccountType.asset, groupName: '', isSystemAccount: false, isActive: false, openingDebit: 0, openingCredit: 0, currentBalance: 0, createdAt: DateTime.now()),
                      );

                      final sourceName = sourceAccount.id.isNotEmpty 
                          ? sourceAccount.name 
                          : transferOptions.firstWhere((opt) => opt['id'] == sourceId)['name']!;
                      final destName = destAccount.id.isNotEmpty 
                          ? destAccount.name 
                          : transferOptions.firstWhere((opt) => opt['id'] == destId)['name']!;

                      final entry = JournalEntry(
                        id: entryId,
                        businessId: 'biz_01',
                        date: DateTime.now(),
                        referenceType: 'BankTransfer',
                        referenceId: refNo,
                        narration: 'Inter-account Contra transfer from $sourceName to $destName - Ref: $refNo',
                        status: JournalStatus.posted,
                        lines: [
                          JournalEntryLine(
                            id: 'line_${entryId}_dest',
                            journalEntryId: entryId,
                            accountId: destId,
                            accountName: destName,
                            debit: amount,
                            credit: 0.0,
                            description: 'Debit to receiving account',
                          ),
                          JournalEntryLine(
                            id: 'line_${entryId}_src',
                            journalEntryId: entryId,
                            accountId: sourceId,
                            accountName: sourceName,
                            debit: 0.0,
                            credit: amount,
                            description: 'Credit to sending account',
                          ),
                        ],
                      );

                      // Also update bank account currentBalances in list if custom bank
                      if (sourceId.startsWith('acc_bank_') || destId.startsWith('acc_bank_')) {
                        final updatedBanks = bankAccounts.map((b) {
                          double balance = b.currentBalance;
                          if (sourceId == 'acc_bank_${b.id}') {
                            balance = double.parse((balance - amount).toStringAsFixed(2));
                          }
                          if (destId == 'acc_bank_${b.id}') {
                            balance = double.parse((balance + amount).toStringAsFixed(2));
                          }
                          return b.copyWith(currentBalance: balance);
                        }).toList();
                        notifier.state = notifier.state.copyWith(bankAccounts: updatedBanks);
                      }

                      await notifier.addManualJournalEntry(entry);

                      Navigator.pop(ctx);
                      AppFeedback.showSnackbar(context, message: 'Fund transfer executed and posted successfully!');
                    } catch (e) {
                      AppFeedback.showSnackbar(context, message: e.toString().replaceAll('Exception: ', ''), isError: true);
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
}
