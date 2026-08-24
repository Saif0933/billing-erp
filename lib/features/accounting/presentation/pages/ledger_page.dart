import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
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

class LedgerPage extends ConsumerStatefulWidget {
  const LedgerPage({super.key});

  @override
  ConsumerState<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends ConsumerState<LedgerPage> {
  String _selectedPartyType = 'Customer'; // Customer vs Supplier
  Customer? _selectedCustomer;
  Supplier? _selectedSupplier;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingRepositoryProvider);

    // Filtered ledger entries
    List<LedgerEntry> filteredLedger = [];

    if (_selectedPartyType == 'Customer' && _selectedCustomer != null) {
      final customerId = _selectedCustomer!.id;
      final customerInvoices = billingState.invoices.where((inv) => inv.customerId == customerId).toList();
      final customerReceipts = billingState.receipts.where((rec) => rec.customerId == customerId).toList();

      final invoiceNumbers = customerInvoices.map((i) => i.invoiceNumber).toSet();
      final receiptRefs = customerReceipts.map((r) => r.referenceNumber).toSet();

      filteredLedger = billingState.ledgerEntries.where((entry) {
        final matchesParty = invoiceNumbers.contains(entry.referenceNumber) ||
            receiptRefs.contains(entry.referenceNumber) ||
            entry.particulars.contains(_selectedCustomer!.name) ||
            (entry.type == LedgerTransactionType.openingBalance && entry.id.contains(customerId));
        final matchesDate = _dateRange == null || (entry.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) && entry.date.isBefore(_dateRange!.end.add(const Duration(days: 1))));
        return matchesParty && matchesDate;
      }).toList();
    } else if (_selectedPartyType == 'Supplier' && _selectedSupplier != null) {
      final supplierId = _selectedSupplier!.id;
      final supplierPurchases = billingState.purchases.where((p) => p.supplierId == supplierId).toList();
      final supplierPayments = billingState.payments.where((p) => p.supplierId == supplierId).toList();

      final purchaseNumbers = supplierPurchases.map((p) => p.purchaseNumber).toSet();
      final paymentRefs = supplierPayments.map((p) => p.referenceNumber).toSet();

      filteredLedger = billingState.ledgerEntries.where((entry) {
        final matchesParty = purchaseNumbers.contains(entry.referenceNumber) ||
            paymentRefs.contains(entry.referenceNumber) ||
            entry.particulars.contains(_selectedSupplier!.name) ||
            (entry.type == LedgerTransactionType.openingBalance && entry.id.contains(supplierId));
        final matchesDate = _dateRange == null || (entry.date.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) && entry.date.isBefore(_dateRange!.end.add(const Duration(days: 1))));
        return matchesParty && matchesDate;
      }).toList();
    }

    // Sort entries by date ascending for sequential audit
    filteredLedger.sort((a, b) => a.date.compareTo(b.date));

    // Recompute running balance sequentially for the filtered set
    double currentBal = 0.0;
    final List<LedgerEntry> auditedLedger = [];
    for (var entry in filteredLedger) {
      if (entry.type == LedgerTransactionType.openingBalance) {
        currentBal = entry.debit - entry.credit;
      } else {
        currentBal += (entry.debit - entry.credit);
      }
      auditedLedger.add(
        LedgerEntry(
          id: entry.id,
          date: entry.date,
          particulars: entry.particulars,
          debit: entry.debit,
          credit: entry.credit,
          runningBalance: currentBal,
          referenceNumber: entry.referenceNumber,
          type: entry.type,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Accounting Ledger')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppPageHeader(
              title: 'Party Ledger Statement',
              description: 'View running audit balances of debits and credits for customers and vendors.',
              breadcrumbs: const ['Dashboard', 'Accounting', 'Ledger'],
              actions: [
                AppButton(
                  label: 'Share Ledger (PDF)',
                  icon: Icons.share_outlined,
                  type: AppButtonType.secondary,
                  onPressed: () {
                    if (auditedLedger.isEmpty) {
                      AppFeedback.showSnackbar(context, message: 'Ledger is empty!', isError: true);
                      return;
                    }
                    Share.share('Party Ledger for ${_selectedPartyType == "Customer" ? _selectedCustomer?.name : _selectedSupplier?.name}\nTotal Entries: ${auditedLedger.length}\nClosing Balance: ₹${currentBal.toStringAsFixed(2)}');
                  },
                ),
              ],
            ),

            AppCard(
              child: Column(
                children: [
                  // Filters Row
                  ResponsiveRow(
                    children: [
                      Expanded(
                        child: AppDropdownField<String>(
                          label: 'Party Type',
                          value: _selectedPartyType,
                          items: const [
                            DropdownMenuItem(value: 'Customer', child: Text('Customer Account')),
                            DropdownMenuItem(value: 'Supplier', child: Text('Supplier Account')),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedPartyType = val ?? 'Customer';
                              _selectedCustomer = null;
                              _selectedSupplier = null;
                              _dateRange = null;
                            });
                          },
                        ),
                      ),
                      if (_selectedPartyType == 'Customer')
                        Expanded(
                          child: AppDropdownField<Customer>(
                            label: 'Select Customer *',
                            value: _selectedCustomer,
                            items: billingState.customers.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c.name));
                            }).toList(),
                            onChanged: (c) => setState(() => _selectedCustomer = c),
                          ),
                        )
                      else
                        Expanded(
                          child: AppDropdownField<Supplier>(
                            label: 'Select Supplier *',
                            value: _selectedSupplier,
                            items: billingState.suppliers.map((s) {
                              return DropdownMenuItem(value: s, child: Text(s.name));
                            }).toList(),
                            onChanged: (s) => setState(() => _selectedSupplier = s),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Filter Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                            TextButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: Text(_dateRange == null
                                  ? 'All Dates'
                                  : '${_dateRange!.start.day}/${_dateRange!.start.month} to ${_dateRange!.end.day}/${_dateRange!.end.month}'),
                              onPressed: () async {
                                final selected = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (selected != null) setState(() => _dateRange = selected);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  AppTable<LedgerEntry>(
                    items: auditedLedger,
                    emptyMessage: 'Select a party and date filters to generate the statement.',
                    columns: [
                      TableColumnSpec<LedgerEntry>(
                        label: 'Date',
                        cellBuilder: (l) => Text('${l.date.day}/${l.date.month}/${l.date.year}'),
                      ),
                      TableColumnSpec<LedgerEntry>(
                        label: 'Particulars',
                        flex: 2,
                        cellBuilder: (l) => Text(l.particulars),
                      ),
                      TableColumnSpec<LedgerEntry>(
                        label: 'Reference Code',
                        cellBuilder: (l) => Text(l.referenceNumber),
                      ),
                      TableColumnSpec<LedgerEntry>(
                        label: 'Debit (Dr) (₹)',
                        isNumeric: true,
                        cellBuilder: (l) => Text(l.debit > 0 ? '₹${l.debit.toStringAsFixed(2)}' : '-'),
                      ),
                      TableColumnSpec<LedgerEntry>(
                        label: 'Credit (Cr) (₹)',
                        isNumeric: true,
                        cellBuilder: (l) => Text(l.credit > 0 ? '₹${l.credit.toStringAsFixed(2)}' : '-'),
                      ),
                      TableColumnSpec<LedgerEntry>(
                        label: 'Running Balance',
                        isNumeric: true,
                        cellBuilder: (l) => Text(
                          '₹${l.runningBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: l.runningBalance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                    mobileCardBuilder: (l) => AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${l.date.day}/${l.date.month}/${l.date.year} • Ref: ${l.referenceNumber}'),
                          const SizedBox(height: 4),
                          Text(l.particulars, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(l.debit > 0 ? 'Dr: ₹${l.debit}' : 'Cr: ₹${l.credit}'),
                              Text(
                                'Bal: ₹${l.runningBalance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: l.runningBalance >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
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
