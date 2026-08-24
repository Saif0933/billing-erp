import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/responsive/responsive.dart';
import '../../../../core/models/billing_models.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_cards.dart';
import '../../../../shared/widgets/app_table.dart';
import '../../../dashboard/presentation/providers/billing_repository.dart';

class CustomerDetailPage extends ConsumerWidget {
  final String customerId;
  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billingState = ref.watch(billingRepositoryProvider);
    
    // Find customer
    final customer = billingState.customers.firstWhere(
      (c) => c.id == customerId,
      orElse: () => Customer(
        id: '',
        name: 'Not Found',
        type: '',
        gstin: '',
        pan: '',
        mobile: '',
        email: '',
        billingAddress: '',
        shippingAddress: '',
        state: '',
        stateCode: '',
        creditLimit: 0,
        creditPeriod: 0,
        openingBalance: 0,
        currentBalance: 0,
        customerGroup: '',
        notes: '',
        isRegistered: false,
      ),
    );

    if (customer.id.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Customer profile not found.')),
      );
    }

    // Filter transaction lists
    final customerInvoices = billingState.invoices.where((inv) => inv.customerId == customerId).toList();
    final customerReceipts = billingState.receipts.where((rec) => rec.customerId == customerId).toList();
    
    final invoiceNumbers = customerInvoices.map((i) => i.invoiceNumber).toSet();
    final receiptRefs = customerReceipts.map((r) => r.referenceNumber).toSet();
    final customerLedger = billingState.ledgerEntries.where((entry) {
      return invoiceNumbers.contains(entry.referenceNumber) ||
          receiptRefs.contains(entry.referenceNumber) ||
          entry.particulars.contains(customer.name) ||
          (entry.type == LedgerTransactionType.openingBalance && entry.id.contains(customer.id));
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(customer.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/customers/edit/${customer.id}'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppPageHeader(
                title: customer.name,
                description: 'Party Type: ${customer.type} • Mobile: ${customer.mobile}',
                breadcrumbs: ['Dashboard', 'Customers', customer.name],
              ),
              
              // Key Stats
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: Responsive.isMobile(context) ? 1 : 3,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: Responsive.isMobile(context) ? 3.0 : 2.2,
                children: [
                  AppMetricCard(
                    title: 'Current Outstanding Balance',
                    value: '₹${customer.currentBalance.toStringAsFixed(2)}',
                    trendColor: customer.currentBalance > 0 ? Colors.red : Colors.green,
                    trendLabel: customer.currentBalance > 0 ? 'Debit' : 'Clear',
                  ),
                  AppMetricCard(
                    title: 'Total Sales Invoiced',
                    value: '₹${customerInvoices.where((i) => i.status != InvoiceStatus.cancelled).fold<double>(0.0, (prev, inv) => prev + inv.grandTotal).toStringAsFixed(2)}',
                    subtitle: 'Confirmed Invoices',
                  ),
                  AppMetricCard(
                    title: 'Total Payments Received',
                    value: '₹${customerReceipts.fold<double>(0.0, (prev, rec) => prev + rec.amount).toStringAsFixed(2)}',
                    subtitle: 'Receipt Entries',
                  ),
                ],
              ),
              
              const SizedBox(height: AppSpacing.xl),

              // Detail Section Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer Information', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('GSTIN:', customer.gstin.isNotEmpty ? customer.gstin : 'Unregistered'),
                              _buildInfoRow('PAN:', customer.pan.isNotEmpty ? customer.pan : 'N/A'),
                              _buildInfoRow('Email:', customer.email.isNotEmpty ? customer.email : 'N/A'),
                              _buildInfoRow('Mobile:', customer.mobile.isNotEmpty ? customer.mobile : 'N/A'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Billing Address:', customer.billingAddress),
                              _buildInfoRow('Shipping Address:', customer.shippingAddress),
                              _buildInfoRow('State Name / Code:', '${customer.state} (${customer.stateCode})'),
                              _buildInfoRow('Credit Terms:', 'Limit: ₹${customer.creditLimit} | Period: ${customer.creditPeriod} Days'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Tabs
              TabBar(
                tabs: const [
                  Tab(text: 'Ledger Statement'),
                  Tab(text: 'Sales Invoices'),
                  Tab(text: 'Receipts'),
                  Tab(text: 'Outstanding Bills'),
                ],
                labelStyle: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.grey,
              ),

              const SizedBox(height: AppSpacing.md),

              SizedBox(
                height: 400,
                child: TabBarView(
                  children: [
                    // Tab 1: Ledger Statement
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<LedgerEntry>(
                        items: customerLedger,
                        emptyMessage: 'No ledger entries for this party.',
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
                            label: 'Ref No.',
                            cellBuilder: (l) => Text(l.referenceNumber),
                          ),
                          TableColumnSpec<LedgerEntry>(
                            label: 'Debit (₹)',
                            isNumeric: true,
                            cellBuilder: (l) => Text(l.debit > 0 ? l.debit.toStringAsFixed(2) : '-'),
                          ),
                          TableColumnSpec<LedgerEntry>(
                            label: 'Credit (₹)',
                            isNumeric: true,
                            cellBuilder: (l) => Text(l.credit > 0 ? l.credit.toStringAsFixed(2) : '-'),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tab 2: Sales Invoices
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<Invoice>(
                        items: customerInvoices,
                        emptyMessage: 'No invoices created for this customer.',
                        columns: [
                          TableColumnSpec<Invoice>(
                            label: 'Inv Number',
                            cellBuilder: (inv) => InkWell(
                              onTap: () => context.push('/sales/${inv.id}'),
                              child: Text(inv.invoiceNumber, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TableColumnSpec<Invoice>(
                            label: 'Date',
                            cellBuilder: (inv) => Text('${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year}'),
                          ),
                          TableColumnSpec<Invoice>(
                            label: 'Amount (₹)',
                            isNumeric: true,
                            cellBuilder: (inv) => Text(inv.grandTotal.toStringAsFixed(2)),
                          ),
                          TableColumnSpec<Invoice>(
                            label: 'Balance (₹)',
                            isNumeric: true,
                            cellBuilder: (inv) => Text(inv.balanceAmount.toStringAsFixed(2)),
                          ),
                          TableColumnSpec<Invoice>(
                            label: 'Status',
                            cellBuilder: (inv) => Text(
                              inv.status.name.toUpperCase(),
                              style: TextStyle(
                                color: inv.status == InvoiceStatus.paid
                                    ? Colors.green
                                    : inv.status == InvoiceStatus.cancelled
                                        ? Colors.red
                                        : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab 3: Receipts
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<Receipt>(
                        items: customerReceipts,
                        emptyMessage: 'No receipt records registered for this customer.',
                        columns: [
                          TableColumnSpec<Receipt>(
                            label: 'Date',
                            cellBuilder: (r) => Text('${r.date.day}/${r.date.month}/${r.date.year}'),
                          ),
                          TableColumnSpec<Receipt>(
                            label: 'Ref Code',
                            cellBuilder: (r) => Text(r.referenceNumber),
                          ),
                          TableColumnSpec<Receipt>(
                            label: 'Mode',
                            cellBuilder: (r) => Text(r.paymentMode),
                          ),
                          TableColumnSpec<Receipt>(
                            label: 'Allocated Invoices',
                            flex: 2,
                            cellBuilder: (r) => Text(r.allocations.map((a) => a.invoiceId).join(', ')),
                          ),
                          TableColumnSpec<Receipt>(
                            label: 'Amount Received',
                            isNumeric: true,
                            cellBuilder: (r) => Text(
                              '₹${r.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab 4: Outstanding Bills
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: AppTable<Invoice>(
                        items: customerInvoices.where((i) => i.status != InvoiceStatus.paid && i.status != InvoiceStatus.cancelled).toList(),
                        emptyMessage: 'No outstanding bills for this customer.',
                        columns: [
                          TableColumnSpec<Invoice>(
                            label: 'Inv Number',
                            cellBuilder: (inv) => Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          TableColumnSpec<Invoice>(
                            label: 'Date',
                            cellBuilder: (inv) => Text('${inv.invoiceDate.day}/${inv.invoiceDate.month}/${inv.invoiceDate.year}'),
                          ),
                          TableColumnSpec<Invoice>(
                            label: 'Total Amount',
                            isNumeric: true,
                            cellBuilder: (inv) => Text('₹${inv.grandTotal.toStringAsFixed(2)}'),
                          ),
                          TableColumnSpec<Invoice>(
                            label: 'Outstanding Amount',
                            isNumeric: true,
                            cellBuilder: (inv) => Text(
                              '₹${inv.balanceAmount.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
