import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/accounting_models.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_input_fields.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';
import '../../../subscription/domain/entities/subscription_models.dart';
import '../../../subscription/presentation/pages/locked_feature_page.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';

class FinancialReportsPage extends ConsumerStatefulWidget {
  const FinancialReportsPage({super.key});

  @override
  ConsumerState<FinancialReportsPage> createState() => _FinancialReportsPageState();
}

class _FinancialReportsPageState extends ConsumerState<FinancialReportsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriodId = 'per_01';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    if (!subscription.canAccess(SubscriptionFeature.accounting)) {
      return const LockedFeaturePage(featureName: 'Advanced Accounting');
    }

    final billing = ref.watch(billingRepositoryProvider);

    final activePeriod = billing.accountingPeriods.firstWhere(
      (p) => p.id == _selectedPeriodId,
      orElse: () => AccountingPeriod(
        id: '',
        businessId: '',
        name: 'N/A',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
        status: PeriodStatus.open,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: () => _simulateExport('PDF'),
          ),
          IconButton(
            icon: const Icon(Icons.grid_on),
            tooltip: 'Export Excel',
            onPressed: () => _simulateExport('Excel'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Day Book', icon: Icon(Icons.calendar_today)),
            Tab(text: 'Trial Balance', icon: Icon(Icons.balance)),
            Tab(text: 'Profit & Loss', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Balance Sheet', icon: Icon(Icons.account_balance)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 250,
                  child: AppDropdownField<String>(
                    label: 'Financial Period',
                    value: _selectedPeriodId,
                    items: billing.accountingPeriods.map((p) {
                      return DropdownMenuItem(value: p.id, child: Text(p.name));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPeriodId = val);
                      }
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: activePeriod.status == PeriodStatus.open ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        activePeriod.status == PeriodStatus.open ? Icons.lock_open : Icons.lock,
                        color: activePeriod.status == PeriodStatus.open ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Period Status: ${activePeriod.status.name.toUpperCase()}',
                        style: TextStyle(
                          color: activePeriod.status == PeriodStatus.open ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDayBookTab(billing.journalEntries),
                _buildTrialBalanceTab(billing.accounts),
                _buildProfitAndLossTab(billing.accounts),
                _buildBalanceSheetTab(billing.accounts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBookTab(List<JournalEntry> journalEntries) {
    final List<Map<String, dynamic>> dayBookLines = [];
    for (var entry in journalEntries) {
      if (entry.status == JournalStatus.posted) {
        for (var line in entry.lines) {
          dayBookLines.add({
            'date': entry.date,
            'narration': entry.narration,
            'reference': '${entry.referenceType} (${entry.referenceId})',
            'account': line.accountName,
            'debit': line.debit,
            'credit': line.credit,
            'description': line.description,
          });
        }
      }
    }

    dayBookLines.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return AppCard(
      padding: EdgeInsets.zero,
      child: AppTable<Map<String, dynamic>>(
        items: dayBookLines,
        emptyMessage: 'No day book transactions found.',
        columns: [
          TableColumnSpec<Map<String, dynamic>>(
            label: 'Date',
            cellBuilder: (item) => Text((item['date'] as DateTime).toString().substring(0, 10)),
          ),
          TableColumnSpec<Map<String, dynamic>>(
            label: 'Particulars (Tx / Account)',
            cellBuilder: (item) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['account'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${item['narration']} • ${item['description']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          TableColumnSpec<Map<String, dynamic>>(
            label: 'Reference',
            cellBuilder: (item) => Text(item['reference'] as String, style: const TextStyle(fontSize: 12)),
          ),
          TableColumnSpec<Map<String, dynamic>>(
            label: 'Debit (Dr)',
            isNumeric: true,
            cellBuilder: (item) {
              final val = item['debit'] as double;
              return Text(val > 0 ? '₹${val.toStringAsFixed(2)}' : '-', style: const TextStyle(color: Colors.green));
            },
          ),
          TableColumnSpec<Map<String, dynamic>>(
            label: 'Credit (Cr)',
            isNumeric: true,
            cellBuilder: (item) {
              final val = item['credit'] as double;
              return Text(val > 0 ? '₹${val.toStringAsFixed(2)}' : '-', style: const TextStyle(color: Colors.red));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTrialBalanceTab(List<Account> accounts) {
    double totalDebit = 0.0;
    double totalCredit = 0.0;

    final List<Map<String, dynamic>> tbRows = [];
    for (var acc in accounts) {
      if (acc.currentBalance != 0) {
        final double debit = acc.type == AccountType.asset || acc.type == AccountType.expense ? acc.currentBalance : 0.0;
        final double credit = acc.type != AccountType.asset && acc.type != AccountType.expense ? acc.currentBalance.abs() : 0.0;

        totalDebit += debit;
        totalCredit += credit;

        tbRows.add({
          'code': acc.code,
          'name': acc.name,
          'type': acc.type.name.toUpperCase(),
          'debit': debit,
          'credit': credit,
        });
      }
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          AppCard(
            padding: EdgeInsets.zero,
            child: AppTable<Map<String, dynamic>>(
              items: tbRows,
              emptyMessage: 'No accounts with non-zero balances found.',
              columns: [
                TableColumnSpec<Map<String, dynamic>>(
                  label: 'Account Code',
                  cellBuilder: (row) => Text(row['code'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                TableColumnSpec<Map<String, dynamic>>(
                  label: 'Account Name',
                  cellBuilder: (row) => Text(row['name'] as String),
                ),
                TableColumnSpec<Map<String, dynamic>>(
                  label: 'Category',
                  cellBuilder: (row) => Text(row['type'] as String, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                TableColumnSpec<Map<String, dynamic>>(
                  label: 'Debit (Dr)',
                  isNumeric: true,
                  cellBuilder: (row) {
                    final val = row['debit'] as double;
                    return Text(val > 0 ? '₹${val.toStringAsFixed(2)}' : '-');
                  },
                ),
                TableColumnSpec<Map<String, dynamic>>(
                  label: 'Credit (Cr)',
                  isNumeric: true,
                  cellBuilder: (row) {
                    final val = row['credit'] as double;
                    return Text(val > 0 ? '₹${val.toStringAsFixed(2)}' : '-');
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Sum Balance Check:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    'Total Dr: ₹${totalDebit.toStringAsFixed(2)}  |  Total Cr: ₹${totalCredit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: double.parse(totalDebit.toStringAsFixed(2)) == double.parse(totalCredit.toStringAsFixed(2))
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitAndLossTab(List<Account> accounts) {
    final incomeAccounts = accounts.where((a) => a.type == AccountType.income).toList();
    final expenseAccounts = accounts.where((a) => a.type == AccountType.expense).toList();

    final double totalIncome = incomeAccounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance.abs());
    final double totalExpenses = expenseAccounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance);
    final double netProfit = totalIncome - totalExpenses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Operating Statement (Revenues & Expenses)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _buildRowTitle('REVENUES', true),
                ...incomeAccounts.map((a) => _buildRowEntry(a.name, a.currentBalance.abs())),
                const Divider(),
                _buildRowSummary('Total Revenue / Income', totalIncome),
                const SizedBox(height: 20),
                _buildRowTitle('DIRECT & INDIRECT EXPENSES', true),
                ...expenseAccounts.map((a) => _buildRowEntry(a.name, a.currentBalance)),
                const Divider(),
                _buildRowSummary('Total Expenses Logged', totalExpenses),
                const Divider(thickness: 2),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  color: netProfit >= 0 ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(netProfit >= 0 ? 'NET RETAINED PROFIT' : 'NET ACCUMULATED LOSS',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('₹${netProfit.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: netProfit >= 0 ? Colors.green : Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSheetTab(List<Account> accounts) {
    final assetAccounts = accounts.where((a) => a.type == AccountType.asset).toList();
    final liabilityAccounts = accounts.where((a) => a.type == AccountType.liability).toList();
    final equityAccounts = accounts.where((a) => a.type == AccountType.equity).toList();

    final double totalIncome = accounts.where((a) => a.type == AccountType.income).fold<double>(0.0, (sum, a) => sum + a.currentBalance.abs());
    final double totalExpenses = accounts.where((a) => a.type == AccountType.expense).fold<double>(0.0, (sum, a) => sum + a.currentBalance);
    final double currentNetProfit = totalIncome - totalExpenses;

    final double totalAssets = assetAccounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance);
    final double totalLiabilities = liabilityAccounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance.abs());
    final double totalEquity = equityAccounts.fold<double>(0.0, (sum, a) => sum + a.currentBalance.abs()) + currentNetProfit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Balance Sheet (Financial Position Statement)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _buildRowTitle('ASSETS (CAPITAL DEPLOYMENTS)', true),
                ...assetAccounts.map((a) => _buildRowEntry(a.name, a.currentBalance)),
                const Divider(),
                _buildRowSummary('Total Assets Value', totalAssets),
                const SizedBox(height: 24),
                _buildRowTitle('EQUITY & LIABILITIES (FINANCING SOURCES)', true),
                _buildRowTitle('Equity Capital', false),
                ...equityAccounts.map((a) => _buildRowEntry(a.name, a.currentBalance.abs())),
                _buildRowEntry('Current Retained Profit (FY)', currentNetProfit),
                const SizedBox(height: 8),
                _buildRowTitle('Liabilities (Debt & Payables)', false),
                ...liabilityAccounts.map((a) => _buildRowEntry(a.name, a.currentBalance.abs())),
                const Divider(),
                _buildRowSummary('Total Equity & Liabilities', totalLiabilities + totalEquity),
                const Divider(thickness: 2),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  color: double.parse(totalAssets.toStringAsFixed(2)) == double.parse((totalLiabilities + totalEquity).toStringAsFixed(2))
                      ? Colors.green.withOpacity(0.08)
                      : Colors.red.withOpacity(0.08),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance Sheet Reconciled Check:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        double.parse(totalAssets.toStringAsFixed(2)) == double.parse((totalLiabilities + totalEquity).toStringAsFixed(2))
                            ? 'Balanced (Assets = Liabilities + Equity)'
                            : 'Unbalanced Error',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: double.parse(totalAssets.toStringAsFixed(2)) == double.parse((totalLiabilities + totalEquity).toStringAsFixed(2))
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowTitle(String title, bool isHeader) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      color: isHeader ? Colors.grey.withOpacity(0.1) : Colors.transparent,
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isHeader ? 14 : 12,
          color: isHeader ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildRowEntry(String name, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 13)),
          Text('₹${val.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRowSummary(String label, double val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('₹${val.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
        ],
      ),
    );
  }

  void _simulateExport(String format) {
    AppFeedback.showSnackbar(
      context,
      message: 'Exporting statement to $format... Please wait.',
    );
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: Text('$format Report Generated'),
              content: Text('Financial statement has been successfully generated and compiled for the selected period under $format structure.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Download'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }
    });
  }
}
