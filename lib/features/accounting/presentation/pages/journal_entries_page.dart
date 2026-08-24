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

class JournalEntriesPage extends ConsumerStatefulWidget {
  const JournalEntriesPage({super.key});

  @override
  ConsumerState<JournalEntriesPage> createState() => _JournalEntriesPageState();
}

class _JournalEntriesPageState extends ConsumerState<JournalEntriesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  JournalStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
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

    final canPost = PermissionService.hasPermission(currentRole, AppPermission.postJournals);
    final canReverse = PermissionService.hasPermission(currentRole, AppPermission.reverseJournals);

    final filteredEntries = billingState.journalEntries.where((je) {
      if (_selectedStatus != null && je.status != _selectedStatus) return false;
      if (_searchQuery.isEmpty) return true;
      return je.narration.toLowerCase().contains(_searchQuery) ||
          (je.referenceId?.toLowerCase().contains(_searchQuery) ?? false) ||
          je.id.toLowerCase().contains(_searchQuery);
    }).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('General Journal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Search journal entries (narration, reference, ID)',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: AppDropdownField<JournalStatus?>(
                    label: 'Filter by Status',
                    value: _selectedStatus,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Statuses')),
                      ...JournalStatus.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedStatus = val);
                    },
                  ),
                ),
                if (canPost) ...[
                  const SizedBox(width: 16),
                  AppButton(
                    label: 'Post Manual Journal',
                    icon: Icons.add,
                    onPressed: () => _showAddJournalDialog(context, billingState.accounts),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: AppCard(
                padding: EdgeInsets.zero,
                child: AppTable<JournalEntry>(
                  items: filteredEntries,
                  emptyMessage: 'No journal entries found matching criteria.',
                  columns: [
                    TableColumnSpec<JournalEntry>(
                      label: 'Date',
                      cellBuilder: (je) => Text(
                        je.date.toString().substring(0, 10),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TableColumnSpec<JournalEntry>(
                      label: 'Narration & Reference',
                      cellBuilder: (je) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(je.narration, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('Ref: ${je.referenceType ?? "N/A"} - ID: ${je.referenceId ?? "N/A"}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    TableColumnSpec<JournalEntry>(
                      label: 'Status',
                      cellBuilder: (je) {
                        final isPosted = je.status == JournalStatus.posted;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPosted ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            je.status.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isPosted ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    TableColumnSpec<JournalEntry>(
                      label: 'Total Value',
                      isNumeric: true,
                      cellBuilder: (je) {
                        final totalDebits = je.lines.fold<double>(0.0, (sum, line) => sum + line.debit);
                        return Text('₹${totalDebits.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold));
                      },
                    ),
                    TableColumnSpec<JournalEntry>(
                      label: 'Actions',
                      cellBuilder: (je) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            tooltip: 'View Lines Details',
                            onPressed: () => _viewJournalDetails(je),
                          ),
                          if (canReverse && je.status == JournalStatus.posted)
                            IconButton(
                              icon: const Icon(Icons.undo, color: Colors.orange),
                              tooltip: 'Reverse Entry',
                              onPressed: () => _confirmReverseJournal(je),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewJournalDetails(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Journal Entry Details: ${entry.id}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text(entry.narration, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 350,
            child: AppTable<JournalEntryLine>(
              items: entry.lines,
              emptyMessage: 'No lines found in this journal entry.',
              columns: [
                TableColumnSpec<JournalEntryLine>(
                  label: 'Account Code & Name',
                  cellBuilder: (line) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.accountName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Account ID: ${line.accountId}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                TableColumnSpec<JournalEntryLine>(
                  label: 'Debit (Dr)',
                  isNumeric: true,
                  cellBuilder: (line) => Text(
                    line.debit > 0 ? '₹${line.debit.toStringAsFixed(2)}' : '-',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ),
                TableColumnSpec<JournalEntryLine>(
                  label: 'Credit (Cr)',
                  isNumeric: true,
                  cellBuilder: (line) => Text(
                    line.credit > 0 ? '₹${line.credit.toStringAsFixed(2)}' : '-',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                  ),
                ),
                TableColumnSpec<JournalEntryLine>(
                  label: 'Line Description',
                  cellBuilder: (line) => Text(line.description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
  }

  void _showAddJournalDialog(BuildContext context, List<Account> accounts) {
    final narrationController = TextEditingController();
    final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));

    List<Map<String, dynamic>> tempLines = [
      {'accountId': accounts.first.id, 'debit': 0.0, 'credit': 0.0, 'description': ''},
      {'accountId': accounts.first.id, 'debit': 0.0, 'credit': 0.0, 'description': ''},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double totalDr = tempLines.fold<double>(0.0, (sum, l) => sum + (l['debit'] ?? 0.0));
            double totalCr = tempLines.fold<double>(0.0, (sum, l) => sum + (l['credit'] ?? 0.0));
            bool isBalanced = double.parse(totalDr.toStringAsFixed(2)) == double.parse(totalCr.toStringAsFixed(2)) && totalDr > 0;

            return AlertDialog(
              title: const Text('Post Manual Journal Entry'),
              content: SizedBox(
                width: 750,
                height: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Narration (Explain transaction) *',
                              controller: narrationController,
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 150,
                            child: AppTextField(
                              label: 'Posting Date (YYYY-MM-DD)',
                              controller: dateController,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Journal Lines', style: TextStyle(fontWeight: FontWeight.bold)),
                          AppButton(
                            label: 'Add Line',
                            icon: Icons.add,
                            type: AppButtonType.secondary,
                            onPressed: () {
                              setDialogState(() {
                                tempLines.add({
                                  'accountId': accounts.first.id,
                                  'debit': 0.0,
                                  'credit': 0.0,
                                  'description': '',
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      ...List.generate(tempLines.length, (index) {
                        final line = tempLines[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: AppDropdownField<String>(
                                  label: 'Account',
                                  value: line['accountId'],
                                  items: accounts.map((a) {
                                    return DropdownMenuItem(value: a.id, child: Text('[${a.code}] ${a.name}'));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setDialogState(() => line['accountId'] = val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  label: 'Debit (₹)',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      line['debit'] = double.tryParse(val) ?? 0.0;
                                      if (line['debit'] > 0) line['credit'] = 0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: AppTextField(
                                  label: 'Credit (₹)',
                                  keyboardType: TextInputType.number,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      line['credit'] = double.tryParse(val) ?? 0.0;
                                      if (line['credit'] > 0) line['debit'] = 0.0;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: AppTextField(
                                  label: 'Line Description',
                                  onChanged: (val) {
                                    line['description'] = val;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  if (tempLines.length <= 2) {
                                    AppFeedback.showSnackbar(context, message: 'Double-entry requires at least 2 lines!', isError: true);
                                    return;
                                  }
                                  setDialogState(() => tempLines.removeAt(index));
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: isBalanced ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Debits: ₹${totalDr.toStringAsFixed(2)} | Total Credits: ₹${totalCr.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isBalanced ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              isBalanced ? 'Balanced' : 'Debits must equal Credits',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isBalanced ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                AppButton(
                  label: 'Post Journal',
                  onPressed: () async {
                    if (narrationController.text.trim().isEmpty) {
                      AppFeedback.showSnackbar(context, message: 'Please specify a narration.', isError: true);
                      return;
                    }
                    if (!isBalanced) {
                      AppFeedback.showSnackbar(context, message: 'Double-entry balances do not match.', isError: true);
                      return;
                    }

                    try {
                      final parsedDate = DateTime.tryParse(dateController.text.trim()) ?? DateTime.now();
                      final entryId = 'je_manual_${DateTime.now().millisecondsSinceEpoch}';

                      final lines = tempLines.map((l) {
                        final account = accounts.firstWhere((a) => a.id == l['accountId']);
                        return JournalEntryLine(
                          id: 'line_${entryId}_${DateTime.now().microsecondsSinceEpoch}_${tempLines.indexOf(l)}',
                          journalEntryId: entryId,
                          accountId: l['accountId'],
                          accountName: account.name,
                          debit: l['debit'] ?? 0.0,
                          credit: l['credit'] ?? 0.0,
                          description: l['description'] ?? '',
                        );
                      }).toList();

                      final entry = JournalEntry(
                        id: entryId,
                        businessId: 'biz_01',
                        date: parsedDate,
                        referenceType: 'Manual',
                        referenceId: 'MANUAL',
                        narration: narrationController.text.trim(),
                        status: JournalStatus.posted,
                        lines: lines,
                      );

                      await ref.read(billingRepositoryProvider.notifier).addManualJournalEntry(entry);
                      Navigator.pop(ctx);
                      AppFeedback.showSnackbar(context, message: 'Manual Journal Entry posted successfully!');
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

  void _confirmReverseJournal(JournalEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reverse Journal Entry?'),
          content: Text('Are you sure you want to post a reversal entry for journal entry ${entry.id}? This will swap all debits and credits.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                try {
                  ref.read(billingRepositoryProvider.notifier).reverseJournalEntry(entry.referenceId ?? '', entry.referenceType ?? '');
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(context, message: 'Reversal Entry posted successfully.');
                } catch (e) {
                  Navigator.pop(ctx);
                  AppFeedback.showSnackbar(context, message: e.toString().replaceAll('Exception: ', ''), isError: true);
                }
              },
              child: const Text('Reverse', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
