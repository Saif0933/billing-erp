import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class OutstandingPage extends ConsumerStatefulWidget {
  const OutstandingPage({super.key});

  @override
  ConsumerState<OutstandingPage> createState() => _OutstandingPageState();
}

class _OutstandingPageState extends ConsumerState<OutstandingPage> {
  String _selectedTab = 'Receivables'; // Receivables vs Payables

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);
    final now = DateTime.now();

    // Ageing bucket totals
    double bucket0To30 = 0.0;
    double bucket31To60 = 0.0;
    double bucket61To90 = 0.0;
    double bucket91Plus = 0.0;

    double totalOutstanding = 0.0;
    double dueToday = 0.0;
    double totalOverdue = 0.0;

    List<_OutstandingItem> outstandingList = [];

    if (_selectedTab == 'Receivables') {
      final activeInvoices = billingState.invoices.where(
        (inv) => inv.status != InvoiceStatus.paid && inv.status != InvoiceStatus.cancelled && !inv.isCreditNote,
      ).toList();

      for (var inv in activeInvoices) {
        final diffDays = now.difference(inv.invoiceDate).inDays;
        final customer = billingState.customers.firstWhere((c) => c.id == inv.customerId, orElse: () => billingState.customers.first);
        final dueDate = inv.invoiceDate.add(Duration(days: customer.creditPeriod));
        final isOverdue = now.isAfter(dueDate);
        final isDueToday = now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day;

        totalOutstanding += inv.balanceAmount;
        if (isDueToday) dueToday += inv.balanceAmount;
        if (isOverdue) totalOverdue += inv.balanceAmount;

        // Ageing sort
        if (diffDays <= 30) {
          bucket0To30 += inv.balanceAmount;
        } else if (diffDays <= 60) {
          bucket31To60 += inv.balanceAmount;
        } else if (diffDays <= 90) {
          bucket61To90 += inv.balanceAmount;
        } else {
          bucket91Plus += inv.balanceAmount;
        }

        outstandingList.add(
          _OutstandingItem(
            id: inv.id,
            refNumber: inv.invoiceNumber,
            date: inv.invoiceDate,
            dueDate: dueDate,
            partyName: inv.customerName,
            amount: inv.grandTotal,
            balance: inv.balanceAmount,
            ageDays: diffDays,
            statusLabel: isOverdue ? 'OVERDUE' : (isDueToday ? 'DUE TODAY' : 'PENDING'),
          ),
        );
      }
    } else {
      // Payables
      final activePurchases = billingState.purchases.where(
        (p) => p.status != PurchaseStatus.paid && p.status != PurchaseStatus.cancelled && !p.isDebitNote,
      ).toList();

      for (var p in activePurchases) {
        final diffDays = now.difference(p.purchaseDate).inDays;
        final supplier = billingState.suppliers.firstWhere((s) => s.id == p.supplierId, orElse: () => billingState.suppliers.first);
        final dueDate = p.purchaseDate.add(Duration(days: supplier.creditTerms));
        final isOverdue = now.isAfter(dueDate);
        final isDueToday = now.year == dueDate.year && now.month == dueDate.month && now.day == dueDate.day;

        totalOutstanding += p.balanceAmount;
        if (isDueToday) dueToday += p.balanceAmount;
        if (isOverdue) totalOverdue += p.balanceAmount;

        // Ageing sort
        if (diffDays <= 30) {
          bucket0To30 += p.balanceAmount;
        } else if (diffDays <= 60) {
          bucket31To60 += p.balanceAmount;
        } else if (diffDays <= 90) {
          bucket61To90 += p.balanceAmount;
        } else {
          bucket91Plus += p.balanceAmount;
        }

        outstandingList.add(
          _OutstandingItem(
            id: p.id,
            refNumber: p.purchaseNumber,
            date: p.purchaseDate,
            dueDate: dueDate,
            partyName: p.supplierName,
            amount: p.grandTotal,
            balance: p.balanceAmount,
            ageDays: diffDays,
            statusLabel: isOverdue ? 'OVERDUE' : (isDueToday ? 'DUE TODAY' : 'PENDING'),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Outstanding Management')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Accounts Outstanding',
              description: 'Track outstanding balances, ageing schedules, and cash flow forecasts.',
              breadcrumbs: const ['Dashboard', 'Accounting', 'Outstanding'],
            ),

            // Tab Buttons
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Receivables (Customers)'),
                  selected: _selectedTab == 'Receivables',
                  onSelected: (val) {
                    if (val) setState(() => _selectedTab = 'Receivables');
                  },
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: const Text('Payables (Suppliers)'),
                  selected: _selectedTab == 'Payables',
                  onSelected: (val) {
                    if (val) setState(() => _selectedTab = 'Payables');
                  },
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // KPI Stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: Responsive.isMobile(context) ? 1 : 3,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: Responsive.isMobile(context) ? 3.0 : 2.2,
              children: [
                AppMetricCard(
                  title: 'Total Outstanding Balance',
                  value: '₹${totalOutstanding.toStringAsFixed(2)}',
                  trendColor: Colors.blue,
                  trendLabel: 'Overall',
                ),
                AppMetricCard(
                  title: 'Due Today',
                  value: '₹${dueToday.toStringAsFixed(2)}',
                  trendColor: Colors.orange,
                  trendLabel: 'Action Required',
                ),
                AppMetricCard(
                  title: 'Total Overdue Balance',
                  value: '₹${totalOverdue.toStringAsFixed(2)}',
                  trendColor: Colors.red,
                  trendLabel: 'Critical',
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Ageing analysis grid
            Text(
              'Ageing Analysis Schedule',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: Responsive.isMobile(context) ? 2.0 : 2.2,
              children: [
                _buildAgeingBucketCard('0-30 Days', bucket0To30),
                _buildAgeingBucketCard('31-60 Days', bucket31To60, color: Colors.orange),
                _buildAgeingBucketCard('61-90 Days', bucket61To90, color: Colors.deepOrange),
                _buildAgeingBucketCard('90+ Days', bucket91Plus, color: Colors.red),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // List of outstanding documents
            Text(
              'Itemized Outstanding Statement',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: AppTable<_OutstandingItem>(
                items: outstandingList,
                emptyMessage: 'No outstanding balances at this moment.',
                columns: [
                  TableColumnSpec<_OutstandingItem>(
                    label: 'Ref Code',
                    cellBuilder: (item) => Text(item.refNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  TableColumnSpec<_OutstandingItem>(
                    label: 'Date',
                    cellBuilder: (item) => Text('${item.date.day}/${item.date.month}/${item.date.year}'),
                  ),
                  TableColumnSpec<_OutstandingItem>(
                    label: 'Due Date',
                    cellBuilder: (item) => Text('${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}'),
                  ),
                  TableColumnSpec<_OutstandingItem>(
                    label: 'Party Name',
                    flex: 2,
                    cellBuilder: (item) => Text(item.partyName),
                  ),
                  TableColumnSpec<_OutstandingItem>(
                    label: 'Bill Val',
                    isNumeric: true,
                    cellBuilder: (item) => Text('₹${item.amount.toStringAsFixed(2)}'),
                  ),
                  TableColumnSpec<_OutstandingItem>(
                    label: 'Balance',
                    isNumeric: true,
                    cellBuilder: (item) => Text('₹${item.balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                  TableColumnSpec<_OutstandingItem>(
                    label: 'Age (Days)',
                    isNumeric: true,
                    cellBuilder: (item) => Text('${item.ageDays} Days'),
                  ),
                  TableColumnSpec<_OutstandingItem>(
                    label: 'Timeline',
                    cellBuilder: (item) => Text(
                      item.statusLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: item.statusLabel == 'OVERDUE'
                            ? Colors.red
                            : item.statusLabel == 'DUE TODAY'
                                ? Colors.orange
                                : Colors.grey,
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

  Widget _buildAgeingBucketCard(String title, double value, {Color? color}) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '₹${value.toStringAsFixed(2)}',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutstandingItem {
  final String id;
  final String refNumber;
  final DateTime date;
  final DateTime dueDate;
  final String partyName;
  final double amount;
  final double balance;
  final int ageDays;
  final String statusLabel;

  const _OutstandingItem({
    required this.id,
    required this.refNumber,
    required this.date,
    required this.dueDate,
    required this.partyName,
    required this.amount,
    required this.balance,
    required this.ageDays,
    required this.statusLabel,
  });
}
